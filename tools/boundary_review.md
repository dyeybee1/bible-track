# English boundary review — APP numbering

Created before Phase 1 implementation, following the user’s Phase 0 review. Regenerate with `python tools/review_bible_boundaries.py`.
Source: pinned public-domain WEB Catholic USFM, ID eng-web-c. Ranges use SOURCE coordinates; the chapter column uses APP coordinates. Word boundaries are whitespace-separated words, with punctuation retained. Verse counts count non-empty rendered entries, not the highest verse label.
All earlier Esther **needs review** flags remain until the user confirms the boundaries. High-confidence literal spans can be displayed while that flag remains in this document and the mapping. Uncertain chapters are **text pending**, with no app Scripture text fabricated.
Reader policy now follows the app language without fallback. Tagalog is unavailable for Esther 10-16, Daniel 3/13/14 and the seven absent books; users may switch the app to English in Settings. Earlier fallback approval is superseded.

| App chapter | Source ranges used | Rendered verses | First 12 English words | Last 12 English words | Status |
|---|---|---:|---|---|---|
| Joel 2 | joe 2:1–27 | 27 | Blow the trumpet in Zion, and sound an alarm in my holy | is no one else; and my people will never again be disappointed. | verified against source |
| Joel 3 | joe 2:28–32 | 5 | “It will happen afterward, that I will pour out my Spirit on | LORD has said, and among the remnant, those whom the LORD calls. | verified against source |
| Joel 4 | joe 3:1–21 | 21 | “For, behold, in those days, and in that time, when I restore | blood that I have not cleansed, for the LORD dwells in Zion.” | verified against source |
| Malachi 3 | mal 3:1–18; mal 4:1–6 | 24 | “Behold, I send my messenger, and he will prepare the way before | their fathers, lest I come and strike the earth with a curse.” | verified against source |
| Esther 10 | est 10:1–13 | 13 | The king levied a tax upon his kingdom both by land and | and gladness before God, throughout the generations forever among his people Israel. | verified against source |
| Esther 11 | est 10:14–14 (1 literal span); est 1:1–1 (11 literal spans) | 12 | In the fourth year of the reign of Ptolemeus and Cleopatra, Dositheus, | heart, and desired by all means to interpret it, even until night. | **needs review (retained)**; high-confidence literal spans |
| Esther 12 | est 1:1–1 (6 literal spans) | 6 | Mordecai rested quietly in the palace with Gabatha and Tharrha the king’s | to harm Mordecai and his people, because of the king’s two chamberlains. | **needs review (retained)**; high-confidence literal spans |
| Esther 13 | est 3:13–13 (7 literal spans); est 4:18–18 (1 literal span); est 4:19–28 | 18 | The following is the copy of the letter. “From the great King | Israel cried with all their might, for death was before their eyes. | **needs review (retained)**; high-confidence literal spans |
| Esther 14 | est 4:29–46; est 4:47–47 (1 literal span) | 19 | And queen Esther took refuge in the Lord, being taken as it | the hand of those who devise mischief. Deliver me from my fear. | verified against source |
| Esther 15 | None assigned; candidate ESG 5:1–14 (app 5) / ESG 4:8 + 5:1–2 (app 15) | 0 | — no app text | — no app text | **needs review; text pending** |
| Esther 16 | est 8:13–13 (24 literal spans) | 24 | The great King Ahasuerus sends greetings to the rulers of provinces in | inaccessible to men, but most hateful to wild beasts and birds forever. | **needs review (retained)**; high-confidence literal spans |
| Daniel 3 | dan 3:1–97; dan 4:1–3 | 100 | Nebuchadnezzar the king made an image of gold, whose height was sixty | kingdom is an everlasting kingdom. His dominion is from generation to generation. | verified against source |
| Daniel 13 | dan 13:1–64 | 64 | A man lived in Babylon, and his name was Joakim. He took | forth, Daniel had a great reputation in the sight of the people. | verified against source |
| Daniel 14 | dan 14:1–42 | 42 | King Astyages was gathered to his fathers, and Cyrus the Persian received | the den; and they were devoured in a moment before his face. | verified against source |
| Baruch 6 | bar 6:1–73 | 73 | A copy of a letter that Jeremy sent to those who were | man who has no idols; for he will be far from reproach. | verified against source |
| Sirach 51 | sir 51:1–30 | 30 | I will give thanks to you, O Lord, O King, and will | time comes, and in his time he will give you your reward. | verified against source |
| Psalms 51 | psa 51:1–19 | 19 | Have mercy on me, God, according to your loving kindness. According to | in whole burnt offerings. Then they will offer bulls on your altar. | verified against source |
| Psalms 119 | psa 119:1–176 | 176 | Blessed are those whose ways are blameless, who walk according to the | a lost sheep. Seek your servant, for I don’t forget your commandments. | verified against source |

## Exact Esther split evidence

The exact inclusive start / exclusive end anchors are committed in `tools/bible_mapping.json`. The Python reference and Dart repository both reject missing, repeated or reversed anchors rather than guessing offsets. Edition square brackets around additions are excluded by explicit span endpoints; no source words are corrected or paraphrased.
Esther 10 is source 10:1–13; source 10:14 (Dositheus colophon) moves to app 11:1. Source 1:1 is divided into the dream (11:2–12), conspiracy (12:1–6), and main narrative (1:1). Source 3:13 supplies the hostile letter (13:1–7) and main narrative (3:13); source 4:18–28 is 13:8–18. Source 4:29–47 is 14:1–19. Source 8:13 supplies the protective letter (16:1–24) and main narrative (8:13).
Numbering references only (their wording is NOT bundled): [Esther 11](https://ebible.org/engDRA/EST11.htm), [12](https://ebible.org/engDRA/EST12.htm), [13](https://ebible.org/engDRA/EST13.htm), [14](https://ebible.org/engDRA/EST14.htm), [15](https://ebible.org/engDRA/EST15.htm), [16](https://ebible.org/engDRA/EST16.htm).

## Text-pending chapters — needs review

WEB Esther 5 and 15 stay pending. The expanded audience in source 5:1–2 overlaps the main narrative. App 15 also repeats Mordecai’s instructions from source 4:8. There is no second, separate Hebrew-form English 5:1–2 in this pinned source. A complete non-duplicating assignment cannot be asserted confidently without further review. Do not substitute Douay-Rheims, paraphrase WEB, silently omit those words, or duplicate the whole audience.
For audit only, the candidate ranges below are NOT displayed as app text:

| Candidate only | Source verse entries | First 12 source words | Last 12 source words |
|---|---:|---|---|
| Esther 5 candidate — needs review | 14 | It came to pass on the third day, when she had ceased | and be merry.” The saying pleased Haman, and the gallows was prepared. |
| Esther 15 candidate — needs review | 3 | And he gave him the copy of what was published in Susa | fell. Then the king was troubled, and all his servants comforted her. |

The reader treats text pending separately from a loading failure. Its quiz / no-question mark action stays available, and merely opening the chapter never changes progress.
