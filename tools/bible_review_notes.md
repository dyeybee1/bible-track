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
