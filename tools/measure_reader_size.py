"""Measure real release artifacts against the isolated pre-reader build.

Run after identical release web/APK/AAB builds:
python tools/measure_reader_size.py --baseline build/reader_size/baseline
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT=Path(__file__).resolve().parents[1]


def snapshot(root):
    paths={'APK':root/'build/app/outputs/flutter-apk/app-release.apk',
           'AAB':root/'build/app/outputs/bundle/release/app-release.aab'}
    result={}
    for label,path in paths.items():
        if not path.is_file():raise SystemExit(f'Missing {label}: {path}')
        with zipfile.ZipFile(path) as archive:
            bible=[n for n in archive.namelist() if '/assets/bible/' in n and n.endswith('.json')]
            result[label]={'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                           'bible_files':len(bible),'bible_compressed_bytes':sum(archive.getinfo(n).compress_size for n in bible)}
    web=root/'build/web'
    if not (web/'main.dart.js').is_file():raise SystemExit(f'Missing release web build: {web}')
    files=[p for p in web.rglob('*') if p.is_file()]
    result['Web output']={'bytes':sum(p.stat().st_size for p in files),'files':len(files)}
    return result


def verify_bundles():
    assets={p.relative_to(ROOT).as_posix():p.read_bytes() for p in (ROOT/'assets/bible').rglob('*.json')}
    for label,archive_path,prefix in [('APK','build/app/outputs/flutter-apk/app-release.apk','assets/flutter_assets/'),
                                      ('AAB','build/app/outputs/bundle/release/app-release.aab','base/assets/flutter_assets/')]:
        with zipfile.ZipFile(ROOT/archive_path) as archive:
            for name,data in assets.items():
                if archive.read(prefix+name)!=data:raise SystemExit(f'{label} contains stale text: {name}')
    for name,data in assets.items():
        if (ROOT/'build/web/assets'/name).read_bytes()!=data:raise SystemExit(f'Web contains stale text: {name}')
    manifest_text=(ROOT/'web/reader_offline_assets.js').read_text(encoding='utf8')
    manifest=json.loads(manifest_text.split('self.READER_OFFLINE = ',1)[1].strip().removesuffix(';'))
    worker=(ROOT/'web/reader_service_worker.js').read_text(encoding='utf8')
    core_block=worker.split('const CORE = [',1)[1].split('];',1)[0]
    core=re.findall(r"'([^']+)'",core_block)
    fonts=json.loads((ROOT/'build/web/assets/FontManifest.json').read_text(encoding='utf8'))
    required=set(core+manifest['files']+['assets/'+font['asset'] for family in fonts for font in family['fonts']])
    for name in required:
        if not (ROOT/'build/web'/name).is_file():raise SystemExit(f'Offline cache path missing from web output: {name}')
    bootstrap=(ROOT/'build/web/flutter_bootstrap.js').read_text(encoding='utf8')
    if 'reader_service_worker.js' not in bootstrap or 'canvasKitBaseUrl' not in bootstrap:
        raise SystemExit('Custom offline bootstrap not in release build')
    return len(assets),len(required)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline',type=Path,required=True)
    args=parser.parse_args()
    baseline=snapshot((ROOT/args.baseline).resolve());current=snapshot(ROOT)
    if baseline['APK']['bible_files'] or baseline['AAB']['bible_files']:
        raise SystemExit('Baseline unexpectedly bundles Bible text')
    asset_count,cache_files=verify_bundles()
    data={'baseline_commit':'0568071','configuration':'Flutter 3.44.0 / Dart 3.12.0; release; identical pubspec.lock; default universal Android architectures; same local signing configuration',
          'baseline':baseline,'reader':current,'added_bytes':{k:current[k]['bytes']-baseline[k]['bytes'] for k in current},
          'verified_bible_assets_per_platform':asset_count,'offline_cache_files':cache_files}
    lines=['# Reader release size comparison','',data['configuration'],
      'Baseline source was archived from commit `0568071` before asset registration and UI changes. Measurements use built APK/AAB archives and all files in the release web output, not source-size estimates. MB = 1,000,000 bytes.','',
      '| Output | Baseline bytes | Reader bytes | Added bytes | Added MB |','|---|---:|---:|---:|---:|']
    for label in current:
        delta=data['added_bytes'][label]
        lines.append(f"| {label} | {baseline[label]['bytes']:,} | {current[label]['bytes']:,} | {delta:+,} | {delta/1_000_000:+.3f} |")
    lines+=['',f'Each platform contains **{asset_count} byte-verified Bible JSON files**, including the mapping. Baseline APK/AAB contained none.',
      f"Compressed Bible text contribution: APK {current['APK']['bible_compressed_bytes']:,} bytes; AAB {current['AAB']['bible_compressed_bytes']:,} bytes.",
      f"Web file counts: baseline {baseline['Web output']['files']}; reader {current['Web output']['files']}. All {cache_files} offline precache paths exist in the release output.",
      'The web total is the uncompressed build directory footprint, including local renderer files; it is not a measured HTTP transfer size. AAB size is the upload archive, not a Play Store per-device download estimate.',
      'The PWA prepares static app files, all Bible books, quizzes and local rendering resources on the first online visit. Offline use is available after that cache installation completes. Native APK/AAB text is bundled immediately. No Firebase documents, auth endpoints or sync responses are cached by the reader worker.','',
      '## Reproduce','', '```text','python tools/convert_bible.py','flutter build web --release','flutter build apk --release --no-pub','flutter build appbundle --release --no-pub',
      'python tools/measure_reader_size.py --baseline build/reader_size/baseline','```','',
      'Machine-readable artifact sizes and SHA-256 values are in `reader_size_report.json`. Release artifacts stay under ignored build directories; no deployment was performed.','']
    (ROOT/'tools/reader_size_report.md').write_text('\n'.join(lines),encoding='utf8',newline='\n')
    (ROOT/'tools/reader_size_report.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf8',newline='\n')
    for label,delta in data['added_bytes'].items():print(f'{label}: {delta:+,} bytes ({delta/1_000_000:+.3f} MB)')

if __name__=='__main__':main()
