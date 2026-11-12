# Offline chapter reader implementation

## Quiz retry reader handoff

Failed quizzes keep the filled retry button and add an equal-width outlined `Basahin ang kabanata` / `Read the chapter` action with a book icon and 14px gap. Chapter-and-language availability hides reading for unavailable Tagalog chapters and pending WEB text. Both actions have accessible labels; the retry content scrolls at large text scales on 320px screens.

Reader-to-quiz and failed-quiz-to-reader hops replace the current route. A reader-origin quiz restores a reader on X/system back; a chapter-list-origin quiz closes to that list. Repeated loops retain one reader or quiz route above the chapter list, clear all answers, and preserve question order. Passing still shows explanations and the star screen before returning to the chapter list. Reading never writes progress. The same Bible repository is passed through the flow.

Validation: `flutter analyze` is clean; all **210 Flutter tests** pass, including **70 reader/quiz widget tests**. Checks cover both languages, unavailable/pending chapters, multiple-question resets, repeated route depth, close/back, passing, already-marked chapters, and narrow dark layouts at 2x text scale. Deterministic generation, **5 service-worker checks**, the release web build, and the real Chromium offline check (**238 cached files**) pass. No Firebase deployment is needed; cloud, sync, and Firestore rules are unchanged.

## Current UI revision (supersedes the original phase behavior below)

The reader uses the app language exclusively and ignores the legacy `readerTranslation` preference. Unavailable Tagalog chapters show a centered, neutral message with a Settings language hint; they never load English text. WEB Esther 5 and 15 retain their pending state. Existing Scripture spans and every Esther **needs review** flag remain unchanged.

Chapter taps now open a centered, scrollable dialog with scale/fade, a labeled close button, outside-tap/back dismissal, a separate question count, and distinct quiz/read actions. Read chapters retain read-again and confirmed removal actions. The reader has no translation chips or previous/next arrows. Its outlined font pill offers five locally persisted sizes (16, 18, 20, 22, 24), accessible 48px targets and disabled end stops; font changes preserve scroll position. Legacy font values normalize to the nearest step.

A passing reader quiz (including its explanations and star screen), or a direct mark with no questions, removes the exact reader route and returns to the updated chapter list. Failure/cancellation returns to the origin. Unmarking and its loss screen leave the chapter list visible. Reader credit lines show source names only; Filipino attribution uses `Walang copyright, malayang gamitin`, and the WEB trademark note is retained.

The analyzer cleanup was completed separately in commit `8b0d4fa`. The original phase descriptions and measurements below are historical.

Validation for this revision: `flutter analyze` reports no issues; all **178 Flutter tests**, **13 conversion tests**, and **5 service-worker tests** pass. Deterministic generation and the release web build pass. The headless Chromium check passes with the HTTP cache disabled and network offline, serving both Bible languages, mapping, renderer and shell from **238 cached files**. No Firebase deployment is needed; no cloud, sync or Firestore rules changes were made.

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
