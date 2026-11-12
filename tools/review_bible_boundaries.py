"""Reproduce the requested English boundaries in APP chapter numbering."""
import json
from bible_sources import ROOT, TOOLS, canon, mapped_chapter

REQUESTED = [('joe',2),('joe',3),('joe',4),('mal',3)]+[('est',c) for c in range(10,17)]+[('dan',3),('dan',13),('dan',14),('bar',6),('sir',51),('psa',51),('psa',119)]

def main():
    mapping=json.loads((TOOLS/'bible_mapping.json').read_text(encoding='utf8'))
    books={p.stem:json.loads(p.read_text(encoding='utf8')) for p in (ROOT/'assets/bible/web').glob('*.json')}
    names={b:n for b,n,_ in canon()}
    lines=['# English boundary review — APP numbering','',
      'Created before Phase 1 implementation, following the user’s Phase 0 review. Regenerate with `python tools/review_bible_boundaries.py`.',
      'Source: pinned public-domain WEB Catholic USFM, ID eng-web-c. Ranges use SOURCE coordinates; the chapter column uses APP coordinates. Word boundaries are whitespace-separated words, with punctuation retained. Verse counts count non-empty rendered entries, not the highest verse label.',
      'All earlier Esther **needs review** flags remain until the user confirms the boundaries. High-confidence literal spans can be displayed while that flag remains in this document and the mapping. Uncertain chapters are **text pending**, with no app Scripture text fabricated.',
      'Reader policy now follows the app language without fallback. Tagalog is unavailable for Esther 10-16, Daniel 3/13/14 and the seven absent books; users may switch the app to English in Settings. Earlier fallback approval is superseded.', '',
      '| App chapter | Source ranges used | Rendered verses | First 12 English words | Last 12 English words | Status |',
      '|---|---|---:|---|---|---|']
    for book,ch in REQUESTED:
      rule=mapping['translations']['web']['books'].get(book,{})
      if ch in rule.get('pending_chapters',[]):
        lines.append(f'| {names[book]} {ch} | None assigned; candidate ESG 5:1–14 (app 5) / ESG 4:8 + 5:1–2 (app 15) | 0 | — no app text | — no app text | **needs review; text pending** |')
        continue
      verses=mapped_chapter(books,mapping,'web',book,ch)
      words=' '.join(v['t'] for v in verses).split()
      segments=rule.get('chapters',{}).get(str(ch))
      grouped={}
      for s in segments or []:
        key=f"{s['source_book']} {s['source_chapter']}:{s['source_verses'][0]}–{s['source_verses'][1]}"
        span='text_start' in s or 'text_end' in s
        n,old_span=grouped.get(key,(0,False));grouped[key]=(n+1,old_span or span)
      source='; '.join(k+(f' ({n} literal span'+('s)' if n>1 else ')') if span else '') for k,(n,span) in grouped.items()) if segments else f'{book} {ch}:1–{verses[-1]["v"]}'
      flag='**needs review (retained)**; high-confidence literal spans' if ch in rule.get('review_required_chapters',[]) else 'verified against source'
      lines.append(f"| {names[book]} {ch} | {source} | {len(verses)} | {' '.join(words[:12])} | {' '.join(words[-12:])} | {flag} |")
    lines+=['','## Exact Esther split evidence','',
      'The exact inclusive start / exclusive end anchors are committed in `tools/bible_mapping.json`. The Python reference and Dart repository both reject missing, repeated or reversed anchors rather than guessing offsets. Edition square brackets around additions are excluded by explicit span endpoints; no source words are corrected or paraphrased.',
      'Esther 10 is source 10:1–13; source 10:14 (Dositheus colophon) moves to app 11:1. Source 1:1 is divided into the dream (11:2–12), conspiracy (12:1–6), and main narrative (1:1). Source 3:13 supplies the hostile letter (13:1–7) and main narrative (3:13); source 4:18–28 is 13:8–18. Source 4:29–47 is 14:1–19. Source 8:13 supplies the protective letter (16:1–24) and main narrative (8:13).',
      'Numbering references only (their wording is NOT bundled): [Esther 11](https://ebible.org/engDRA/EST11.htm), [12](https://ebible.org/engDRA/EST12.htm), [13](https://ebible.org/engDRA/EST13.htm), [14](https://ebible.org/engDRA/EST14.htm), [15](https://ebible.org/engDRA/EST15.htm), [16](https://ebible.org/engDRA/EST16.htm).','',
      '## Text-pending chapters — needs review','',
      'WEB Esther 5 and 15 stay pending. The expanded audience in source 5:1–2 overlaps the main narrative. App 15 also repeats Mordecai’s instructions from source 4:8. There is no second, separate Hebrew-form English 5:1–2 in this pinned source. A complete non-duplicating assignment cannot be asserted confidently without further review. Do not substitute Douay-Rheims, paraphrase WEB, silently omit those words, or duplicate the whole audience.',
      'For audit only, the candidate ranges below are NOT displayed as app text:','',
      '| Candidate only | Source verse entries | First 12 source words | Last 12 source words |',
      '|---|---:|---|---|']
    for ch,selected in [(5,books['est']['chapters']['5']),(15,[v for v in books['est']['chapters']['4'] if v['v']==8]+books['est']['chapters']['5'][:2])]:
      words=' '.join(v['t'] for v in selected).split()
      lines.append(f"| Esther {ch} candidate — needs review | {len(selected)} | {' '.join(words[:12])} | {' '.join(words[-12:])} |")
    lines+=['','The reader treats text pending separately from a loading failure. Its quiz / no-question mark action stays available, and merely opening the chapter never changes progress.','']
    (TOOLS/'boundary_review.md').write_text('\n'.join(lines),encoding='utf8',newline='\n')

if __name__=='__main__':main()
