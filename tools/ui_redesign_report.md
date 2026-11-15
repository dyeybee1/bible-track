# Serene Scripture UI redesign

Implemented the supplied HTML/design specification in the existing Flutter app. The presentation now uses warm cream, forest green, mint in dark mode, and gold milestones. Newsreader and Plus Jakarta Sans are bundled locally with their SIL Open Font Licenses; neither needs a runtime Google Fonts request.

## Screens and navigation

- Shared headers use a compact paper-colored bar. Root pages show the book mark, Bible Track, existing utilities, and profile access. Details retain their existing back/close handlers, with the profile avatar on the right.
- The bottom bar has exactly four destinations: Mga Libro, Paikot, Ranggo, Setting. The existing profile screen opens as a route from the header. Returning preserves the selected tab and quiz answers.
- The library has the inspiration card, editorial heading, horizontally scrollable testament pills, section progress, book cards and a shortcut to the existing spinner. The heading and filters scroll with the list so large accessibility text remains usable.
- The spinner keeps its original selection, filtering and animation. The disc uses quiet alternating paper/sage segments, a gold pointer, and a green hub. Settings controls and the quote have their own space.
- Rank lists, profile cards and profile previews share green badges, serif names, white/dark surfaces, gold stars and consistent spacing. All displayed counts remain derived from existing progress.
- The chapter grid has five columns, sage completed tiles, a dark first-unread tile, and quiet unread tiles. The existing action dialog appears near the bottom on phones and remains centered on wider screens; its actions, dismissal and return values are unchanged.
- The reader uses the existing font-size controls, a scrollable chapter heading, serif verse cards and numbered badges. Its attribution, translation availability and quiz flow are retained.
- Quiz questions use serif text, neutral answer wells, sage selections, 48px minimum answer targets, and a progress meter derived from the existing answers. Retry/success states use calm cards. The reader shortcut is a white floating pill. The reward screen has a centered rank card, gold stars and an explicit continuation button using the existing gated close handler.
- Settings uses grouped labels, segmented language/theme controls, a soft destructive logout button and the reference's footer verse.
- Existing book/check launcher artwork was recolored and regenerated for web, Android and iOS. PWA browser theme colors and update-banner styling follow the new palette.

## Existing behavior and content

No data controllers, authentication, cloud calls, sync/merge logic, quiz scoring, rank calculations, storage formats, Bible assets or Firestore rules were changed. Existing Filipino/English strings retain their original values. Added strings are presentational copy from the reference and their English equivalents.

The mockup's names, progress, app version and seasonal badges are not production data. The app keeps its real 73-book catalog and four-star division rules. No timer, bookmark, XP system, weekly ranking feature or new privacy route was introduced. The library's added spin button selects the existing spinner tab; it does not create a second spinner or alter its state.

The PWA registration, content hashing, precaching, migration and consent-based update flow remain intact. The browser offline check now also requests the two new font files with HTTP caching disabled.

## Local preview

Actual Flutter screen captures and a gallery are generated under `build/serene_scripture/`. The previews use isolated test data, a short test quiz, and the real bundled Genesis 14 text; they do not access an account or Firestore. They are local build artifacts, not a deployed website.

Regenerate the screenshots with:

```sh
flutter test test/ui_redesign_test.dart --dart-define=CAPTURE_UI=true --reporter expanded
```

## Validation

- Full Flutter suite: **222 tests passed**.
- Final reader/quiz and UI walkthrough checks after the last button adjustments: **81 tests passed**, including 320px screens at 200% text size and both themes.
- `flutter analyze`: **No issues found**.
- Service worker/update tests: **17 passed**.
- `flutter build web --release` followed by `node tools/build_pwa.cjs`: **passed**. The final build contains **263** precache files, including both fonts and their licenses. Release hash: `f0345b8859c5923fe0ef1e510e73c5e51c4e75a72274b244cbde8a2ee87abf15`.
- `node tools/check_reader_offline.cjs`: **passed in real headless Chromium**, with HTTP caching disabled. It verifies old-worker migration, waiting-worker consent, cache cleanup, offline books/quiz/renderer, and the new Newsreader and Plus Jakarta Sans font files. Evidence: `build/reader_size/offline_browser_check.json`.
- **22 actual Flutter captures** cover 11 screens/states in both themes. Open `build/serene_scripture/index.html` in a browser for the local gallery.
- `git diff --check`: **passed**. Data/model/cloud/rule files have no content diff. Native launcher images were regenerated, but native binaries were not rebuilt.

Deploy using the existing build workflow:

```sh
flutter/bin/flutter build web --release && node tools/build_pwa.cjs
```

Install Command and Output Directory (`build/web`) stay unchanged. No production deployment, commit or push was performed in this session.
