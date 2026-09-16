"""Negative controls run in disposable repositories, never the Flick Git index."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SOURCE_ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('governance', SOURCE_ROOT / 'scripts/governance.py')
governance = importlib.util.module_from_spec(spec)
spec.loader.exec_module(governance)


class GovernanceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='flick-governance-test-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        for name in governance.inventory():
            destination = self.root / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(SOURCE_ROOT / name, destination)
        self.git('init', '-q')
        self.git('add', 'README.md')
        self.git('-c', 'user.name=progentic', '-c', 'user.email=progentic@users.noreply.github.com',
                 'commit', '-qm', 'chore(test): Create disposable comparison base')
        self.root_patch = patch.object(governance, 'ROOT', self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.policy = json.loads((self.root / '.repo-policy.json').read_text())

    def test_matching_baseline_passes(self):
        governance.establish_root()
        governance.check_metadata()
        governance.check_packages(self.policy)
        governance.check_workflows()
        governance.write_inventory()
        governance.check_inventory()

    def test_missing_base_is_inconclusive(self):
        with self.assertRaises(governance.Inconclusive):
            governance.changed_paths('missing-ref')

    def test_wrong_source_revision_fails(self):
        with self.assertRaises(AssertionError):
            governance.changed_paths('HEAD', 'f' * 40)

    def test_dirty_tree_cannot_claim_exact_source(self):
        head = self.git('rev-parse', 'HEAD').strip()
        with self.assertRaises(AssertionError):
            governance.changed_paths('HEAD', head)

    def test_changes_include_deletion_and_untracked_spaced_filename(self):
        (self.root / 'README.md').unlink()
        (self.root / 'new file.txt').write_text('new\n')
        changed = governance.changed_paths('HEAD')
        self.assertIn('README.md', changed)
        self.assertIn('new file.txt', changed)

    def test_staged_change_is_detected(self):
        (self.root / 'README.md').write_text('modified\n')
        self.git('add', 'README.md')
        self.assertIn('README.md', governance.changed_paths('HEAD'))

    def test_missing_package_fails(self):
        (self.root / 'Packages/CEIngestion/Package.swift').unlink()
        with self.assertRaises(AssertionError):
            governance.check_packages(self.policy)

    def test_sibling_import_fails(self):
        path = self.root / 'Packages/CEIngestion/Sources/CEIngestion/Module.swift'
        path.write_text('import CEStorage\n')
        with self.assertRaises(AssertionError):
            governance.check_packages(self.policy)

    def test_cycle_fails(self):
        with self.assertRaises(AssertionError):
            governance.visit_dependencies({'A': ['B'], 'B': ['A']})

    def test_mutable_action_pin_fails(self):
        path = self.root / '.github/workflows/packages.yml'
        path.write_text(path.read_text().replace('d23441a48e516b6c34aea4fa41551a30e30af803', 'v6'))
        with self.assertRaises(AssertionError):
            governance.check_workflows()

    def test_license_change_fails(self):
        path = self.root / 'LICENSE'
        path.write_text(path.read_text().replace('Proto', 'Different Holder'))
        with self.assertRaises(AssertionError):
            governance.check_metadata()

    def test_stale_inventory_fails(self):
        governance.write_inventory()
        (self.root / 'unlisted.txt').write_text('new\n')
        with self.assertRaises(AssertionError):
            governance.check_inventory()

    def test_no_ui_is_not_applicable_but_new_ui_needs_evidence(self):
        governance.check_ui()
        (self.root / 'Packages/CEUI/Sources/CEUI/Module.swift').write_text('import SwiftUI\n')
        with self.assertRaises(governance.Inconclusive):
            governance.check_ui()

    def git(self, *arguments):
        return subprocess.run(['git', *arguments], cwd=self.root, check=True,
                              capture_output=True, text=True).stdout


if __name__ == '__main__':
    unittest.main()
