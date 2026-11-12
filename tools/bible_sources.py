"""Offline, deterministic readers for the pinned public-domain Bible inputs.

Python 3.10+, standard library only. No downloading or app/progress changes.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data/source"
TOOLS = ROOT / "tools"
USFM_ALIASES = {"JOL": "joe", "EZK": "eze", "NAM": "nah", "ESG": "est", "DAG": "dan"}
DEUTERO = {"tob", "jdt", "wis", "sir", "bar", "1ma", "2ma"}


def canon() -> list[tuple[str, str, int]]:
    text = (ROOT / "lib/data/books_data.dart").read_text(encoding="utf-8")
    books = re.findall(
        r"Book\('([^']+)', '([^']+)', '[^']+', Testament\.(?:ot|nt), (\d+)", text
    )
    if len(books) != 73:
        raise ValueError("Expected exactly 73 books in books_data.dart")
    return [(book, name, int(count)) for book, name, count in books]


def dump(path: Path, value: object, *, compact: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    options = {"separators": (",", ":")} if compact else {"indent": 2}
    path.write_text(json.dumps(value, ensure_ascii=False, **options) + "\n", encoding="utf-8", newline="\n")


def checked_inputs() -> dict:
    lock = json.loads((TOOLS / "bible_sources.json").read_text(encoding="utf-8"))
    for item in lock["inputs"]:
        path = SOURCE / item["file"]
        if not path.is_file():
            raise FileNotFoundError(f"Download {item['url']} to {path}")
        if hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError(f"Source checksum changed: {path}. Review before updating the lock.")
    return lock


def strip_notes(text: str) -> str:
    # Note bodies can contain nested character markers. Remove the outer span
    # first, so their references and wording never become Scripture text.
    for marker in ("f", "x"):
        text = re.sub(r"\\" + marker + r"\s.*?\\" + marker + r"\*", "", text, flags=re.S)
    if re.search(r"\\(?:f|x)(?:\s|\*)", text):
        raise ValueError("Unbalanced USFM footnote/cross-reference")
    return text


def plain_usfm(text: str) -> str:
    text = re.sub(
        r"\\(\+?w)\s+([^|\\]*)(?:\|[^\\]*)?\\\1\*",
        lambda m: m[2], text,
    )
    # The only retained character styles in this pinned source. Fail closed if
    # the source introduces a marker this converter has not been reviewed for.
    text = re.sub(r"\\(?:wj|qs|bk)\*? ?", "", text)
    if "\\" in text or "|" in text or re.search(r'strong="[HG]\d+', text):
        raise ValueError(f"Unprocessed USFM markup: {text[:150]!r}")
    return " ".join(text.split())


def read_web() -> tuple[dict, dict]:
    books, inventory = {}, {}
    allowed = {book for book, _, _ in canon()}
    # Paragraph/poetry/list boundaries retain their text; metadata, section
    # titles, Psalm superscriptions and speaker labels are excluded.
    paragraph = re.compile(r"(?:p|m|mi|nb|b|pc|pi\d*|q\d*|li\d*)\Z")
    heading = re.compile(r"(?:id|ide|h|toc\d|mt\d?|ms\d?|s\d?|cl|d|sp|i[a-z]+\d*)\Z")
    with zipfile.ZipFile(SOURCE / "eng-web-c_usfm.zip") as archive:
        for name in sorted(archive.namelist()):
            if not name.endswith(".usfm"):
                continue
            raw = archive.read(name).decode("utf-8-sig")
            source_id = re.search(r"\\id (\w+)", raw)[1]
            book = USFM_ALIASES.get(source_id, source_id.lower())
            if book not in allowed:
                if source_id != "FRT":
                    raise ValueError(f"Unexpected source book {source_id}")
                continue
            if book in books:
                raise ValueError(f"Duplicate source book {book}")
            chapters: dict[str, list] = {}
            inventory[book] = {"source_id": source_id, "file": name, "verse_spans": [], "note_only": []}
            chapter, label, parts = None, None, []

            def flush() -> None:
                nonlocal label, parts
                if label is None:
                    return
                start, *end = map(int, label.split("-"))
                finish = end[0] if end else start
                if finish < start:
                    raise ValueError(f"Invalid verse bridge {book} {chapter}:{label}")
                text = plain_usfm(" ".join(parts))
                if text:
                    chapters[chapter].append({"v": start, "t": text})
                else:
                    inventory[book]["note_only"].append({"chapter": int(chapter), "verses": [start, finish]})
                if end:
                    inventory[book]["verse_spans"].append({"chapter": int(chapter), "verses": [start, finish], "has_text": bool(text)})
                label, parts = None, []

            for line in strip_notes(raw).splitlines():
                if not line.strip():
                    continue
                match = re.match(r"\\([a-z][a-z0-9]*)\b ?(.*)", line)
                if match:
                    marker, tail = match.groups()
                    if marker == "c":
                        flush()
                        chapter = tail.strip()
                        if not chapter.isdigit() or chapter in chapters:
                            raise ValueError(f"Invalid/duplicate chapter {book} {chapter}")
                        chapters[chapter] = []
                        continue
                    if marker == "v":
                        flush()
                        verse = re.fullmatch(r"(\d+(?:-\d+)?)\s*(.*)", tail)
                        if chapter is None or verse is None:
                            raise ValueError(f"Invalid verse {book}: {line}")
                        label, tail = verse.groups()
                        parts.append(tail)
                        continue
                    if heading.fullmatch(marker):
                        continue
                    if paragraph.fullmatch(marker):
                        if label is not None:
                            parts.append(tail)
                        continue
                    raise ValueError(f"Unrecognized line marker {book}: {line[:100]}")
                if label is not None:
                    parts.append(line)
            flush()
            # Psalm 151 is outside the requested canon, even if a future source includes it.
            if book == "psa":
                chapters.pop("151", None)
            books[book] = {"book": book, "chapters": chapters}
    return books, inventory


def sword_texts(archive: zipfile.ZipFile, testament: str) -> list[str]:
    """Read zText BOOK/ZIP payloads, independently checking the JSON export.

    .bzs: little-endian (compressed offset, length, uncompressed length) uint32s.
    .bzv: little-endian (block, uncompressed offset) uint32s + uint16 length.
    Intro/heading entries have zero length. The pinned module has no verse markup.
    """
    prefix = "modules/texts/ztext/tagangbiblia/" + testament
    compressed = archive.read(prefix + ".bzz")
    blocks = []
    for offset, length, expected in struct.iter_unpack("<III", archive.read(prefix + ".bzs")):
        block = zlib.decompress(compressed[offset:offset + length])
        if len(block) != expected:
            raise ValueError("Corrupt SWORD block")
        blocks.append(block)
    result = []
    for block, offset, length in struct.iter_unpack("<IIH", archive.read(prefix + ".bzv")):
        if length:
            text = blocks[block][offset:offset + length]
            if len(text) != length:
                raise ValueError("SWORD verse outside its block")
            result.append(text.decode("utf-8"))
    return result


def read_tagalog() -> tuple[dict, dict]:
    data = json.loads((SOURCE / "tagalog.json").read_text(encoding="utf-8"))
    if data["distribution_license"] != "Public Domain" or data["distribution_version"] != "1.2":
        raise ValueError("Unexpected Tagalog edition/license")
    order = [book for book, _, _ in canon() if book not in DEUTERO]
    if len(data["books"]) != len(order):
        raise ValueError("Incomplete Tagalog source")
    # This is a byte-for-byte text comparison, BEFORE whitespace normalization,
    # of all 31,102 verses with the original CrossWire module in canonical order.
    with zipfile.ZipFile(SOURCE / "TagAngBiblia.zip") as archive:
        for testament, subset in (("ot", data["books"][:39]), ("nt", data["books"][39:])):
            exported = [v["text"] for b in subset for c in b["chapters"] for v in c["verses"]]
            if sword_texts(archive, testament) != exported:
                raise ValueError(f"Tagalog JSON differs from CrossWire {testament} payload")
    books, inventory = {}, {}
    for expected_nr, (book, raw) in enumerate(zip(order, data["books"]), 1):
        if raw["nr"] != expected_nr:
            raise ValueError("Tagalog book order changed")
        chapters = {}
        for ch in raw["chapters"]:
            chapter = ch["chapter"]
            if str(chapter) in chapters:
                raise ValueError("Duplicate Tagalog chapter")
            verses = []
            for v in ch["verses"]:
                text = " ".join(v["text"].split())
                if not text or "<" in text or "\\" in text or v["chapter"] != chapter:
                    raise ValueError(f"Unexpected Tagalog verse markup/numbering: {book} {chapter}")
                verses.append({"v": v["verse"], "t": text})
            chapters[str(chapter)] = verses
        books[book] = {"book": book, "chapters": chapters}
        inventory[book] = {"source_id": raw["nr"], "source_name": raw["name"], "verse_spans": [], "note_only": []}
    return books, inventory


def validate_source(books: dict) -> None:
    for book, data in books.items():
        chapters = data["chapters"]
        if list(chapters) != [str(n) for n in range(1, len(chapters) + 1)]:
            raise ValueError(f"Non-sequential chapters: {book}")
        for ch, verses in chapters.items():
            numbers = [v["v"] for v in verses]
            if not verses or numbers != sorted(set(numbers)) or numbers[0] != 1:
                raise ValueError(f"Invalid/empty chapter: {book} {ch}")


def mapped_chapter(books: dict, mapping: dict, translation: str, book: str, chapter: int) -> list[dict]:
    """Return a verified app chapter with explicit destination verse numbering.

    JSON assets retain source coordinates. This function is the executable
    reference for the Phase 1 repository; unresolved/incomplete chapters fail closed.
    """
    translation_map = mapping["translations"][translation]
    if book in translation_map["missing_books"]:
        raise ValueError(f"Missing translation: {translation}/{book}")
    rule = translation_map["books"].get(book)
    if rule and chapter in rule["pending_chapters"]:
        raise ValueError(f"Needs review: {translation}/{book}/{chapter}")
    if rule:
        result = []
        for segment in rule["chapters"][str(chapter)]:
            low, high = segment["source_verses"]
            selected = [v for v in books[segment["source_book"]]["chapters"][str(segment["source_chapter"])] if low <= v["v"] <= high]
            if not selected or selected[0]["v"] != low or selected[-1]["v"] != high:
                raise ValueError("Mapping endpoints absent from source")
            for verse in selected:
                result.append({"v": segment["app_verse_start"] + verse["v"] - low, "t": verse["t"]})
        if not result or result[0]["v"] != 1 or len({v['v'] for v in result}) != len(result):
            raise ValueError("Invalid mapped verse numbers")
        return result
    return books[book]["chapters"][str(chapter)]
