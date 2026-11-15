# bible_track

## Release web / Vercel

Build the Flutter output first, then generate the content-hashed PWA worker:

```sh
flutter/bin/flutter build web --release && node tools/build_pwa.cjs
```

Use that exact Vercel Build Command when the existing Install Command installs Flutter into `flutter/`. Keep the existing Install Command and Output Directory (`build/web`) unchanged. `vercel.json` provides revalidation headers and the SPA fallback. Deploy the generated output; do not run the Bible converter in Vercel. All converted `assets/bible/*.json` and translation JSON files are already Git-tracked. Python and ignored source downloads are only for deliberate local Scripture conversion/review.

For a locally installed Flutter SDK, use `flutter build web --release && node tools/build_pwa.cjs`.

```sh
node --test tools/reader_service_worker_test.cjs
node tools/check_reader_offline.cjs
```

See [tools/pwa_update_report.md](tools/pwa_update_report.md) for diagnosis, update behavior, legacy migration, and phone verification.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
