# Bible text: Phase 0 source and numbering report

Generated deterministically by `python tools/convert_bible.py`. Source retrieval: 2026-11-12.
Phase 0 source audit, updated with the user's app-language-only reader and literal-span mapping decisions. See `boundary_review.md` for the current boundary audit. No source Scripture wording is invented.

## Result

Converted 139 compact UTF-8 book JSON files: 73 WEB and 66 Tagalog.
Assets retain SOURCE chapter/verse numbers. `tools/bible_mapping.json` explicitly maps them to app chapters; the Phase 1 repository must apply it once.
`mapped_chapter` in `tools/bible_sources.py` is the executable mapping reference. It renumbers Joel 3 to 1–5, Joel 4 to 1–21, Malachi 3 to 1–24, and Daniel 4 to 1–34.
Text-pending chapters raise a distinct exception for the reader's friendly pending state. The reader follows the app language without fallback; unavailable Tagalog chapters have a separate friendly state.
Use `--app-output build/bible_app_preview` to inspect files with the verified mappings and renumbering already applied. Pending chapters are omitted from that review-only preview.

| Translation | Source books | Source chapters | Non-empty source verse entries | Verified app chapters | Pending app chapters |
|---|---:|---:|---:|---:|---:|
| web | 73 | 1328 | 35379 | 1332 | 2 |
| tl1905 | 66 | 1189 | 31102 | 1187 | 10 |

JSON files occupy **10,451,144 bytes (10.45 MB; 9.97 MiB)** before packaging/compression.
They are not registered in pubspec.yaml yet (Phase 1); this is data size, not a measured installed-app increase.

## Every-book chapter comparison

Counts below are measured from the pinned inputs. Missing means the source has no book, not zero-length invented chapters.
Equal chapter counts alone do not prove verse-by-verse equivalence with every Catholic edition. The app uses mixed conventions (notably modern Psalm numbering).

| ID | Book | App chapters | WEB source chapters | WEB result | TL1905 source chapters | TL1905 result |
|---|---|---:|---:|---|---:|---|
| gen | Genesis | 50 | 50 | same chapter count | 50 | same chapter count |
| exo | Exodus | 40 | 40 | same chapter count | 40 | same chapter count |
| lev | Leviticus | 27 | 27 | same chapter count | 27 | same chapter count |
| num | Numbers | 36 | 36 | same chapter count | 36 | same chapter count |
| deu | Deuteronomy | 34 | 34 | same chapter count | 34 | same chapter count |
| jos | Joshua | 24 | 24 | same chapter count | 24 | same chapter count |
| jdg | Judges | 21 | 21 | same chapter count | 21 | same chapter count |
| rut | Ruth | 4 | 4 | same chapter count | 4 | same chapter count |
| 1sa | 1 Samuel | 31 | 31 | same chapter count | 31 | same chapter count |
| 2sa | 2 Samuel | 24 | 24 | same chapter count | 24 | same chapter count |
| 1ki | 1 Kings | 22 | 22 | same chapter count | 22 | same chapter count |
| 2ki | 2 Kings | 25 | 25 | same chapter count | 25 | same chapter count |
| 1ch | 1 Chronicles | 29 | 29 | same chapter count | 29 | same chapter count |
| 2ch | 2 Chronicles | 36 | 36 | same chapter count | 36 | same chapter count |
| ezr | Ezra | 10 | 10 | same chapter count | 10 | same chapter count |
| neh | Nehemiah | 13 | 13 | same chapter count | 13 | same chapter count |
| tob | Tobit | 14 | 14 | same chapter count | missing | missing book; unavailable in Tagalog |
| jdt | Judith | 16 | 16 | same chapter count | missing | missing book; unavailable in Tagalog |
| est | Esther | 16 | 10 | needs review (embedded additions) | 10 | unavailable app chapters in Tagalog |
| 1ma | 1 Maccabees | 16 | 16 | same chapter count | missing | missing book; unavailable in Tagalog |
| 2ma | 2 Maccabees | 15 | 15 | same chapter count | missing | missing book; unavailable in Tagalog |
| job | Job | 42 | 42 | same chapter count | 42 | same chapter count |
| psa | Psalms | 150 | 150 | modern numbering matches quiz; no Psalm 151 | 150 | modern numbering matches quiz; no Psalm 151 |
| pro | Proverbs | 31 | 31 | same chapter count | 31 | same chapter count |
| ecc | Ecclesiastes | 12 | 12 | same chapter count | 12 | same chapter count |
| sng | Song of Songs | 8 | 8 | same chapter count | 8 | same chapter count |
| wis | Wisdom | 19 | 19 | same chapter count | missing | missing book; unavailable in Tagalog |
| sir | Sirach | 51 | 51 | 51; prologue excluded; source verse gaps retained | missing | missing book; unavailable in Tagalog |
| isa | Isaiah | 66 | 66 | same chapter count | 66 | same chapter count |
| jer | Jeremiah | 52 | 52 | same chapter count | 52 | same chapter count |
| lam | Lamentations | 5 | 5 | same chapter count | 5 | same chapter count |
| bar | Baruch | 6 | 6 | 6 includes Letter of Jeremiah | missing | missing book; unavailable in Tagalog |
| eze | Ezekiel | 48 | 48 | same chapter count | 48 | same chapter count |
| dan | Daniel | 14 | 14 | mapped | 12 | unavailable app chapters in Tagalog |
| hos | Hosea | 14 | 14 | same chapter count | 14 | same chapter count |
| joe | Joel | 4 | 3 | mapped | 3 | mapped |
| amo | Amos | 9 | 9 | same chapter count | 9 | same chapter count |
| oba | Obadiah | 1 | 1 | same chapter count | 1 | same chapter count |
| jon | Jonah | 4 | 4 | same chapter count | 4 | same chapter count |
| mic | Micah | 7 | 7 | same chapter count | 7 | same chapter count |
| nah | Nahum | 3 | 3 | same chapter count | 3 | same chapter count |
| hab | Habakkuk | 3 | 3 | same chapter count | 3 | same chapter count |
| zep | Zephaniah | 3 | 3 | same chapter count | 3 | same chapter count |
| hag | Haggai | 2 | 2 | same chapter count | 2 | same chapter count |
| zec | Zechariah | 14 | 14 | same chapter count | 14 | same chapter count |
| mal | Malachi | 3 | 4 | mapped | 4 | mapped |
| mat | Matthew | 28 | 28 | same chapter count | 28 | same chapter count |
| mrk | Mark | 16 | 16 | same chapter count | 16 | same chapter count |
| luk | Luke | 24 | 24 | same chapter count | 24 | same chapter count |
| jhn | John | 21 | 21 | same chapter count | 21 | same chapter count |
| act | Acts | 28 | 28 | same chapter count | 28 | same chapter count |
| rom | Romans | 16 | 16 | same chapter count | 16 | same chapter count |
| 1co | 1 Corinthians | 16 | 16 | same chapter count | 16 | same chapter count |
| 2co | 2 Corinthians | 13 | 13 | same chapter count | 13 | same chapter count |
| gal | Galatians | 6 | 6 | same chapter count | 6 | same chapter count |
| eph | Ephesians | 6 | 6 | same chapter count | 6 | same chapter count |
| php | Philippians | 4 | 4 | same chapter count | 4 | same chapter count |
| col | Colossians | 4 | 4 | same chapter count | 4 | same chapter count |
| 1th | 1 Thessalonians | 5 | 5 | same chapter count | 5 | same chapter count |
| 2th | 2 Thessalonians | 3 | 3 | same chapter count | 3 | same chapter count |
| 1ti | 1 Timothy | 6 | 6 | same chapter count | 6 | same chapter count |
| 2ti | 2 Timothy | 4 | 4 | same chapter count | 4 | same chapter count |
| tit | Titus | 3 | 3 | same chapter count | 3 | same chapter count |
| phm | Philemon | 1 | 1 | same chapter count | 1 | same chapter count |
| heb | Hebrews | 13 | 13 | same chapter count | 13 | same chapter count |
| jas | James | 5 | 5 | same chapter count | 5 | same chapter count |
| 1pe | 1 Peter | 5 | 5 | same chapter count | 5 | same chapter count |
| 2pe | 2 Peter | 3 | 3 | same chapter count | 3 | same chapter count |
| 1jn | 1 John | 5 | 5 | same chapter count | 5 | same chapter count |
| 2jn | 2 John | 1 | 1 | same chapter count | 1 | same chapter count |
| 3jn | 3 John | 1 | 1 | same chapter count | 1 | same chapter count |
| jud | Jude | 1 | 1 | same chapter count | 1 | same chapter count |
| rev | Revelation | 22 | 22 | same chapter count | 22 | same chapter count |

## Current reader decisions after Phase 0 review

The reader now follows the app language with no fallback, superseding the earlier approval. Tagalog Esther 10-16, Daniel 3/13/14 and the seven missing books show a friendly unavailable message and keep the quiz action. `tools/boundary_review.md` is the current boundary audit. High-confidence literal spans populate the reviewed mappings while retaining every original Esther **needs review** flag in `review_required_chapters`. WEB Esther 5 and 15 remain **text pending**. The earlier Phase 0 assessment below is retained as historical evidence; its proposed fallback is not current reader behavior.

## Sources and public-domain evidence

- **WEB**: eBible.org **World English Bible, Catholic edition**, ID `eng-web-c`, downloaded as [USFM](https://ebible.org/Scriptures/eng-web-c_usfm.zip). Its [edition page](https://ebible.org/find/details.php?id=eng-web-c) identifies the Catholic canon and Greek portions of Esther/Daniel. `data/source/licenses/eng-web-c-copr.htm` is the exact public-domain declaration included inside the archive. The declaration also identifies **World English Bible as a trademark of eBible.org** and asks that changed wording not be presented under that name. No wording corrections or paraphrases were made; only notes, markup, headings and redundant whitespace were removed.
- **Tagalog**: **Ang Dating Biblia (1905)**, CrossWire SWORD module **TagAngBiblia 1.2 (2008-07-19)**, typed by Richard & Dolores Long. Both the [module page](https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=TagAngBiblia) and [copyright record](https://www.crosswire.org/sword/copyright/ModInfoCopyright.jsp?modName=TagAngBiblia) explicitly identify it as public domain. The exact module configuration, including `DistributionLicense=Public Domain`, is committed as `data/source/licenses/tagangbiblia.conf`.
- For dependency-free chapter/verse coordinates, the converter reads [getBible's Tagalog JSON export](https://api.getbible.net/v2/tagalog.json). **Every one of its 31,102 verse texts is independently compared, byte for byte before whitespace normalization, with the decompressed original CrossWire archive**: 23,145 OT and 7,957 NT. Any difference aborts conversion. Export metadata is committed as `data/source/licenses/tagalog-metadata.json`.
- CrossWire's module literally named **Tagalog** contains only John and James, so it was not used. Sacred Texts was also not used. No Magandang Balita, Ang Biblia 1978, or other copyrighted translation was downloaded or bundled. Douay-Rheims links below are public-domain **numbering references only**; their text is not bundled.

## Verified split/merge mappings

All ranges below are inclusive. The mapping stores `source_book`, `source_chapter`, `source_verses`, and `app_verse_start`. The destination verse is `app_verse_start + source_v - first_source_v`; verse 1 is retained at every app chapter start. Existing source gaps stay gaps; they are not compressed or filled.

| Translation | Source coordinates | App coordinates |
|---|---|---|
| both | Joel 1:1–20 | Joel 1:1–20 |
| both | Joel 2:1–27 | Joel 2:1–27 |
| both | Joel 2:28–32 | Joel 3:1–5 |
| both | Joel 3:1–21 | Joel 4:1–21 |
| both | Malachi 1:1–14; 2:1–17 | same |
| both | Malachi 3:1–18 | Malachi 3:1–18 |
| both | Malachi 4:1–6 | Malachi 3:19–24 |
| WEB | Daniel 3:1–97 | Daniel 3:1–97 |
| WEB | Daniel 4:1–3 | Daniel 3:98–100 |
| both | Daniel 4:4–37 | Daniel 4:1–34 |
| WEB | Daniel 13:1–64 | Daniel 13:1–64 (Susanna) |
| WEB | Daniel 14:1–42 | Daniel 14:1–42 (Bel and the Dragon) |
| WEB | Esther 4:1–17 | Esther 4:1–17 |
| WEB | Esther 4:29–47 | Esther 14:1–19 (Esther's prayer) |
| WEB | Esther 10:1–13 | Esther 10:1–13 (includes dream interpretation) |

The source texts confirm Joel's Spirit prophecy begins at 2:28 and the nations' judgment at 3:1. The existing `joe.json` quiz independently places these in app chapters 3 and 4. Malachi's final source chapter has six verses; concatenation gives 24 verses, not an extra app chapter.

Daniel's 14-chapter count alone hides a chapter-boundary difference. The app describes its convention as Vulgate-based. [Douay-Rheims Daniel 3](https://ebible.org/engDRA/DAN03.htm) places the royal proclamation at 3:98–100, while WEB DAG places it at 4:1–3; [Daniel 4](https://ebible.org/engDRA/DAN04.htm) begins with the king at rest, WEB 4:4. This boundary is explicitly mapped in both languages. The Greek prayer and song are WEB 3:24–90. Daniel 5 and 6 retain their source chapter boundaries; no unsupported 5/6 transfer was added.

Baruch is already **six** source chapters, with the Letter of Jeremiah in chapter 6 (73 verses); there is no separate Letter book to append. Sirach is **51** chapters; the unnumbered prologue is outside the chapters and is excluded. Source footnote-only labels and missing markers are documented below, rather than replaced with invented Scripture.

## Needs review before Phase 1

### 1. WEB Esther: 10 source chapters cannot become 16 using whole-verse ranges alone

The source is **ESG (Esther translated from the Greek Septuagint)**, not an accidentally selected Protestant Esther. Its own introduction explains that additions are embedded in long verses. The app's existing `est.json` questions and `_REVIEW.md` instead require the 16-chapter arrangement: dream interpretation in 10, dream in 11, conspiracy in 12, hostile letter plus Mordecai's prayer in 13, Esther's prayer in 14, expanded audience in 15, protective letter in 16.

Measured source locations:

| Source location | Contents / destination requiring review |
|---|---|
| 1:1 (2,104 characters after stripping markup) | Dream (app 11), conspiracy (app 12), and opening of the main narrative (app 1) share one verse. |
| 3:13 | Main narrative and hostile letter (part of app 13) share one verse. Mordecai's prayer is separately numbered 4:18–28. |
| 4:29–47 | Esther's prayer maps cleanly to app 14:1–19. |
| 5:1–2 | Expanded audience needed for app 15 is embedded in the main audience of app 5. A duplicate whole-verse copy would repeat text. App 15 also begins with Mordecai's instructions; range-only transfer must not silently omit them. |
| 8:13 | Protective letter (app 16) and main narrative share one verse. **The actual insertion is at 8:13**, although the source introduction says 8:12. The report uses the actual verse markers. |
| 10:1–13; 10:14 | First range matches app 10; the Dositheus colophon at 10:14 belongs before the dream, app 11:1 ([numbering reference](https://ebible.org/engDRA/EST11.htm)). |

The numeric mappings that are unambiguous are recorded; unresolved app chapter entries are `null` and explicitly listed as pending. **No split offsets, new verses, duplicated additions, or invented source words were guessed.** The raw Esther JSON remains source-numbered for audit.

**Review needed:** agree on exact within-verse text spans and verse divisions for the 16-chapter presentation, preserving the pinned WEB wording and accounting for every source span once. This requires a reviewed extension to the range-only mapping schema. Keeping a 10-chapter reader would not meet the current 16-chapter app/quiz requirement. No app chapter counts or existing questions were changed.

The source also contains joined words (for example `thingsin` in 1:1 and `theirbenefactors` in 8:13). These were preserved as downloaded, not silently edited. Any corrections should be reviewed with the WEB trademark guidance.

### 2. Tagalog availability must be decided per chapter for Esther and Daniel

Besides the seven wholly missing deuterocanonical books, the 66-book Tagalog source lacks additions within two other books:

- **Esther 10** has only verses 1–3, omitting the dream interpretation required by the app's chapter-10 quiz. App Esther 11–16 are absent entirely. Proposed: whole-chapter WEB fallback for **Esther 10–16**, after the WEB Esther arrangement is reviewed. Tagalog Esther 1–9 can use the existing source text; the additions are to be located in their separate app chapters.
- **Daniel 3** lacks the prayer and song, app verses **24–90**. Its source 3:24–30 corresponds to app 3:91–97; source 4:1–3 supplies app 3:98–100. These partial ranges are recorded, but the incomplete app chapter is blocked. App **Daniel 13 and 14** are absent entirely. Proposed: whole-chapter WEB fallback for **Daniel 3, 13 and 14**, rather than mixing English into a chapter labeled Tagalog or presenting an incomplete chapter.

**Review needed:** accept these additional chapter-level fallbacks and extend the later reader's availability/English-only notice accordingly. The proposed book-level rule “both languages except seven books” is insufficient for these chapters. No copyrighted Tagalog additions were sourced and no fallback has been implemented in the app.

## Psalms: use the quiz's modern numbering

Both sources have Psalms **1–150**, not 151. Inspected `assets/questions/psa.json` confirms modern Hebrew/Protestant chapter numbering, despite the general Vulgate-based comment in `books_data.dart`. Use identity chapter mapping here, not Vulgate/LXX Psalm shifts. Diagnostic checks cover each region where those traditions merge or split Psalms:

| App quiz chapter | Quiz topic | Both source texts at the same numbered Psalm |
|---|---|---|
| 9 / 10 | God judges and remembers afflicted people / wicked oppressors | Two separate Psalms, not a single Vulgate Psalm 9 |
| 22 / 23 | Suffering and divided clothing / shepherd and threatening valley | Suffering in 22; shepherd in 23 |
| 114 / 115 | Sea and Jordan / glory and powerless idols | Separate Exodus imagery / idols |
| 116 / 117 | Rescue and thanksgiving / all nations praising | Separate Psalms; no Vulgate split/recombination |
| 146 / 147 | Trust beyond princes / Jerusalem, scattered Israel and stars | Modern 146 / 147, not Vulgate 147 split |
| 150 | Final praise with instruments and movement | Final Psalm 150 in both sources |

This is a diagnostic chapter-numbering check, not a claim that the quiz is an exact translation of either source. Psalm superscriptions (`\\d`) and section headings are excluded, while in-verse text such as Selah is retained. All 150 Psalm chapters remain non-empty and start at verse 1.

## Phase 0 validation results (2026-11-12)

- **12 Python conversion checks passed**, covering text cleanup, complete source coverage, known verse counts, Joel/Malachi/Daniel renumbering, explicit refusal of pending chapters, license evidence, and byte-identical regeneration.
- **`flutter test --reporter expanded`: all 131 tests passed.**
- **`flutter analyze`: exit 1, 14 pre-existing findings** (11 informational lints and 3 warnings). They occur in unchanged `lib/data/account_controller.dart`, `lib/data/leaderboard_controller.dart`, `lib/data/progress_controller.dart`, `lib/widgets/app_logo.dart`, and `tools/validate_questions.dart`. No Dart files or dependency declarations changed in Phase 0. These findings were not hidden or fixed as unrelated work.
- Raw inputs remain local and ignored; small license evidence, pinned checksums, scripts, mapping, report, inventory and 139 JSON assets are committed. `.gitattributes` preserves deterministic LF outputs and original license-excerpt bytes across Windows checkouts.
- **No Firebase deployment is needed.** Reader implementation, asset registration, web build and installed-app size comparison belong to the later phases, after review.

## Pending chapter inventory

- **web**: `est/5`, `est/15`.
- **tl1905**: `est/10`, `est/11`, `est/12`, `est/13`, `est/14`, `est/15`, `est/16`, `dan/3`, `dan/13`, `dan/14`.

Missing TL1905 books: `1ma`, `2ma`, `bar`, `jdt`, `sir`, `tob`, `wis`.

## Footnote-only verse labels (excluded, never invented)

These labels contain no main verse text after footnotes are removed. Ranges are not expanded into fabricated verses. All chapters remain non-empty.

| Translation | Book | Source labels |
|---|---|---|
| web | sir | 1:5, 1:7, 1:21, 3:19, 10:21, 11:15–16, 13:14, 16:15–16, 17:5, 17:9, 17:16, 17:18, 17:21, 18:3, 19:18–19, 19:21, 20:3, 20:32, 22:9–10, 23:28, 24:18, 24:24, 25:12, 26:19–27 |
| web | luk | 17:36 |
| web | act | 8:37, 15:34, 24:7 |
| web | rom | 16:25 |

Some gaps have no verse marker at all, so they are distinct from footnote-only labels. The complete per-chapter inventory, including all gaps and verse bridges, is in `tools/bible_source_inventory.json`.

## Pinned downloads

| File under data/source/ | Bytes | SHA-256 |
|---|---:|---|
| [eng-web-c_usfm.zip](https://ebible.org/Scriptures/eng-web-c_usfm.zip) | 3,091,065 | `add2ff69c0f07ed4059ee58a9dc391dc4ec77c0b8415dc38a865a1d9f1d3b9cb` |
| [TagAngBiblia.zip](https://www.crosswire.org/ftpmirror/pub/sword/packages/rawzip/TagAngBiblia.zip) | 1,489,402 | `f387b9b93938dba7aba9729d6942f893665c3bf207d77a7fd52421a6a580f874` |
| [tagalog.json](https://api.getbible.net/v2/tagalog.json) | 9,594,856 | `50f653ec89312b0c104788d6abda9693ea4eb69cf85c019d63a67090716ceef0` |

## Reproduce and verify

```text
python tools/download_bible_sources.py
python tools/convert_bible.py
python tools/convert_bible.py --check
python tools/convert_bible.py --app-output build/bible_app_preview
python -m unittest discover -s tools -p "test_bible_sources.py"
flutter analyze
flutter test
```

The converter is offline and checks all three input hashes. The downloader rejects changed upstream files rather than silently importing a different edition.
Raw archives and the large Tagalog JSON stay in ignored `data/source/`. Small extracted license evidence is committed in `data/source/licenses/`.
If network access fails, manually download the three files linked above into `data/source/` with those exact filenames; no substitute text is generated.
