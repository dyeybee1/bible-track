# Offline chapter reader implementation

## Phase 1 — data and boundary review

`boundary_review.md` was created before the data layer. Original Esther boundary review flags remain in `bible_mapping.json`; literal source spans now populate the high-confidence Vulgate-style additions. WEB Esther 5 and 15 are explicitly text pending. No Scripture wording was invented. Whole-chapter Tagalog-to-WEB fallback is approved for Esther 10–16, Daniel 3/13/14 and the seven missing books.

The repository lazily caches source books and the mapping, applies mapping once, returns immutable verses, and distinguishes editorial pending text from asset errors. Translation and font preferences use the existing local settings box; no sync data or Firestore rules changed. Asset directories are explicitly registered for Flutter's non-recursive asset bundling.

Validation: **140 Flutter tests passed**, **13 Python conversion tests passed**, deterministic regeneration passed. `flutter analyze` reports exactly the **14 original findings**, with no new findings. A temporary isolated baseline project under build/ is excluded only from that copy's analysis; the tracked project analysis configuration is unchanged.

## Phase 2 — reader and chapter actions

Chapter taps now open a localized Read / Quiz sheet (or Read again / Remove from read). No-question chapters keep the existing direct-mark flow; removal still confirms and opens the loss screen. The reader uses bundled text, chapter-aware disabled translation chips, saved font controls, themed verse text, chapter navigation and attribution. Its sticky action calls the existing quiz / explanation / star flow. Reading, loading, switching languages and text-pending states do not mark progress.

The reader distinguishes loading, retryable asset failures, and editorial text pending. Whole-chapter English fallback shows the approved passage-level note. Text sources are available in Settings and from the reader credit. Intro copy now describes the offline reader. All added user-facing copy has Filipino and English forms.

Validation: **140 Flutter tests passed**; `flutter analyze` still reports only the **14 unchanged findings**. The expanded reader and sheet widget checks are added in Phase 3.
