#!/usr/bin/env python3
"""Execute AdminCap ownership controls on a disposable, loopback-only Sui network.

Uses published production objects, explicit sender-owned gas and signed execution;
never dev-inspect, dry-run, skip-signing or test_scenario ownership impersonation.
The local AdminCap is transferred to a second genesis account by this probe.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from urllib.parse import urlparse


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--sui', default='sui')
    p.add_argument('--client-config', required=True)
    p.add_argument('--env', required=True)
    p.add_argument('--publication', required=True, type=Path)
    p.add_argument('--kind', choices=['clmm', 'dlmm'], required=True)
    p.add_argument('--output', required=True, type=Path)
    args = p.parse_args()
    base = [args.sui, 'client', '--client.config', args.client_config,
            '--client.env', args.env, '--json']

    def run(words):
        return subprocess.run(base + words, capture_output=True, text=True, timeout=120)

    def query(words):
        r = run(words)
        assert r.returncode == 0, r.stdout + r.stderr
        return json.loads(r.stdout)

    envs = query(['envs'])[0]
    rpc = next(e['rpc'] for e in envs if e['alias'] == args.env)
    assert urlparse(rpc).hostname in ['127.0.0.1', 'localhost', '::1'], 'Localnet only'
    pub = json.loads(args.publication.read_text())
    assert pub['effects']['status']['status'] == 'success'
    objects = pub['objectChanges']
    cap_type = '::config::AdminCap' if args.kind == 'clmm' else '::admin_cap::AdminCap'
    cap_obj = next(o for o in objects if o.get('objectType', '').endswith(cap_type))
    cap = cap_obj['objectId']
    package = cap_obj['objectType'].split('::')[0]
    config = next(o['objectId'] for o in objects if o.get('objectType', '').endswith('::config::GlobalConfig'))
    version = next((o['objectId'] for o in objects if o.get('objectType', '').endswith('::versioned::Versioned')), None)
    owner = cap_obj['owner']['AddressOwner']
    addresses = query(['addresses'])['addresses']
    other = next(a[1] for a in addresses if a[1] != owner)
    assert query(['object', cap])['owner'] == {'AddressOwner': owner}, 'Use a fresh publication'
    gas = {a: query(['gas', a])['gasCoins'][0]['gasCoinId'] for a in [owner, other]}
    out = args.output
    out.mkdir(parents=True, exist_ok=True)
    summary = {'kind': args.kind, 'chain': query(['chain-identifier']), 'rpc': rpc,
               'toolchain': subprocess.check_output([args.sui, '--version'], text=True).strip(),
               'publication_digest': pub['digest'], 'package': package, 'capability': cap,
               'owner': owner, 'other': other, 'cases': [],
               'limits': 'AdminCap and config::set_roles only. Local relocated production publication, not mainnet state or every capability/entry. Does not cover shared/frozen/wrapped capabilities, multisig custody or upgrade replay.'}

    def snapshot():
        return {name: query(['object', oid]) for name, oid in [('cap', cap), ('config', config)]}

    def attempt(label, sender, roles, expect_success):
        before = snapshot()
        call_args = [cap, config, other, str(roles)] if args.kind == 'clmm' else [config, cap, other, str(roles), version]
        cmd = ['call', '--package', package, '--module', 'config', '--function', 'set_roles',
               '--args', *call_args, '--sender', sender, '--gas', gas[sender], '--gas-budget', '10000000']
        r = run(cmd)
        after = snapshot()
        record = {'label': label, 'sender': sender, 'command': cmd, 'exit_code': r.returncode,
                  'before': before, 'after': after}
        if expect_success:
            assert r.returncode == 0, r.stdout + r.stderr
            tx = json.loads(r.stdout)
            assert tx['effects']['status']['status'] == 'success', tx
            assert after['config']['version'] > before['config']['version']
            record['transaction'] = tx
        else:
            text = r.stdout + r.stderr
            assert r.returncode != 0 and 'Transaction was not signed by the correct sender' in text, text
            assert cap in text and sender in text, text
            assert before == after, 'Rejected transaction mutated protected state'
            record['rejection'] = text
        (out / (label + '.json')).write_text(json.dumps(record, indent=2) + '\n')
        summary['cases'].append({'case': label, 'expected_result_observed': True})

    attempt('owner-accepted', owner, 1, True)
    attempt('nonowner-rejected', other, 2, False)
    tx = query(['transfer', '--to', other, '--object-id', cap, '--sender', owner,
                '--gas', gas[owner], '--gas-budget', '10000000'])
    assert tx['effects']['status']['status'] == 'success'
    assert query(['object', cap])['owner'] == {'AddressOwner': other}
    (out / 'transfer.json').write_text(json.dumps(tx, indent=2) + '\n')
    attempt('former-owner-rejected', owner, 4, False)
    attempt('new-owner-accepted', other, 8, True)
    summary['sha256'] = {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in out.glob('*.json') if f.name != 'summary.json'}
    (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(args.kind + ': four signed ownership controls passed; transfer confirmed')


if __name__ == '__main__':
    main()
