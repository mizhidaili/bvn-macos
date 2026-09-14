import json, sys, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import import_game
import run_adl

class ImportSafety(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.src = self.root/'source'; self.src.mkdir()
        (self.src/'launch.f').write_bytes(b'test fixture, never executable')
        (self.src/'assetss').mkdir(); (self.src/'assetss/data.f').write_bytes(b'resource')
        d=self.src/'META-INF/AIR';d.mkdir(parents=True)
        (d/'application.xml').write_text('<application xmlns="http://ns.adobe.com/air/application/32.0"><id>original.game</id></application>')
        (self.src/'bvnsave.sav').write_text('{"private":true}')
        self.fingerprint=import_game.sha(self.src/'launch.f')
    def tearDown(self): self.tmp.cleanup()
    def test_unsupported_source_is_not_copied(self):
        dst=self.root/'out'
        with self.assertRaises(ValueError): import_game.import_game(self.src,dst)
        self.assertFalse(dst.exists())
    def test_isolated_import_preserves_source_and_excludes_save(self):
        before={str(p.relative_to(self.src)):p.read_bytes() for p in self.src.rglob('*') if p.is_file()}
        dst=self.root/'out'
        with patch.object(import_game,'LAUNCH_SHA256',self.fingerprint): r=import_game.import_game(self.src,dst)
        after={str(p.relative_to(self.src)):p.read_bytes() for p in self.src.rglob('*') if p.is_file()}
        self.assertEqual(before,after)
        self.assertFalse((dst/'bvnsave.sav').exists())
        self.assertIn(import_game.APP_ID,(dst/'application-macos.xml').read_text())
        self.assertFalse(r['runtime_storage_verified'])
    def test_nested_destination_refused(self):
        with self.assertRaises(ValueError): import_game.import_game(self.src,self.src/'child')
    def test_symlink_resource_refused(self):
        (self.src/'assetss/private').symlink_to(self.src/'bvnsave.sav')
        with patch.object(import_game,'LAUNCH_SHA256',self.fingerprint):
            with self.assertRaises(ValueError): import_game.import_game(self.src,self.root/'out')
    def test_launcher_refuses_original_application_id_before_runtime(self):
        dst=self.root/'out'
        with patch.object(import_game,'LAUNCH_SHA256',self.fingerprint): import_game.import_game(self.src,dst)
        (dst/'application-macos.xml').write_text((dst/'META-INF/AIR/application.xml').read_text())
        with self.assertRaisesRegex(ValueError,'application ID'):
            run_adl.prepare(self.root/'sdk',dst,self.root/'evidence')

if __name__ == '__main__': unittest.main()
