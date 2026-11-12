# Reader release size comparison

Flutter 3.44.0 / Dart 3.12.0; release; identical pubspec.lock; default universal Android architectures; same local signing configuration
Baseline source was archived from commit `0568071` before asset registration and UI changes. Measurements use built APK/AAB archives and all files in the release web output, not source-size estimates. MB = 1,000,000 bytes.

| Output | Baseline bytes | Reader bytes | Added bytes | Added MB |
|---|---:|---:|---:|---:|
| APK | 57,259,934 | 60,488,344 | +3,228,410 | +3.228 |
| AAB | 57,447,387 | 60,686,485 | +3,239,098 | +3.239 |
| Web output | 47,885,246 | 58,413,160 | +10,527,914 | +10.528 |

Each platform contains **140 byte-verified Bible JSON files**, including the mapping. Baseline APK/AAB contained none.
Compressed Bible text contribution: APK 2,990,406 bytes; AAB 2,990,406 bytes.
Web file counts: baseline 116; reader 258. All 238 offline precache paths exist in the release output.
The web total is the uncompressed build directory footprint, including local renderer files; it is not a measured HTTP transfer size. AAB size is the upload archive, not a Play Store per-device download estimate.
The PWA prepares static app files, all Bible books, quizzes and local rendering resources on the first online visit. Offline use is available after that cache installation completes. Native APK/AAB text is bundled immediately. No Firebase documents, auth endpoints or sync responses are cached by the reader worker.

## Reproduce

```text
python tools/convert_bible.py
flutter build web --release
flutter build apk --release --no-pub
flutter build appbundle --release --no-pub
python tools/measure_reader_size.py --baseline build/reader_size/baseline
```

Machine-readable artifact sizes and SHA-256 values are in `reader_size_report.json`. Release artifacts stay under ignored build directories; no deployment was performed.
