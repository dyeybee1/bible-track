# Offline chapter reader implementation

## Phase 1 — data and boundary review

`boundary_review.md` was created before the data layer. Original Esther boundary review flags remain in `bible_mapping.json`; literal source spans now populate the high-confidence Vulgate-style additions. WEB Esther 5 and 15 are explicitly text pending. No Scripture wording was invented. Whole-chapter Tagalog-to-WEB fallback is approved for Esther 10–16, Daniel 3/13/14 and the seven missing books.

The repository lazily caches source books and the mapping, applies mapping once, returns immutable verses, and distinguishes editorial pending text from asset errors. Translation and font preferences use the existing local settings box; no sync data or Firestore rules changed. Asset directories are explicitly registered for Flutter's non-recursive asset bundling.

Validation: **140 Flutter tests passed**, **13 Python conversion tests passed**, deterministic regeneration passed. `flutter analyze` reports exactly the **14 original findings**, with no new findings. A temporary isolated baseline project under build/ is excluded only from that copy's analysis; the tracked project analysis configuration is unchanged.

## Phase 2 — reader and chapter actions

Chapter taps now open a localized Read / Quiz sheet (or Read again / Remove from read). No-question chapters keep the existing direct-mark flow; removal still confirms and opens the loss screen. The reader uses bundled text, chapter-aware disabled translation chips, saved font controls, themed verse text, chapter navigation and attribution. Its sticky action calls the existing quiz / explanation / star flow. Reading, loading, switching languages and text-pending states do not mark progress.

The reader distinguishes loading, retryable asset failures, and editorial text pending. Whole-chapter English fallback shows the approved passage-level note. Text sources are available in Settings and from the reader credit. Intro copy now describes the offline reader. All added user-facing copy has Filipino and English forms.

Validation: **140 Flutter tests passed**; `flutter analyze` still reports only the **14 unchanged findings**. The expanded reader and sheet widget checks are added in Phase 3.

## Phase 3 — behavior, offline web and release checks

**158 Flutter tests passed**, including 18 reader widget checks; **13 Python conversion checks passed**; **5 service-worker checks passed**. The suite covers unread/read sheets, question counts, no-question direct marking, unmark confirmation and loss flow, translation switching, saved font size, chapter navigation, English-only passages, pending text in both languages, loading/error/retry, attribution, and a 320px dark layout at 1.6 text scale. Opening, reading, switching, loading and pending states leave progress unchanged. The existing quiz → explanations → explicit mark → star screen remains intact.

The widget checks exposed and fixed background loading animation under the sheet, text overflow in the chapter header/finisher preview, and Settings card ink painting. These fixes stay within the requested screens. No existing analyzer findings were changed.

This Flutter SDK's generated worker unregisters the old caching worker; see the [Flutter initialization documentation](https://docs.flutter.dev/platform-integration/web/initialization#service-worker-deprecation). The custom bootstrap now registers a versioned static-file worker and uses bundled CanvasKit instead of a CDN. Its first online installation caches all Bible books, quizzes, app shell, fonts and renderer before activation. Dart still loads/decodes only one book at a time. Imported resource metadata changes the worker version when reader sources change. Regenerate it with `python tools/convert_bible.py` before a release build after source changes.

A **real headless Chromium check passed with HTTP cache disabled and the network offline**, reading previously unopened English and Tagalog book files, the mapping, local renderer and app shell from **238 precached static files**. This checks reader static resources; it does not change or replace the existing sign-in/sync flow. No account APIs, auth endpoints, Firebase documents or cloud responses enter the reader cache. Browser cache installation must complete during an online visit before PWA offline use; native text is available directly in the package.

`flutter build web --release`, `flutter build apk --release --no-pub` and `flutter build appbundle --release --no-pub` all succeeded. [reader_size_report.md](reader_size_report.md) records exact sizes and the baseline methodology. APK increased **3,228,410 bytes (3.228 MB)**; AAB increased **3,239,098 bytes (3.239 MB)**; the uncompressed web output directory increased **10,527,914 bytes (10.528 MB)**. Each platform contains all **140 byte-verified Bible JSON files**, including the mapping. AAB upload size is distinct from a Play Store per-device download. Existing Firebase Kotlin plugin migration warnings do not prevent these builds; dependencies were left unchanged.

WEB Esther **5 and 15 remain text pending**. The original Esther **needs review** flags remain in both the mapping and boundary review until the user confirms them. Tagalog Esther 5 remains readable from its own source. Quiz and mark actions work for pending chapters.

**No Firebase deployment is needed.** No Firestore rules, sync/account/progress data, quiz questions or server code changed. Release artifacts are local under ignored build directories; nothing was published.

## Pre-existing analyzer findings left unchanged (14)

`flutter analyze` exits 1 for the same 11 informational lints and 3 warnings:

| File | Line:column | Finding |
|---|---|---|
| lib/data/account_controller.dart | 28:8 | prefer_initializing_formals (`_auth`) |
| lib/data/account_controller.dart | 29:8 | prefer_initializing_formals (`_cloud`) |
| lib/data/account_controller.dart | 30:8 | prefer_initializing_formals (`_progress`) |
| lib/data/account_controller.dart | 31:8 | prefer_initializing_formals (`_settings`) |
| lib/data/account_controller.dart | 32:8 | prefer_initializing_formals (`_box`) |
| lib/data/leaderboard_controller.dart | 44:9 | prefer_initializing_formals (`_cloud`) |
| lib/data/leaderboard_controller.dart | 45:9 | prefer_initializing_formals (`_currentUid`) |
| lib/data/leaderboard_controller.dart | 46:9 | prefer_initializing_formals (`_myChaptersRead`) |
| lib/data/progress_controller.dart | 13:47 | unintended_html_in_doc_comment |
| lib/widgets/app_logo.dart | 28:29 | unnecessary_underscores |
| lib/widgets/app_logo.dart | 28:33 | unnecessary_underscores |
| tools/validate_questions.dart | 76:16 | unnecessary_cast (warning) |
| tools/validate_questions.dart | 108:32 | unnecessary_cast (warning) |
| tools/validate_questions.dart | 117:32 | unnecessary_cast (warning) |

## Verification commands

```text
python tools/convert_bible.py --check
python tools/review_bible_boundaries.py
python -m unittest discover -s tools -p test_bible_sources.py
node --test tools/reader_service_worker_test.cjs
flutter analyze
flutter test --reporter expanded --timeout 60s
flutter build web --release
flutter build apk --release --no-pub
flutter build appbundle --release --no-pub
node tools/check_reader_offline.cjs
python tools/measure_reader_size.py --baseline build/reader_size/baseline
```
