#!/usr/bin/env python3
"""Validate reviewed witnesses; retain ALL remaining lexical checks as unreviewed.

This is an evidence validator, not a parser or an automatic security review.
"""
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
A = ROOT / 'Audit'
checks = list(csv.DictReader((A / 'check-inventory.csv').open()))
tests = {t['test']: t for t in json.loads((A / 'test-index.json').read_text())}
review = json.loads((A / 'positive-negative-reviewed.json').read_text())
covered = set()
for item in review:
    source = ROOT / item['file']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == item['source_sha256'], item['function'] + ': stale source'
    for polarity in ['positive', 'negative']:
        assert item[polarity], item['function']
        for name in item[polarity]:
            assert name in tests, name
            t = tests[name]
            assert bool(t['expected_failure']) == (polarity == 'negative'), name
            assert hashlib.sha256((ROOT / t['file']).read_bytes()).hexdigest() == item['test_sha256'][t['file']], name + ': stale test'
    matched = [i for i,c in enumerate(checks) if c['file'] == item['file'] and c['function'] == item['function'] and c['check'] == item['check']]
    assert len(matched) == 1, (item['function'], item['check'])
    assert matched[0] not in covered, 'duplicate review'
    covered.add(matched[0])
rows=[]
for i,c in enumerate(checks):
    rows.append(dict(c, review_status='paired entry witnesses reviewed' if i in covered else 'unreviewed'))
with (A/'positive-negative-status.csv').open('w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=rows[0].keys(), lineterminator='\n');writer.writeheader();writer.writerows(rows)
summary={'method':'Lexical sites with manually reviewed, fingerprint-bound entry witnesses. Not a complete semantic invariant inventory.',
         'lexical_check_sites':len(checks),'paired_sites':len(covered),'unreviewed_sites':len(checks)-len(covered),
         'requirement_complete':False,
         'limits':['Unreviewed is not equivalent to missing tests.','Capability input ownership requires transaction/compiler evidence.','Business invariants beyond explicit assertions still require enumeration.','Scope is CLMM only; dependencies and integrations require separate evidence.']}
(A/'positive-negative-status.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
