"""Text-fidelity and numbering checks for Phase 0 (standard library only)."""

import json
import subprocess
import sys
import unittest

from bible_sources import (
    DEUTERO, ROOT, SOURCE, TOOLS, canon, checked_inputs, mapped_chapter,
    plain_usfm, read_tagalog, read_web, strip_notes, validate_source,
)
from convert_bible import verify_mappings


class BibleSourcesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        checked_inputs()
        cls.web, cls.web_inventory = read_web()
        cls.tl, cls.tl_inventory = read_tagalog()
        cls.translations = {"web": cls.web, "tl1905": cls.tl}
        cls.mapping = json.loads((TOOLS / "bible_mapping.json").read_text(encoding="utf-8"))

    def chapter(self, translation, book, chapter):
        return mapped_chapter(self.translations[translation], self.mapping, translation, book, chapter)

    def test_remove_notes_and_attributes_without_changing_scripture(self):
        raw = r'\w LORD|strong="H3068"\w*’s\f + \fr 1:1 \ft Not verse text: \+w name|strong="H1"\+w*.\f* word\x + \xo 1:1 \xt John 1:1\x*.'
        self.assertEqual(plain_usfm(strip_notes(raw)), "LORD’s word.")
        self.assertEqual(plain_usfm(r'\wj Come\wj*, \w now|strong="G1"\w*!'), "Come, now!")

    def test_unknown_markup_and_unclosed_notes_fail(self):
        with self.assertRaises(ValueError):
            plain_usfm(r"text \newstyle unreviewed")
        with self.assertRaises(ValueError):
            strip_notes(r"text \f + unclosed note")

    def test_complete_source_canon_and_nonempty_clean_text(self):
        expected = {book for book, _, _ in canon()}
        self.assertEqual(set(self.web), expected)
        self.assertEqual(set(self.tl), expected - DEUTERO)
        self.assertEqual(sum(len(vs) for b in self.tl.values() for vs in b["chapters"].values()), 31102)
        for t, books in self.translations.items():
            validate_source(books)
            for book, data in books.items():
                self.assertEqual(data["book"], book)
                for ch, verses in data["chapters"].items():
                    for verse in verses:
                        with self.subTest(translation=t, book=book, chapter=ch, verse=verse["v"]):
                            self.assertTrue(verse["t"].strip())
                            self.assertNotRegex(verse["t"], r'\\|strong="|<[^>]+>')

    def test_known_source_chapters_and_literal_text(self):
        self.assertEqual(self.web["gen"]["chapters"]["1"][0]["t"], "In the beginning, God created the heavens and the earth.")
        self.assertEqual(self.tl["gen"]["chapters"]["1"][0]["t"], "Nang pasimula ay nilikha ng Dios ang langit at ang lupa.")
        for books in self.translations.values():
            for book, ch, count in [("gen", "1", 31), ("psa", "119", 176), ("jhn", "3", 36)]:
                self.assertEqual(len(books[book]["chapters"][ch]), count)
            self.assertEqual(len(books["psa"]["chapters"]), 150)
            self.assertNotIn("151", books["psa"]["chapters"])
        self.assertEqual(len(self.web["bar"]["chapters"]["6"]), 73)
        self.assertEqual(len(self.web["dan"]["chapters"]["13"]), 64)
        self.assertEqual(len(self.web["dan"]["chapters"]["14"]), 42)

    def test_joel_split_is_renumbered_in_both_languages(self):
        for t in self.translations:
            ch2 = self.chapter(t, "joe", 2)
            ch3 = self.chapter(t, "joe", 3)
            ch4 = self.chapter(t, "joe", 4)
            self.assertEqual([v["v"] for v in ch2], list(range(1, 28)))
            self.assertEqual([v["v"] for v in ch3], list(range(1, 6)))
            self.assertEqual([v["v"] for v in ch4], list(range(1, 22)))
            self.assertEqual(ch3[0]["t"], self.translations[t]["joe"]["chapters"]["2"][27]["t"])
        self.assertIn("pour out my Spirit", self.chapter("web", "joe", 3)[0]["t"])
        self.assertIn("Judah and Jerusalem", self.chapter("web", "joe", 4)[0]["t"])

    def test_malachi_merge_keeps_final_six_verses(self):
        for t in self.translations:
            ch3 = self.chapter(t, "mal", 3)
            self.assertEqual([v["v"] for v in ch3], list(range(1, 25)))
            self.assertEqual([v["t"] for v in ch3[18:]], [v["t"] for v in self.translations[t]["mal"]["chapters"]["4"]])
        self.assertIn("burning", self.chapter("web", "mal", 3)[18]["t"])

    def test_daniel_additions_and_royal_proclamation_boundary(self):
        ch3 = self.chapter("web", "dan", 3)
        ch4 = self.chapter("web", "dan", 4)
        self.assertEqual([v["v"] for v in ch3], list(range(1, 101)))
        self.assertEqual([v["v"] for v in ch4], list(range(1, 35)))
        self.assertIn("Azarias", ch3[24]["t"])
        self.assertIn("Peace be multiplied", ch3[97]["t"])
        self.assertIn("at rest in my house", ch4[0]["t"])
        self.assertEqual(len(self.chapter("tl1905", "dan", 4)), 34)

    def test_pending_and_missing_chapters_never_silently_load_partial_text(self):
        for t, book, ch in [("web", "est", 5), ("web", "est", 15), ("tl1905", "est", 10), ("tl1905", "est", 16), ("tl1905", "dan", 3), ("tl1905", "dan", 13)]:
            with self.subTest(translation=t, book=book, chapter=ch):
                with self.assertRaisesRegex(ValueError, "Needs review"):
                    self.chapter(t, book, ch)
        for book in DEUTERO:
            with self.assertRaisesRegex(ValueError, "Missing translation"):
                self.chapter("tl1905", book, 1)

    def test_sirach_and_esther_preserve_source_omissions_without_invented_text(self):
        self.assertEqual(len(self.web["sir"]["chapters"]), 51)
        self.assertEqual(self.web["sir"]["chapters"]["1"][0]["v"], 1)
        self.assertNotIn(5, [v["v"] for v in self.web["sir"]["chapters"]["1"]])
        self.assertNotIn(19, [v["v"] for v in self.web["sir"]["chapters"]["26"]])
        self.assertTrue(any(v["verses"] == [19, 27] for v in self.web_inventory["sir"]["note_only"]))
        self.assertNotIn("WHEREAS many", self.web["sir"]["chapters"]["1"][0]["t"])
        # Actual source insertion disagrees with the introduction: do not move
        # its letter to 8:12 merely because the introduction says so.
        self.assertIn("copy of the letter", self.web["est"]["chapters"]["8"][12]["t"])
        prayer = self.chapter("web", "est", 14)
        self.assertEqual([v["v"] for v in prayer], list(range(1, 20)))
        self.assertIn("queen Esther took refuge", prayer[0]["t"])

    def test_every_app_chapter_is_verified_or_explicitly_pending_or_missing(self):
        coverage = verify_mappings(self.translations, self.mapping)
        self.assertEqual(len(coverage["web"]["pending_app_chapters"]), 2)
        self.assertEqual(len(coverage["tl1905"]["pending_app_chapters"]), 10)
        self.assertEqual(set(coverage["tl1905"]["missing_books"]), DEUTERO)
        self.assertEqual(coverage["web"]["verified_app_chapters"] + 2, sum(c for _, _, c in canon()))

    def test_esther_literal_spans_keep_flags_and_never_overlap(self):
        rule = self.mapping['translations']['web']['books']['est']
        self.assertEqual(rule['review_required_chapters'], [1,3,5,8,11,12,13,15,16])
        self.assertEqual(rule['review_status'], 'needs review')
        used = {}
        for ch, segments in rule['chapters'].items():
            if int(ch) in rule['pending_chapters']:
                continue
            for segment in segments:
                lo,hi=segment['source_verses']
                for v in self.web['est']['chapters'][str(segment['source_chapter'])]:
                    if not lo<=v['v']<=hi:continue
                    text=v['t'];key=(segment['source_chapter'],v['v'])
                    start=text.index(segment['text_start']) if 'text_start' in segment else 0
                    end=text.index(segment['text_end']) if 'text_end' in segment else len(text)
                    for old_start,old_end in used.get(key,[]):
                        self.assertTrue(end<=old_start or start>=old_end, (key,ch))
                    used.setdefault(key,[]).append((start,end))
        for chapter,count in [(11,12),(12,6),(13,18),(16,24)]:
            self.assertEqual(len(mapped_chapter(self.web,self.mapping,'web','est',chapter)),count)

    def test_license_evidence_came_from_downloaded_sources(self):
        conf = (SOURCE / "licenses/tagangbiblia.conf").read_text(encoding="utf-8")
        self.assertIn("DistributionLicense=Public Domain", conf)
        self.assertIn("Philippine Bible Society (1905)", conf)
        web_license = (SOURCE / "licenses/eng-web-c-copr.htm").read_text(encoding="utf-8")
        self.assertIn('"World English Bible" is a Trademark of eBible.org.', web_license)

    def test_committed_conversion_is_reproducible(self):
        result = subprocess.run([sys.executable, "tools/convert_bible.py", "--check"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
