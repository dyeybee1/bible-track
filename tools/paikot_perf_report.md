# Paikot performance diagnosis

## Before changes (2026-11-19)

Read `spinner_screen.dart`, `scripture_quote.dart`, `app_header.dart`, the home
shell, theme, settings, book data and widget tests before editing implementation.

- There is one AnimationController, created without repeat/forward in initState.
  It runs only for an explicit spin (four seconds, or zero with reduced motion),
  and is disposed. No idle ticker, timers, pulse, confetti or glow was found.
- AnimatedBuilder already rebuilds only CustomPaint, not the entire screen.
  However it creates a new painter and slice-color list on every spin frame.
- The wheel has no RepaintBoundary. Scrolling can repaint all 73 wedges and
  labels. Each paint allocates Paint objects and creates, lays out and disposes
  TWO TextPainters per book (146 text layouts for the full wheel). Rotation
  changes shouldRepaint on every animation tick. Existing non-rotation checks
  compare names, colors, hub and divider colors correctly.
- No BackdropFilter, blur, ShaderMask, explicit saveLayer, large gradients,
  large shadow stacks or full-page opacity were found. The only Card uses the
  shared theme's small elevation. Normal Material clipping is local to controls.
- SingleChildScrollView contains a fixed, short Column: heading, wheel, count,
  switch, Scripture quote and button. There is no shrinkWrap list, nested
  vertical scrollable, intrinsic layout, or eager book/chapter widget list.
  Converting this bounded content to slivers is not justified by code evidence.
- Names and alternating colors are computed in build (linear over at most 73
  books). Filtering happens on initialization, progress or filter changes only.
  No sorting, JSON/Hive reads or repository loads occur in build. Fonts are
  bundled and no images/fonts are loaded by this screen on each build.
- The random result uses Random.nextInt over the filtered book list. Result
  actions dismiss the dialog then either spin again or push ChapterScreen.
  It does not switch home tab indexes. Preserve these paths and calculations.

## Evidence-supported fix planned

Isolate the wheel with repaint boundaries. Rotate a prebuilt static wheel face
using AnimatedBuilder's child; keep its circular rim/hub stationary. Move Paint
allocation out of paint and retain exact content/color invalidation checks.
This removes per-animation-frame text layout and prevents scrolling from
repainting the complex wheel. Preserve colors, sizing, labels, random selection,
filters, spin duration and result flow. Do not change effects or scroll layout
without supporting evidence.

The same paint/layout work exists on Android and web; CanvasKit also benefits
from isolation and transform reuse. Code inspection alone cannot establish
whether the reported lag is web-only or provide device frame timings.

## Implemented fix

The moving face is now AnimatedBuilder's stable child, inside a RepaintBoundary.
Only Transform.rotate changes per controller tick. An outer RepaintBoundary
isolates the complete wheel from scrolling; a separate foreground painter keeps
the rim and hub still. Paint objects live on their painters, and the initial
per-book label width probes are cached on each face. There are no Path objects
in the original wheel to cache. Final text painters are still disposed after
recording; repaint isolation reuses their recorded output through scrolling and
spinning. Names/colors invalidate the face precisely; hub/line colors invalidate
the frame. No scroll-layout, effects, random calculations or result logic changed.

## Verification

`spinner_performance_test.dart` ran against the original painter BEFORE the fix:

| Controlled widget check | Before | After |
| --- | --- | --- |
| Additional face paint calls for a 120px scroll gesture | 1 | 0 |
| Same CustomPaint instance after an 800ms spin tick | No | Yes |
| Idle controller schedules frames after settling / 10 seconds | No | No |

These are deterministic widget-test repaint counts, not phone frame timings.
The two new performance regressions failed before the fix and pass afterward.
Scrolling both ways produces no exceptions; a normal four-second spin still
shows its result and settles without scheduled animation frames.

Books/navigation tests also cover the pushed spinner, normal back action,
scope changes, spin again, opening the selected book, returning to spinner and
Books, unchanged progress, and 320px / 200% text in both themes and languages.

Flutter 3.44.0 / Dart 3.12.0 detects Chrome, Edge and Windows. There is no
connected Android device and `flutter emulators` reports none available.
Consequently no Android or installed-phone-PWA build/raster milliseconds were
measured, and web-only lag cannot be established. The rendering fix is shared
by web/CanvasKit and Android. Android SDK 36.1 and Java 21 are available for a
profile APK build. Final build, analyzer, full-suite and PWA results follow below.

- `flutter analyze`: passed, no issues.
- `flutter test --dart-define=CAPTURE_UI=true --reporter expanded`: all 233 tests
  passed. Refreshed existing local light/dark previews; visually inspected the
  compact Books screen and spinner (including the unchanged wheel styling).
- `node --test tools/reader_service_worker_test.cjs`: all 17 tests passed.
- `flutter build web --release`: passed (CanvasKit JavaScript release; Wasm dry
  run also succeeded).
- `node tools/build_pwa.cjs`: passed, 263 content-hashed precache files.
- `node tools/check_reader_offline.cjs`: passed in real headless Chromium,
  including legacy migration, explicit update consent, cache cleanup and all
  offline assets. Evidence: `build/reader_size/offline_browser_check.json`.
- `flutter build apk --profile`: passed; output is
  `build/app/outputs/flutter-apk/app-profile.apk` (82.2 MB). Gradle emitted
  dependency notes about Firebase plugins' Kotlin Gradle Plugin usage and
  Firestore Java unchecked operations; those dependencies were not changed.

The daily guide was a static Books-only card: no dedicated controller, storage
key or asset existed. Its exclusive strings and the unused summary formatter
were removed in both languages. Profile retains its own summaries unchanged.
HomeShell was the only tab-index owner; no index-based deep-link mapping or
external tab-switch callbacks were found. Its IndexedStack and destinations now
share the Books/Leaderboard/Settings order. Spinner result navigation still
pushes the same ChapterScreen with the same controllers/repositories.

No cloud, sync, Firestore rules, progress, quiz, rank, reader or leaderboard
logic changed. The discovery hint uses only the existing local settings box.
No Firebase deployment is needed, and no deployment was performed.
