"""Guard against overwrites, unverified payloads, and silent seed omission."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import build_macos as builder
from import_game import APP_ID, sha

class BuildSafety(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.game = self.root / 'game'
        (self.game / 'assetss').mkdir(parents=True)
        (self.game / 'launch.f').write_bytes(b'test entry, not game code')
        (self.game / 'assetss/sample').write_bytes(b'test asset')
        self.files = {n: sha(self.game / n) for n in ('launch.f', 'assetss/sample')}
        self.report = dict(application_id=APP_ID, source_unchanged=True, files=self.files)
        self.write_report()
        self.addCleanup(patch.stopall)
        patch.object(builder, 'LAUNCH_SHA256', self.files['launch.f']).start()

    def write_report(self):
        (self.game / 'import-report.json').write_text(json.dumps(self.report))

    def test_changed_resource_rejected(self):
        (self.game / 'assetss/sample').write_bytes(b'changed')
        with self.assertRaises(ValueError): builder.checked_payload(self.game)

    def test_linked_resource_rejected(self):
        target = self.game / 'assetss/sample'
        target.unlink()
        outside = self.root / 'outside'
        outside.write_bytes(b'test asset')
        target.symlink_to(outside)
        with self.assertRaises(ValueError): builder.checked_payload(self.game)

    def test_shared_application_identity_rejected(self):
        self.report['application_id'] = 'original.identity'
        self.write_report()
        with self.assertRaises(ValueError): builder.checked_payload(self.game)

    def test_only_verified_game_payload_is_selected(self):
        (self.game / 'private.sav').write_text('private')
        self.assertEqual(builder.checked_payload(self.game), self.files)

    def build(self, **overrides):
        args = dict(sdk=self.root/'sdk', game=self.game,
                    output=self.root/'out.app', scratch=self.root/'scratch')
        args.update(overrides)
        with patch.object(builder.subprocess, 'run') as execute:
            with self.assertRaises(ValueError): builder.build(**args)
            execute.assert_not_called()

    def test_nested_output_and_scratch_rejected(self):
        self.build(output=self.root/'scratch/out.app')
        self.assertFalse((self.root/'scratch').exists())

    def test_explicit_missing_seed_is_not_silently_omitted(self):
        self.build(seed_path=self.root/'missing.sav')
        self.assertFalse((self.root/'scratch').exists())

    def test_invalid_seed_precedes_any_build_writes(self):
        seed=self.root/'bad.sav';seed.write_text('[]')
        self.build(seed_path=seed)
        self.assertFalse((self.root/'scratch').exists())

    def test_existing_output_preserved(self):
        output=self.root/'out.app';output.mkdir()
        marker=output/'keep';marker.write_text('untouched')
        self.build(output=output)
        self.assertEqual(marker.read_text(),'untouched')

    def test_application_id_cannot_escape_storage_directory(self):
        self.build(app_id='local.bvn.macos.x/../../other')

if __name__ == '__main__': unittest.main()
