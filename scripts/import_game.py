#!/usr/bin/env python3
"""Import a fingerprinted local BVN package without writing to its source."""
import argparse, hashlib, json, shutil
from pathlib import Path
import xml.etree.ElementTree as ET

LAUNCH_SHA256 = '2c565d9693eba6ee4ae4e691cbc8f9783e60fbe15a1d589afbe0a1988dddc8cb'
APP_ID = 'local.bvn.macos.compat'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def import_game(source, destination, include_save=False):
    source, destination = Path(source).resolve(), Path(destination).resolve()
    if destination == source or source in destination.parents or destination in source.parents:
        raise ValueError('Source and destination must be separate, non-nested directories')
    if destination.exists():
        raise ValueError('Destination already exists; choose a fresh directory')
    if sha(source / 'launch.f') != LAUNCH_SHA256:
        raise ValueError('Unsupported launch.f fingerprint; no files copied')
    candidates = [source / 'launch.f', source / 'META-INF/AIR/application.xml']
    candidates += sorted((source / 'assetss').rglob('*'))
    if include_save:
        candidates += [source / 'bvnsave.sav']
    files = [p for p in candidates if p.is_file() and p.name != '.DS_Store']
    if any(p.is_symlink() or source not in p.resolve().parents for p in candidates):
        raise ValueError('Symlink or escaping source resource rejected')
    before = {str(p.relative_to(source)): sha(p) for p in files}
    destination.mkdir(parents=True)
    for p in files:
        target = destination / p.relative_to(source)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, target)
        if sha(target) != before[str(p.relative_to(source))]:
            raise RuntimeError('Copied file failed verification: ' + str(target))
    descriptor = destination / 'META-INF/AIR/application.xml'
    text = descriptor.read_text(encoding='utf-8-sig')
    ns = {'a': 'http://ns.adobe.com/air/application/32.0'}
    original_id = ET.fromstring(text).find('a:id', ns).text
    # Preserve all descriptor formatting and fields except the storage identity.
    text = text.replace('<id>' + original_id + '</id>', '<id>' + APP_ID + '</id>', 1)
    (destination / 'application-macos.xml').write_text(text, encoding='utf-8')
    after = {str(p.relative_to(source)): sha(p) for p in files}
    if before != after:
        raise RuntimeError('Source changed during import; do not run this candidate')
    report = {'launch_sha256': LAUNCH_SHA256, 'files': before, 'application_id': APP_ID,
              'original_application_id': original_id, 'source_unchanged': True,
              'save_copied': include_save, 'runtime_storage_verified': False,
              'static_save_path': 'File.applicationDirectory/bvnsave.sav'}
    (destination / 'import-report.json').write_text(json.dumps(report, indent=2))
    return report

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('source'); p.add_argument('destination')
    p.add_argument('--include-save', action='store_true', help='Copy the local save into this private test import')
    a = p.parse_args()
    try:
        r = import_game(a.source, a.destination, a.include_save)
    except (ValueError, OSError, RuntimeError) as e:
        p.exit(1, str(e) + '\n')
    print(json.dumps({k:v for k,v in r.items() if k != 'files'}, indent=2))
