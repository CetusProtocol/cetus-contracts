"""The ledger must reject stale or misclassified evidence, not silently bless it."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

class EvidenceValidationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.audit = self.root / 'Audit'
        (self.audit / 'tools').mkdir(parents=True)
        self.script = self.audit / 'tools/positive_negative_report.py'
        shutil.copyfile(Path(__file__).with_name('positive_negative_report.py'), self.script)
        for name in ['check-inventory.csv', 'test-index.json', 'positive-negative-reviewed.json']:
            shutil.copyfile(ROOT/'Audit'/name, self.audit/name)
        self.reviews = json.loads((self.audit/'positive-negative-reviewed.json').read_text())
        paths = {r['file'] for r in self.reviews}
        paths.update(f for r in self.reviews for f in r['test_sha256'])
        for f in paths:
            p = self.root/f
            p.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT/f, p)

    def run_report(self):
        return subprocess.run([sys.executable, str(self.script)], capture_output=True, text=True)

    def write_reviews(self):
        (self.audit/'positive-negative-reviewed.json').write_text(json.dumps(self.reviews))

    def test_valid_evidence_remains_incomplete(self):
        result = self.run_report()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(json.loads((self.audit/'positive-negative-status.json').read_text())['requirement_complete'])

    def test_changed_production_source_invalidates_review(self):
        p = self.root/self.reviews[0]['file']
        p.write_text(p.read_text()+'\n// changed source\n')
        result = self.run_report()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('stale source', result.stderr)

    def test_failure_case_cannot_be_positive_witness(self):
        self.reviews[0]['positive'] = self.reviews[0]['negative'][:1]
        self.write_reviews()
        self.assertNotEqual(self.run_report().returncode, 0)

    def test_duplicate_review_cannot_inflate_count(self):
        self.reviews.append(self.reviews[0])
        self.write_reviews()
        result = self.run_report()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('duplicate review', result.stderr)

if __name__ == '__main__':
    unittest.main()
