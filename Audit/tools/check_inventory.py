#!/usr/bin/env python3
"""Conservative lexical inventory, NOT a Move parser, call graph or coverage proof."""
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'Audit'


def blank_noncode(text):
    # Preserve offsets/newlines while removing strings and nested comments.
    result = list(text); i = 0
    while i < len(text):
        start = i
        if text.startswith('//', i):
            end = text.find('\n', i); i = len(text) if end < 0 else end
        elif text.startswith('/*', i):
            depth = 1; i += 2
            while i < len(text) and depth:
                if text.startswith('/*', i): depth += 1; i += 2
                elif text.startswith('*/', i): depth -= 1; i += 2
                else: i += 1
        elif text[i] == '"':
            i += 1
            while i < len(text):
                if text[i] == '\\': i += 2
                elif text[i] == '"': i += 1; break
                else: i += 1
        else:
            i += 1; continue
        for k in range(start, i):
            if result[k] != '\n': result[k] = ' '
    return ''.join(result)


def functions(path):
    text = path.read_text(); clean = blank_noncode(text)
    modules = list(re.finditer(r'\bmodule\s+([\w:]+)', clean))
    if not modules: return []
    records = []; previous_end = modules[0].end()
    for match in re.finditer(r'\bfun\s+(\w+)\b', clean):
        module = next(m for m in reversed(modules) if m.start() < match.start())
        module_prefix = clean[max(clean.rfind('}', 0, module.start()), clean.rfind(';', 0, module.start()))+1:module.start()]
        module_test = '#[test_only]' in module_prefix
        start = clean.find('{', match.end()); semi = clean.find(';', match.end())
        if start < 0 or (semi >= 0 and semi < start): continue
        depth = 1; end = start + 1
        while depth and end < len(clean):
            if clean[end] == '{': depth += 1
            elif clean[end] == '}': depth -= 1
            end += 1
        assert depth == 0, (path, match[1])
        prefix = clean[previous_end:match.start()]
        # Only adjacent attributes/modifiers belong to this function.
        attrs = re.search(r'((?:#\[[^\]]*\]\s*)*)(?:(?:public(?:\([^)]*\))?|entry|macro|native)\s+)*$', prefix)
        attributes = attrs[1] if attrs else ''
        signature = clean[match.start():start]
        records.append({'name': match[1], 'module': module[1], 'line': text.count('\n', 0, match.start()) + 1,
                        'start': start, 'end': end, 'attributes': attributes,
                        'test': bool(re.search(r'#\[\s*test\s*(?:\(|,|\])', attributes)),
                        'test_only': module_test or '#[test_only]' in attributes,
                        'signature': signature, 'body': clean[start:end], 'text': text,
                        'path': path.relative_to(ROOT).as_posix()})
        previous_end = end
    return records


paths = sorted(p for p in ROOT.glob('packages/cetus_clmm/**/*.move')
               if p.relative_to(ROOT).parts[2] in ('sources', 'tests') and 'build' not in p.parts)
records = [f for p in paths for f in functions(p)]
tests = []
for f in records:
    if f['test']:
        expected = re.search(r'expected_failure(?:\((.*?)\))?(?=\s*,?\s*\])', f['attributes'], re.S)
        tests.append({'test': f['module'] + '::' + f['name'], 'file': f['path'], 'line': f['line'],
                      'expected_failure': ' '.join(expected[1].split()) if expected and expected[1] else ('any failure' if expected else '')})
rows = []
for f in records:
    if f['test'] or f['test_only'] or f['path'].split('/')[2] != 'sources': continue
    module = f['module'].split('::')[-1]
    def add(kind, offset, expression):
        errors = set(re.findall(r'\bE[A-Z_a-z0-9]+\b', expression))
        candidates = [t['test'] for t in tests if t['file'].split('/')[1] == f['path'].split('/')[1]
                      and any(re.search(r'\b'+re.escape(module)+r'::'+re.escape(e)+r'\b', t['expected_failure']) for e in errors)]
        rows.append({'package': f['path'].split('/')[1], 'file': f['path'],
                     'line': f['text'].count('\n', 0, offset) + 1, 'function': f['module']+'::'+f['name'],
                     'kind': kind, 'check': ' '.join(expression.split()),
                     'negative_test_candidates': '; '.join(candidates), 'review_status': 'unreviewed'})
    for match in re.finditer(r'\bassert(?:_eq)?!\s*\(', f['body']):
        begin = match.start(); cursor = match.end(); depth = 1
        while depth and cursor < len(f['body']):
            if f['body'][cursor] == '(': depth += 1
            elif f['body'][cursor] == ')': depth -= 1
            cursor += 1
        add('assertion', f['start']+begin, f['body'][begin:cursor])
    if re.search(r'\b\w*Cap\b', f['signature']):
        add('capability signature', f['start'], f['signature'])
    for match in re.finditer(r'\b(?:\w+::)?(?:checked_\w+|check_\w+|assert_authorized|validate_\w+)\s*(?:<[^;{}]*?>)?\s*\(', f['body']):
        add('guard call candidate', f['start']+match.start(), f['body'][match.start():f['body'].find('\n',match.start()) if '\n' in f['body'][match.start():] else len(f['body'])])

fields = ['package','file','line','function','kind','check','negative_test_candidates','review_status']
with (OUT/'check-inventory.csv').open('w', newline='') as out:
    writer = csv.DictWriter(out, fieldnames=fields, lineterminator='\n'); writer.writeheader(); writer.writerows(rows)
(OUT/'test-index.json').write_text(json.dumps(tests,indent=2)+'\n')
summary = {'method': __doc__, 'source_sha256': {p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
           'tests': len(tests), 'check_rows': len(rows), 'by_package': {}}
for package in sorted({r['package'] for r in rows}):
    subset = [r for r in rows if r['package']==package]
    summary['by_package'][package] = {kind:sum(r['kind']==kind for r in subset) for kind in ['assertion','capability signature','guard call candidate']}
(OUT/'check-inventory-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'tests':len(tests),'check_rows':len(rows),'by_package':summary['by_package']},indent=2))
