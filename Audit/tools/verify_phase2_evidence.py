#!/usr/bin/env python3
"""Check CLMM Phase 2 publication integrity and source/test binding."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]

def verify(rel, expected):
    assert hashlib.sha256((root / rel).read_bytes()).hexdigest() == expected, rel

provenance = json.loads((root / 'Audit/phase2-sync-provenance.json').read_text())
for group in ['imported_evidence_sha256', 'public_adapter_sha256']:
    for rel, expected in provenance[group].items():
        verify(rel, expected)
witnesses = json.loads((root / 'Audit/phase2-recovery-witnesses.json').read_text())
verify(witnesses['test_file'], witnesses['test_sha256'])
tests = (root / witnesses['test_file']).read_text()
for entry in witnesses['entries']:
    verify(entry['source'], entry['source_sha256'])
    for name in entry['witnesses']:
        assert 'fun ' + name + '(' in tests, name
inputs = json.loads((root / 'Audit/evidence/phase2/clmm-upgrade/inputs.json').read_text())
for rel, expected in inputs['current_source_sha256'].items():
    verify('packages/cetus_clmm/sources/' + rel, expected)
for summary in (root / 'Audit/evidence/phase2').glob('clmm-*/summary.json'):
    record = json.loads(summary.read_text())
    for rel, expected in record.get('sha256', {}).items():
        verify((summary.parent / rel).relative_to(root).as_posix(), expected)
print('CLMM Phase 2 receipts, public adapters, current sources and entry witnesses verified.')

public = json.loads((root / 'Audit/evidence/phase2/public-clmm-ci/summary.json').read_text())
for rel, expected in public['sha256'].items():
    verify('Audit/evidence/phase2/public-clmm-ci/' + rel, expected)
for name, expected in public['build_input_sha256'].items():
    verify('packages/cetus_clmm/' + name, expected)
print('Public CI snapshot and unchanged build inputs verified.')
