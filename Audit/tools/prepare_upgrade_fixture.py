#!/usr/bin/env python3
"""Reconstruct the recorded CLMM v14 sources using public, hash-checked inputs."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
repo = Path(__file__).resolve().parents[2]
fixture = repo / 'Audit/fixtures/clmm_v14'
m = json.loads((fixture / 'manifest.json').read_text())
out = a.output.resolve()
assert Path('/tmp') in out.parents, 'Fresh temporary fixture directory required'
patch = fixture / 'historical-sources.patch'
assert hashlib.sha256(patch.read_bytes()).hexdigest() == m['patch_sha256']
out.mkdir(parents=True, exist_ok=False)
for rel in m['historical_source_sha256']:
    target = out / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(subprocess.check_output(
        ['git', 'show', m['public_source_base'] + ':' + m['public_package'] + '/' + rel], cwd=repo))
subprocess.run(['patch', '-p1', '--batch', '--forward', '-i', str(patch)], cwd=out, check=True)
for rel, expected in m['historical_source_sha256'].items():
    assert hashlib.sha256((out / rel).read_bytes()).hexdigest() == expected, rel
for name, expected in m['normalized_metadata_sha256'].items():
    data = (fixture / name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == expected, name
    (out / name).write_bytes(data)
(out / 'rehearsal-inputs.json').write_text(json.dumps(m, indent=2) + '\n')
print(out)
