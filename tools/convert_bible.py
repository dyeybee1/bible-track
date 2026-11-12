"""Convert pinned inputs to source-numbered assets and a reproducible report.

Run: python tools/convert_bible.py [--check] [--app-output build/bible_app_preview]
The optional preview applies VERIFIED mappings, including renumbering. It omits
pending chapters and is for review only. Phase 1 must apply the mapping exactly
once when loading the bundled, source-numbered assets.
"""

import argparse
import hashlib
import json
from pathlib import Path
import zipfile

from bible_sources import (
    ROOT, SOURCE, TOOLS, canon, checked_inputs, mapped_chapter,
    read_tagalog, read_web, validate_source,
)


def encoded(value: object, compact: bool = False) -> bytes:
    options = {"separators": (",", ":")} if compact else {"indent": 2}
    return (json.dumps(value, ensure_ascii=False, **options) + "\n").encode("utf-8")


def inventory_for(books: dict, inventory: dict) -> dict:
    for book, data in books.items():
        item = inventory[book]
        item["chapter_count"] = len(data["chapters"])
        item["chapters"] = {}
        for chapter, verses in data["chapters"].items():
            numbers = {v["v"] for v in verses}
            item["chapters"][chapter] = {
                "text_verses": len(verses),
                "last_verse": verses[-1]["v"],
                "absent_text_labels": sorted(set(range(1, verses[-1]["v"] + 1)) - numbers),
            }
    return inventory


def verify_mappings(translations: dict, mapping: dict) -> dict:
    coverage = {}
    for translation, books in translations.items():
        rules = mapping["translations"][translation]
        missing = {book for book, _, _ in canon()} - books.keys()
        if missing != set(rules["missing_books"]):
            raise ValueError(f"Unrecorded missing books: {translation}")
        coverage[translation] = {"verified_app_chapters": 0, "pending_app_chapters": [], "missing_books": sorted(missing)}
        for book, _, count in canon():
            if book in missing:
                continue
            rule = rules["books"].get(book)
            pending = rule["pending_chapters"] if rule else []
            if rule and set(rule["chapters"]) != {str(c) for c in range(1, count + 1)}:
                raise ValueError(f"Incomplete mapping chapter keys: {translation}/{book}")
            for ch in range(1, count + 1):
                if ch in pending:
                    coverage[translation]["pending_app_chapters"].append(f"{book}/{ch}")
                    continue
                verses = mapped_chapter(books, mapping, translation, book, ch)
                if not verses or verses[0]["v"] != 1 or any(not v["t"] for v in verses):
                    raise ValueError(f"Empty/invalid mapped chapter: {translation}/{book}/{ch}")
                coverage[translation]["verified_app_chapters"] += 1
            # Every resolved remapping must retain every source verse exactly
            # once. A bad split/merge must not silently duplicate or lose text.
            if rule and not pending:
                used = []
                for segments in rule["chapters"].values():
                    for segment in segments:
                        low, high = segment["source_verses"]
                        used.extend((segment["source_chapter"], v["v"]) for v in books[book]["chapters"][str(segment["source_chapter"])] if low <= v["v"] <= high)
                original = {(int(c), v["v"]) for c, vs in books[book]["chapters"].items() for v in vs}
                if len(used) != len(set(used)) or set(used) != original:
                    raise ValueError(f"Mapping duplicates or loses verses: {translation}/{book}")
    return coverage


def report(translations: dict, inventories: dict, coverage: dict, assets: dict, lock: dict) -> str:
    lines = [
        "# Bible text: Phase 0 source and numbering report", "",
        "Generated deterministically by `python tools/convert_bible.py`. Source retrieval: " + lock["retrieved_on"] + ".",
        "No app, UI, progress, sync, Firestore rules, or Firebase deployment changes. Stop here for review.", "",
        "## Result", "",
        f"Converted {sum(len(b) for b in translations.values())} compact UTF-8 book JSON files: 73 WEB and 66 Tagalog.",
        "Assets retain SOURCE chapter/verse numbers. `tools/bible_mapping.json` explicitly maps them to app chapters; the Phase 1 repository must apply it once.",
        "`mapped_chapter` in `tools/bible_sources.py` is the executable mapping reference. It renumbers Joel 3 to 1–5, Joel 4 to 1–21, Malachi 3 to 1–24, and Daniel 4 to 1–34.",
        "Pending chapters raise an error rather than inventing text or silently displaying a partial chapter.",
        "Use `--app-output build/bible_app_preview` to inspect files with the verified mappings and renumbering already applied. Pending chapters are omitted from that review-only preview.", "",
        "| Translation | Source books | Source chapters | Non-empty source verse entries | Verified app chapters | Pending app chapters |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for t, books in translations.items():
        lines.append(f"| {t} | {len(books)} | {sum(len(b['chapters']) for b in books.values())} | {sum(len(vs) for b in books.values() for vs in b['chapters'].values())} | {coverage[t]['verified_app_chapters']} | {len(coverage[t]['pending_app_chapters'])} |")
    total = sum(len(data) for data in assets.values())
    lines += ["", f"JSON files occupy **{total:,} bytes ({total / 1_000_000:.2f} MB; {total / 1024**2:.2f} MiB)** before packaging/compression.",
              "They are not registered in pubspec.yaml yet (Phase 1); this is data size, not a measured installed-app increase.", "",
              "## Every-book chapter comparison", "",
              "Counts below are measured from the pinned inputs. Missing means the source has no book, not zero-length invented chapters.",
              "Equal chapter counts alone do not prove verse-by-verse equivalence with every Catholic edition. The app uses mixed conventions (notably modern Psalm numbering).", "",
              "| ID | Book | App chapters | WEB source chapters | WEB result | TL1905 source chapters | TL1905 result |",
              "|---|---|---:|---:|---|---:|---|"]
    for book, name, count in canon():
        row = [book, name, str(count)]
        for t, books in translations.items():
            if book not in books:
                row += ["missing", "missing book; WEB fallback"]
                continue
            source_count = len(books[book]["chapters"])
            rule = json.loads((TOOLS / "bible_mapping.json").read_text(encoding="utf-8"))["translations"][t]["books"].get(book)
            status = ("needs review (partial additions)" if t == "tl1905" else "needs review (embedded additions)") if rule and rule["pending_chapters"] else "mapped" if rule else "same chapter count"
            if book == "psa": status = "modern numbering matches quiz; no Psalm 151"
            if book == "sir": status = "51; prologue excluded; source verse gaps retained"
            if book == "bar": status = "6 includes Letter of Jeremiah"
            row += [str(source_count), status]
        lines.append("| " + " | ".join(row) + " |")
    lines += ["", (TOOLS / "bible_review_notes.md").read_text(encoding="utf-8").rstrip(), "",
              "## Pending chapter inventory", ""]
    for t, info in coverage.items():
        lines.append(f"- **{t}**: " + ", ".join(f"`{c}`" for c in info["pending_app_chapters"]) + ".")
    lines += ["", "Missing TL1905 books: " + ", ".join(f"`{b}`" for b in coverage["tl1905"]["missing_books"]) + ".", "",
              "## Footnote-only verse labels (excluded, never invented)", "",
              "These labels contain no main verse text after footnotes are removed. Ranges are not expanded into fabricated verses. All chapters remain non-empty.", "",
              "| Translation | Book | Source labels |", "|---|---|---|"]
    for t, books in inventories.items():
        for book, item in books.items():
            if item["note_only"]:
                labels = [f"{v['chapter']}:{v['verses'][0]}" + (f"–{v['verses'][1]}" if v['verses'][1] != v['verses'][0] else "") for v in item["note_only"]]
                lines.append(f"| {t} | {book} | {', '.join(labels)} |")
    lines += ["", "Some gaps have no verse marker at all, so they are distinct from footnote-only labels. The complete per-chapter inventory, including all gaps and verse bridges, is in `tools/bible_source_inventory.json`.", "",
              "## Pinned downloads", "", "| File under data/source/ | Bytes | SHA-256 |", "|---|---:|---|"]
    for item in lock["inputs"]:
        lines.append(f"| [{item['file']}]({item['url']}) | {item['bytes']:,} | `{item['sha256']}` |")
    lines += ["", "## Reproduce and verify", "", "```text",
              "python tools/download_bible_sources.py",
              "python tools/convert_bible.py",
              "python tools/convert_bible.py --check",
              "python tools/convert_bible.py --app-output build/bible_app_preview",
              'python -m unittest discover -s tools -p "test_bible_sources.py"',
              "flutter analyze", "flutter test", "```", "",
              "The converter is offline and checks all three input hashes. The downloader rejects changed upstream files rather than silently importing a different edition.",
              "Raw archives and the large Tagalog JSON stay in ignored `data/source/`. Small extracted license evidence is committed in `data/source/licenses/`.",
              "If network access fails, manually download the three files linked above into `data/source/` with those exact filenames; no substitute text is generated.", ""]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify committed outputs without writing")
    parser.add_argument("--app-output", type=Path, help="Optional verified app-numbered preview directory")
    args = parser.parse_args()
    if args.check and args.app_output:
        parser.error("--check and --app-output cannot be combined")
    lock = checked_inputs()
    web, web_inventory = read_web()
    tl, tl_inventory = read_tagalog()
    translations = {"web": web, "tl1905": tl}
    inventories = {"web": inventory_for(web, web_inventory), "tl1905": inventory_for(tl, tl_inventory)}
    for books in translations.values():
        validate_source(books)
    mapping = json.loads((TOOLS / "bible_mapping.json").read_text(encoding="utf-8"))
    coverage = verify_mappings(translations, mapping)
    outputs = {ROOT / f"assets/bible/{t}/{book}.json": encoded(data, compact=True) for t, books in translations.items() for book, data in books.items()}
    asset_outputs = outputs.copy()
    outputs[TOOLS / "bible_source_inventory.json"] = encoded({"schema_version": 1, "numbering": "source", "translations": inventories, "coverage": coverage})
    with zipfile.ZipFile(SOURCE / "eng-web-c_usfm.zip") as archive:
        outputs[SOURCE / "licenses/eng-web-c-copr.htm"] = archive.read("copr.htm")
    with zipfile.ZipFile(SOURCE / "TagAngBiblia.zip") as archive:
        outputs[SOURCE / "licenses/tagangbiblia.conf"] = archive.read("mods.d/tagangbiblia.conf")
    data = json.loads((SOURCE / "tagalog.json").read_text(encoding="utf-8"))
    outputs[SOURCE / "licenses/tagalog-metadata.json"] = encoded({k: v for k, v in data.items() if k != "books"})
    outputs[TOOLS / "bible_text_report.md"] = report(translations, inventories, coverage, asset_outputs, lock).encode("utf-8")
    differences = []
    for path, content in outputs.items():
        if args.check:
            if not path.is_file() or path.read_bytes() != content:
                differences.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
    if differences:
        raise SystemExit("Generated outputs differ:\n" + "\n".join(differences))
    actual_assets = set((ROOT / "assets/bible").glob("*/*.json"))
    if actual_assets != set(asset_outputs):
        raise SystemExit("Unexpected Bible asset files; inspect and remove stale output explicitly.")
    if args.app_output:
        # Do not allow a review preview to overwrite source assets or live inputs.
        preview = (ROOT / args.app_output).resolve()
        build = (ROOT / "build").resolve()
        if build not in preview.parents:
            raise SystemExit("--app-output must be a subdirectory of build/")
        for t, books in translations.items():
            for book, _, count in canon():
                if book not in books:
                    continue
                pending = mapping["translations"][t]["books"].get(book, {}).get("pending_chapters", [])
                chapters = {str(c): mapped_chapter(books, mapping, t, book, c) for c in range(1, count + 1) if c not in pending}
                path = preview / t / f"{book}.json"
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(encoded({"book": book, "chapters": chapters}, compact=True))
    digest = hashlib.sha256(b"".join(outputs[p] for p in sorted(outputs))).hexdigest()
    print(f"{'Verified' if args.check else 'Generated'} {len(asset_outputs)} source-numbered assets; output digest {digest}")
    print("Needs review: WEB Esther arrangement; Tagalog additions require chapter-level English fallback. See tools/bible_text_report.md.")


if __name__ == "__main__":
    main()
