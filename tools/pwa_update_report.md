# Installed PWA update diagnosis and repair

## Diagnosis (before changes)

Inspected `web/flutter_bootstrap.js`, `web/reader_service_worker.js`, `web/reader_offline_assets.js`, `tools/reader_offline_manifest.py`, `tools/convert_bible.py`, `tools/reader_service_worker_test.cjs`, `tools/check_reader_offline.cjs`, and `tools/measure_reader_size.py`. No `vercel.json` exists in the initial checkout. All 140 converted Bible JSON files (139 books plus mapping) are already tracked in Git; their raw conversion inputs under `data/source` are intentionally ignored.

The suspected deployment failure is confirmed, but the original hash is broader than just Bible-reader sources. `offline_manifest()` hashes sorted relative paths, a NUL separator, and file bytes using SHA-256, keeping its first 20 hexadecimal characters. It covers every file under `assets`, every `lib/**/*.dart`, every `web/**/*.js` except its own generated output, `pubspec.yaml`, `pubspec.lock`, `web/index.html`, and `web/manifest.json`. Text input line endings are normalized. In principle UI, quizzes, fonts, and reader edits change it **when that Python function actually runs**. It is called by `convert_bible.py`, not Flutter. That converter requires the ignored source archives and Tagalog source JSON. The Flutter-only Vercel build merely copies the committed, potentially stale generated list. It neither recalculates that hash nor hashes the actual compiled `main.dart.js`, generated bootstrap, or bundled renderer. This explains a changed app with an unchanged cache identity.

Original lifecycle and requests:

- Install opens `bible-track-reader-<source hash>`, downloads a hard-coded CORE list plus source assets and FontManifest fonts, then unconditionally calls `skipWaiting()`.
- Activate deletes other `bible-track-reader-*` caches and calls `clients.claim()`.
- Root/index navigations, `index.html`, `main.dart.js`, and `flutter_bootstrap.js` are all cache-first. Navigation matching only covers root and `index.html`, not arbitrary SPA paths.
- The bootstrap registers once after load with `updateViaCache: 'none'`; there are no explicit startup/resume/periodic update checks, waiting-worker prompt, or user-controlled controller-change/reload flow.
- A source change to the worker can trigger installation, but reusing the same cache name can overwrite the active version in place and cannot distinguish releases reliably.
- `measure_reader_size.py` reads the source manifest and parses CORE out of worker source; it must instead validate post-build output after this repair.

## Live Vercel headers before changes

Read-only HEAD requests to `https://bibletrack.vercel.app` on 2026-11-15 returned HTTP 200 for `/reader_service_worker.js`, `/index.html`, `/flutter_bootstrap.js`, and `/manifest.json`. All four returned `Cache-Control: public, max-age=0, must-revalidate`, with `X-Vercel-Cache: HIT`. A later HEAD for `/version.json` also returned HTTP 200 with the same revalidation policy (`X-Vercel-Cache: MISS`). The worker ETag was `14b16b07e59bbf0dd6bcd09f9fda51f8`, index ETag `3b64feae309e6c5d36dac9170ce2529d`. These headers already require browser revalidation; CDN HIT alone does not explain the bug. The application's cache-first service worker can answer without reaching HTTP revalidation at all. The repair makes this policy explicit as `no-cache` in repository-controlled Vercel configuration.

Reference: [Vercel cache-control documentation](https://vercel.com/docs/caching/cache-control-headers) and [project configuration](https://vercel.com/docs/project-configuration).

## Repair and validation

`tools/build_pwa.cjs` uses only Node built-ins and the finished `build/web` directory. It walks the actual output, hashes every precache file with SHA-256, and hashes the sorted path/digest map together with the worker template. This includes compiled app code, generated bootstrap, app/translation JSON, quizzes, fonts, icons, manifests and renderer files. Adding, removing, or changing a file changes the release ID; so does changing worker behavior. Re-running the step on unchanged output is idempotent.

The content hash and exact resource digests are embedded directly in `reader_service_worker.js`, so the worker's own bytes change with a release. `reader_offline_assets.js` is now generated in the **build output**, not committed source. `version.json` preserves Flutter's app version fields and adds `buildHash` plus `precache`. These generated metadata files and the generated worker are excluded from their own precache hash to avoid circularity. The deprecated Flutter-generated worker is not used or precached. Source `web/reader_service_worker.js` deliberately refuses installation until the post-build step embeds its manifest.

Each release installs into a fresh `bible-track-pwa-<full SHA-256>` cache. Downloads bypass the HTTP cache and their SHA-256 must match the build manifest; a failed/mixed-deployment install removes its partial cache and leaves the previous worker active. The bounded downloads are all settled before cleanup. Static resources are served from the active release cache; navigation, SPA paths and explicit `index.html` requests are network-first, falling back to that release's original shell offline. Online HTML is not written over the active snapshot, preserving a consistent offline release. Activation removes only old `bible-track-pwa-*` and legacy `bible-track-reader-*` caches, then claims clients; unrelated caches and local/Hive/account storage are preserved.

`pwa_update.js` registers with `updateViaCache: 'none'`, calls `registration.update()` on startup, when visibility returns, and every 30 minutes. A waiting release gets a small keyboard-accessible, non-modal banner. The page's language follows the existing Flutter language setting using a web-only document-language bridge. EN: "A new version is available" / "Update"; Filipino: "May bagong bersyon ng app" / "I-update". Only the consenting page sends `SKIP_WAITING`, waits for `controllerchange`, and reloads once. Other tabs display a prompt without reloading. A timeout enables retry rather than forcing a reload. No automatic page reload interrupts an open quiz or reader.

**One-time old-worker migration:** cached pages from the previous implementation contain no banner code. Leaving their replacement worker waiting forever would require a UI they cannot display. Therefore a fully downloaded/verified new worker calls `skipWaiting()` only when it detects an active legacy reader cache and no earlier new-protocol release. It cleans the legacy layout and claims clients **without reloading them**. The old page can finish its current activity; its next manual reload/reopen receives the network-first shell and new updater. All later releases wait for the update button.

`vercel.json` explicitly serves every static URL, including the worker, index/root/SPA pages, `main.dart.js`, bootstrap, update client, metadata and manifest, with `Cache-Control: no-cache`. This conservative policy avoids giving immutable lifetimes to same-name assets such as `assets/.../gen.json`, whose contents can change. The worker still supplies fast, verified offline caching. The filesystem-first SPA rewrite follows [Vercel's documented SPA configuration](https://vercel.com/docs/project-configuration/vercel-json#rewrites). Existing files retain their URLs; missing SPA routes fall back to index.

`convert_bible.py` only converts/reviews Scripture and no longer versions the PWA. The obsolete Python manifest generator was removed. `measure_reader_size.py` now checks post-build precache paths and byte hashes. No cloud, synchronization, authentication, or Firestore-rule changes were made. The only Dart change publishes the existing language setting to the page for banner localization.

## Vercel settings and release command

Paste this exact **Build Command** (Node is the dependency-free alternative):

```sh
flutter/bin/flutter build web --release && node tools/build_pwa.cjs
```

Keep the existing **Install Command** unchanged and **Output Directory** at `build/web`. Keep the same project/root/framework settings. Commit/deploy these changes, including `vercel.json`, `tools/build_pwa.cjs`, web files and the Dart language bridge. All 140 converted Bible JSON files were already Git-tracked; Vercel needs neither Python nor `data/source` downloads. The added configuration does not override Install Command or Output Directory. No account-setting change or deployment was performed from this session.

## Phone verification after deploying

1. Open `https://bibletrack.vercel.app/version.json` online. Confirm `buildHash` is a 64-character hash. On a computer, HEAD the worker, index, bootstrap, version and manifest URLs; each must return `Cache-Control: no-cache` after this deployment.
2. For the existing old installation, open the PWA online and allow the full static cache download to complete (time depends on connection). Finish any current quiz/reading, then fully close the installed PWA and any browser tabs for this origin and reopen it. This one-time migration needs no uninstall or site-data reset. If it was already left open before deployment, one manual reopen/refresh starts the browser's worker update check; a subsequent reopen after installation gets the new shell.
3. Once on this updater, deploy a second release with a visible UI-only change. Keep the installed PWA open in a quiz or reader, background it, then return online. The banner should appear after installation while the page and selected answers remain untouched. Startup/resume checks are immediate; an open page also checks about every 30 minutes.
4. Finish the activity and tap **I-update / Update**. Expect one reload, the new UI and a different `buildHash`. Check both app languages. In a second open tab, activation must show a prompt rather than forcing a reload.
5. Once installation completes, turn on airplane mode, reopen, and read a previously unopened Bible book and its local quiz. Reconnect and confirm normal account/sync behavior remains unchanged.

## Verification results

- `node --test tools/reader_service_worker_test.cjs`: **17 passed**. Includes every-file content changes (specifically compiled app only), file addition/deletion, worker behavior changes, idempotence, install failure/integrity cleanup, legacy/new cache activation cleanup, network-first navigation/offline fallback, SKIP_WAITING, initial install, waiting/updatefound handling, both banner languages, startup/visibility/30-minute checks, retry, and no unsolicited reload of another tab/quiz/reader.
- `flutter analyze`: **No issues found**.
- `flutter test --reporter expanded`: **217 passed**.
- `flutter build web --release` followed by `node tools/build_pwa.cjs`: **passed**, including the SDK's Wasm dry-run compilation. **259** precache files have verified SHA-256 digests, including **140** built Bible JSON files. The generated metadata is idempotent when rerun.
- Local release ID: `7faf255276ac4f2d8dcd8ca00fc6777c165e5422418c5b1bb1e93c3b3782e886`. The Vercel build can have a different ID if its compiled bytes/SDK differ; changes between deployments, not equality to a local build, are the important check.
- `node tools/check_reader_offline.cjs`: **passed in real headless Chromium**, with HTTP cache disabled. It starts from an active legacy cache-first worker, verifies migration/cache cleanup without any page reload, preserves a sample quiz answer, serves new HTML network-first while retaining release A's compiled JS, installs release B into a separate waiting cache, renders the Filipino update banner, reloads exactly once on user approval, deletes A/legacy caches, and verifies offline unvisited WEB/Tagalog books, mapping, local quiz, CanvasKit, Roboto, bootstrap and app shell. The synthetic B release changes compiled JS and adds an HTML marker without changing the real release output. Browser evidence is `build/reader_size/offline_browser_check.json`.
- Python conversion/measurement tools passed syntax compilation. The historical APK/AAB size comparison was not regenerated because this task does not rebuild native artifacts or change Scripture.

The checked Vercel headers above are **before deployment**. Repository configuration and local release output are ready, but production has not been redeployed here; verify the deployed headers and phone behavior using the steps above.
