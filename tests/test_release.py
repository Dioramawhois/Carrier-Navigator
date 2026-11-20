# SPDX-License-Identifier: GPL-3.0-or-later
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('release', Path(__file__).resolve().parents[1] / 'tools/release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def test_beta_publication_requires_explicit_authorization_and_keeps_validation_truthful(self):
        with tempfile.TemporaryDirectory() as directory:
            root,candidate,receipt,acceptance=self.fixture(directory)
            acceptance.update(schema=2,kind='owner-authorized-beta',publication_authorized=True,game_runtime_tested=False)
            with self.assertRaises(ValueError):release.validate_payload(root,candidate,receipt,acceptance)
            release.validate_payload(root,candidate,receipt,acceptance,authorized_beta=True)
            acceptance['publication_authorized']=False
            with self.assertRaises(ValueError):release.validate_payload(root,candidate,receipt,acceptance,authorized_beta=True)

    def fixture(self, directory):
        root, candidate = Path(directory) / 'source', Path(directory) / 'candidate'
        files = {name: b'owned' for name in release.STEAM_FILES}
        files['content/bridge.json'] = b'{"id":"carrier_navigator","scripts":["bridge/main.lua"]}'
        receipt = {'source_commit': 'accepted', 'sdk_sha256': 'runtime', 'files': {}}
        for name, data in files.items():
            for base in (root, candidate / 'Carrier Navigator'):
                target = base / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            receipt['files']['Carrier Navigator/' + name] = release.sha(data)
        acceptance = {'game_runtime_tested': True, 'candidate_source_commit': 'accepted',
            'runtime_sha256': 'runtime', 'functional_sha256': {
                name: release.sha(files[name]) for name in release.RUNTIME_FILES}}
        return root, candidate, receipt, acceptance

    def test_steam_payload_excludes_developer_material_but_keeps_license(self):
        with tempfile.TemporaryDirectory() as directory:
            root, candidate, receipt, acceptance = self.fixture(directory)
            (root / 'tests').mkdir()
            (root / 'tests/private.lua').write_text('fixture')
            files = release.validate_payload(root, candidate, receipt, acceptance)
            self.assertEqual(len(files), 8)
            self.assertIn('LICENSE', files)
            self.assertFalse(any(name.startswith('tests/') for name in files))

    def test_unexpected_test_or_native_file_in_content_rejects_packaging(self):
        for name in ('tests/fixture.lua', 'bridge/observer.lua', 'loader.dll'):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                root, candidate, receipt, acceptance = self.fixture(directory)
                target = root / 'content' / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(b'unwanted')
                with self.assertRaises(ValueError):
                    release.validate_payload(root, candidate, receipt, acceptance)

    def test_changed_gameplay_or_wrong_acceptance_is_rejected(self):
        for change in ('source', 'candidate', 'acceptance', 'runtime'):
            with self.subTest(change=change), tempfile.TemporaryDirectory() as directory:
                root, candidate, receipt, acceptance = self.fixture(directory)
                if change == 'source':
                    (root / 'content/bridge/main.lua').write_bytes(b'changed')
                elif change == 'candidate':
                    (candidate / 'Carrier Navigator/content/bridge/main.lua').write_bytes(b'changed')
                elif change == 'acceptance':
                    acceptance['game_runtime_tested'] = False
                else:
                    acceptance['runtime_sha256'] = 'wrong'
                with self.assertRaises(ValueError):
                    release.validate_payload(root, candidate, receipt, acceptance)

    def test_only_the_three_exact_title_literals_can_differ(self):
        with tempfile.TemporaryDirectory() as directory:
            root, candidate, receipt, acceptance = self.fixture(directory)
            for name, changes in release.BRANDING_REPLACEMENTS.items():
                original = b'\n'.join(before for before, _ in changes)
                (candidate / 'Carrier Navigator' / name).write_bytes(original)
                (root / name).write_bytes(release.branded_candidate(name, original))
                receipt['files']['Carrier Navigator/' + name] = release.sha(original)
                acceptance['functional_sha256'][name] = release.sha(original)
            release.validate_payload(root, candidate, receipt, acceptance)
            path = root / 'content/bridge/main.lua'
            path.write_bytes(path.read_bytes() + b'\ncc2.carrier.drive_motion(1,1,1)')
            with self.assertRaises(ValueError):
                release.validate_payload(root, candidate, receipt, acceptance)

    def test_title_replacement_requires_one_exact_old_literal(self):
        name = 'content/scripts/library_custom_0.lua'
        for original in (b'unknown', b"'CARRIER NAVIGATOR' 'CARRIER NAVIGATOR'"):
            with self.subTest(original=original), self.assertRaises(ValueError):
                release.branded_candidate(name, original)

    def test_source_archive_rejects_secrets_native_files_and_traversal(self):
        required = {'tools/release.py', 'tests/runtime.lua', 'tests/ui.lua', 'README.md', 'LICENSE', *release.RUNTIME_FILES}
        files = {'Carrier-Navigator-source/' + name: b'owned' for name in required}
        release.validate_source_archive(release.zip_files(files))
        for name in ('Carrier-Navigator-source/build/private.json',
                     'Carrier-Navigator-source/research/decomp.c',
                     'Carrier-Navigator-source/loader.dll', '../private'):
            with self.subTest(name=name):
                output = io.BytesIO()
                with zipfile.ZipFile(output, 'w') as archive:
                    for key, value in {**files, name: b'unwanted'}.items():
                        archive.writestr(key, value)
                with self.assertRaises(ValueError):
                    release.validate_source_archive(output.getvalue())


if __name__ == '__main__':
    unittest.main()
