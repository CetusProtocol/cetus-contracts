#!/usr/bin/env python3
"""Filter Sui LCOV to package sources; retain native denominators and exclusions."""
import argparse
import hashlib
import json
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('package', type=Path)
p.add_argument('lcov', type=Path)
p.add_argument('output', type=Path)
a = p.parse_args()
root = a.package.resolve()
a.output.mkdir(parents=True, exist_ok=True)
kept, files, excluded = [], [], []
for block in a.lcov.read_text().split('end_of_record'):
    lines = block.strip().splitlines()
    source = next((v[3:] for v in lines if v.startswith('SF:')), None)
    if source is None:
        continue
    path = Path(source).resolve()
    if not path.is_relative_to(root / 'sources'):
        excluded.append(source)
        continue
    relative = path.relative_to(root)
    normalized = f'{root.name}/{relative.as_posix()}'
    stats = {}
    for key in ('LF', 'LH', 'BRF', 'BRH'):
        values = [int(v.split(':', 1)[1]) for v in lines if v.startswith(key + ':')]
        if len(values) != 1:
            raise ValueError(f'{source}: missing or duplicate {key}')
        stats[key] = values[0]
    assert 0 <= stats['LH'] <= stats['LF'] and 0 <= stats['BRH'] <= stats['BRF']
    files.append({'source': normalized, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), **stats})
    kept.append('\n'.join('SF:' + normalized if v.startswith('SF:') else v for v in lines) + '\nend_of_record\n')
if not files:
    raise ValueError('No package production sources found in LCOV')
seen = {f['source'] for f in files}
missing = sorted(f'{root.name}/{f.relative_to(root).as_posix()}' for f in (root / 'sources').rglob('*.move') if f'{root.name}/{f.relative_to(root).as_posix()}' not in seen)
totals = {k: sum(f[k] for f in files) for k in ('LF', 'LH', 'BRF', 'BRH')}
report = {'package': root.name, 'metric': 'Sui native trace LCOV, filtered to package sources', 'totals': totals, 'files': files, 'sources_missing_from_lcov': missing, 'excluded_records': len(excluded), 'limits': 'Native mapped executable lines/branches only; not every auth check or invariant. Missing source files are not assigned invented denominators. Inline test-only code in sources may remain.'}
(a.output / 'coverage.lcov').write_text(''.join(kept))
(a.output / 'coverage.json').write_text(json.dumps(report, indent=2) + '\n')
def ratio(hit, total):
    return f'{hit}/{total} ({100 * hit / total:.2f}%)' if total else 'N/A (zero denominator)'
(a.output / 'coverage.md').write_text(f"# {root.name} source coverage\n\nLine: {ratio(totals['LH'],totals['LF'])}\n\nBranch: {ratio(totals['BRH'],totals['BRF'])}\n\nMissing source files: {', '.join(missing) or 'none'}.\n\n{report['limits']}\n")
print((a.output / 'coverage.md').read_text())
