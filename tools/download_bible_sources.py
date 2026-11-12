"""Download the exact, checksum-pinned inputs; never silently accept an update.

Run: python tools/download_bible_sources.py
Alternatively download the three URLs in bible_sources.json to data/source/.
"""

import hashlib
import json
from urllib.request import urlopen

from bible_sources import SOURCE, TOOLS


def main() -> None:
    SOURCE.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((TOOLS / "bible_sources.json").read_text(encoding="utf-8"))
    for item in manifest["inputs"]:
        target = SOURCE / item["file"]
        if target.exists():
            data = target.read_bytes()
        else:
            try:
                with urlopen(item["url"], timeout=60) as response:
                    data = response.read()
            except OSError as error:
                raise SystemExit(f"Download failed: {error}\nDownload {item['url']} manually to {target}") from error
        if hashlib.sha256(data).hexdigest() != item["sha256"]:
            raise SystemExit(f"Checksum mismatch: {target}. The source may have changed. Review before replacing the pinned input.")
        if not target.exists():
            target.write_bytes(data)
        print(f"Verified {item['file']} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
