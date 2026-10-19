#!/usr/bin/env python3
"""Compile valid capability forwarding and reject external construction in an isolated commit snapshot."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
CAPS = {'packages/cetus_clmm': ['cetus_clmm::config::AdminCap', 'cetus_clmm::config::ProtocolFeeClaimCap', 'cetus_clmm::pool::ProtocolFeeCollectCap', 'cetus_clmm::factory::PoolCreationCap', 'cetus_clmm::partner::PartnerCap']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    commit = subprocess.check_output(['git', 'rev-parse', '--verify', args.commit + '^{commit}'], cwd=ROOT, text=True).strip()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    summary = {'tested_commit': commit,
               'toolchain': subprocess.check_output(['sui', '--version'], text=True).strip(),
               'command': 'sui move build --path PACKAGE --build-env mainnet',
               'packages': {},
               'limits': 'Compiler construction visibility only. Does not prove transaction input ownership, capability minting policy, or every guarded entry. ProtocolFeeClaimCap is included although source calls it redundant.'}
    with tempfile.TemporaryDirectory(prefix='cetus-cap-checks-') as temp:
        tree = Path(temp)
        archive = subprocess.run(['git', 'archive', commit], cwd=ROOT, check=True, stdout=subprocess.PIPE).stdout
        subprocess.run(['tar', '-xf', '-', '-C', str(tree)], input=archive, check=True)
        for package, caps in CAPS.items():
            dest = output / package
            dest.mkdir(parents=True, exist_ok=True)
            namespace = caps[0].split('::')[0]
            probe = tree / package / 'sources/capability_compile_probe.move'
            assert not probe.exists(), 'refusing to overwrite a source file'
            record = {'capabilities': caps, 'sha256': {}}
            for mode in ['forward', 'forge']:
                functions = []
                for index, cap in enumerate(caps):
                    if mode == 'forward':
                        functions.append(f'    public fun forward_{index}(cap: {cap}): {cap} {{ cap }}')
                    else:
                        fields = 'id: sui::object::new(ctx)'
                        if cap.endswith('::PoolCreationCap'):
                            fields += ', coin_type: std::type_name::get<u64>()'
                        if cap.endswith('::PartnerCap'):
                            fields += ', name: std::string::utf8(b"probe"), partner_id: sui::object::id_from_address(@0x1)'
                        functions.append(f'    public fun forge_{index}(ctx: &mut sui::tx_context::TxContext): {cap} {{\n        {cap} {{ {fields} }}\n    }}')
                source = f'module {namespace}::capability_compile_probe {{\n' + '\n'.join(functions) + '\n}\n'
                probe.write_text(source)
                result = subprocess.run(['sui', 'move', 'build', '--path', str(tree/package), '--build-env', 'mainnet'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                log = re.sub(r'\x1b\[[0-9;]*m', '', result.stdout)
                (dest/f'{mode}.move').write_text(source)
                (dest/f'{mode}.log').write_text(log)
                if mode == 'forward':
                    assert result.returncode == 0, package + ': forwarding control failed; see log'
                else:
                    assert result.returncode != 0, package + ': forged capabilities compiled'
                    errors = re.findall(r'error\[([^]]+)\]', log)
                    assert len(errors) == len(caps) and set(errors) == {'EC04001'}, (package, errors)
                    for cap in caps:
                        assert f"Struct '{cap}' can only be instantiated within its defining module" in log, cap
                record[mode] = {'exit_code': result.returncode, 'expected_result_observed': True}
                for suffix in ['move', 'log']:
                    name = f'{mode}.{suffix}'
                    record['sha256'][name] = hashlib.sha256((dest/name).read_bytes()).hexdigest()
            probe.unlink()
            summary['packages'][package] = record
            print(package + ': valid forwarding accepted; external construction rejected for ' + str(len(caps)) + ' capabilities', flush=True)
    (output/'provenance.json').write_text(json.dumps(summary, indent=2)+'\n')


if __name__ == '__main__':
    main()
