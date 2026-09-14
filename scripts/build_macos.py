#!/usr/bin/env python3
"""Build a self-contained Mac application from a verified local import."""
import argparse
import datetime
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET

from import_game import APP_ID, LAUNCH_SHA256, sha


def checked_payload(game):
    report = json.loads((game / 'import-report.json').read_text())
    if report.get('application_id') != APP_ID or not report.get('source_unchanged'):
        raise ValueError('A successful isolated import is required')
    payload = {}
    for name, expected in report['files'].items():
        if name != 'launch.f' and not name.startswith('assetss/'):
            continue
        path = game / name
        if path.is_symlink() or game not in path.resolve().parents or sha(path) != expected:
            raise ValueError('Unverified game resource: ' + name)
        payload[name] = expected
    if payload.get('launch.f') != LAUNCH_SHA256:
        raise ValueError('Unsupported game entry')
    return payload


def build(sdk, game, output, scratch, app_id=APP_ID, seed_path=None, diagnostic_suite=None):
    sdk, game, output, scratch = [Path(p).resolve() for p in (sdk, game, output, scratch)]
    if output.suffix != '.app' or output.exists() or scratch.exists():
        raise ValueError('Choose a fresh .app output and fresh scratch directory')
    for target in (output, scratch):
        for protected in (sdk, game):
            if target == protected or target in protected.parents or protected in target.parents:
                raise ValueError('Build paths must be separate from SDK and imported game')
    if output == scratch or output in scratch.parents or scratch in output.parents:
        raise ValueError('Output and scratch must be separate, non-nested paths')
    if not re.fullmatch(r'local\.bvn\.macos\.[A-Za-z0-9][A-Za-z0-9.-]*', app_id):
        raise ValueError('Use an isolated local application ID')
    payload = checked_payload(game)
    explicit_seed = seed_path is not None
    seed_path = Path(seed_path).resolve() if explicit_seed else game / 'bvnsave.sav'
    if explicit_seed and not seed_path.is_file():
        raise ValueError('Requested seed save is missing')
    if seed_path.exists() and not isinstance(json.loads(seed_path.read_text()), dict):
        raise ValueError('Seed save must be a JSON object')
    project = Path(__file__).resolve().parents[1]
    icon = project / 'assets/AppIcon.icns'
    if not icon.is_file():
        raise ValueError('Application icon is missing; run scripts/build_icon.py first')
    if diagnostic_suite:
        cases = json.loads(Path(diagnostic_suite).read_text())
        if not isinstance(cases, list) or not all(isinstance(c, dict) and 'fighter' in c for c in cases):
            raise ValueError('Diagnostic suite must be a list of fighter cases')
    scratch.mkdir(parents=True)
    stage = scratch / 'stage'
    stage.mkdir()
    if diagnostic_suite:
        (stage / 'suite.json').write_text(json.dumps(cases, ensure_ascii=False))
    output.parent.mkdir(parents=True, exist_ok=True)
    for name in payload:
        target = stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(game / name, target)
    seed_hash = None
    if seed_path.exists():
        json.loads(seed_path.read_text())
        seed_hash = sha(seed_path)
        shutil.copy2(seed_path, stage / 'bvnsave.sav')
    ns = 'http://ns.adobe.com/air/application/32.0'
    ET.register_namespace('', ns)
    root = ET.parse(game / 'application-macos.xml').getroot()
    root.find('{%s}id' % ns).text = app_id
    root.find('{%s}filename' % ns).text = 'BVNMac'
    if not diagnostic_suite:
        root.find('{%s}name' % ns).text = '死神VS火影'
    window = root.find('{%s}initialWindow' % ns)
    entry = 'suite.swf' if diagnostic_suite else 'mac-launcher.swf'
    window.find('{%s}content' % ns).text = entry
    for name, value in [('width', '800'), ('height', '700' if diagnostic_suite else '600')]:
        node = window.find('{%s}%s' % (ns, name))
        if node is None:
            node = ET.SubElement(window, '{%s}%s' % (ns, name))
        node.text = value
    ET.ElementTree(root).write(stage / 'application.xml', encoding='utf-8', xml_declaration=True)
    sources = {str(p.relative_to(project)): sha(p) for p in (project / 'src/compat').rglob('*.as')}
    if diagnostic_suite:
        sources['src/diagnostics/SuiteHarness.as'] = sha(project / 'src/diagnostics/SuiteHarness.as')
    manifest = {'created_at': datetime.datetime.now().astimezone().isoformat(),
                'app_id': app_id, 'original_payload': payload, 'adapter_sources': sources,
                'commands': [], 'status': 'building', 'publicly_notarized': False,
                'seed_sha256': seed_hash, 'diagnostic_suite': cases if diagnostic_suite else None,
                'icon_sha256': sha(icon)}
    with (scratch / 'build.log').open('w') as log:
        def run(command):
            command = list(map(str, command))
            manifest['commands'].append(command)
            subprocess.run(command, cwd=project, stdout=log, stderr=subprocess.STDOUT, check=True)
        compiler = [sdk / 'bin/amxmlc', '-swf-version=43', '-debug=false',
                    '-source-path=' + str(project / 'src/compat'), '-output=' + str(stage / entry)]
        if diagnostic_suite:
            compiler += ['-source-path+=' + str(project / 'src/diagnostics'), project / 'src/diagnostics/SuiteHarness.as']
        else:
            compiler += [project / 'src/compat/MacLauncher.as']
        run(compiler)
        certificate = scratch / 'local-build.p12'
        run([sdk / 'bin/adt', '-certificate', '-cn', 'BVN Local Compatibility Build',
             '-validityPeriod', '1', '2048-RSA', certificate, 'local-build-only'])
        files = [entry, 'launch.f', 'assetss']
        if diagnostic_suite:
            files.append('suite.json')
        if (stage / 'bvnsave.sav').exists():
            files.append('bvnsave.sav')
        run([sdk / 'bin/adt', '-package', '-storetype', 'pkcs12', '-keystore', certificate,
             '-storepass', 'local-build-only', '-tsa', 'none', '-target', 'bundle', output,
             stage / 'application.xml', '-C', stage] + files)
        shutil.copy2(icon, output / 'Contents/Resources/AppIcon.icns')
        info_path = output / 'Contents/Info.plist'
        info = plistlib.loads(info_path.read_bytes())
        info['CFBundleIconFile'] = 'AppIcon.icns'
        if not diagnostic_suite:
            info['CFBundleName'] = '死神VS火影'
            info['CFBundleDisplayName'] = '死神VS火影'
        info_path.write_bytes(plistlib.dumps(info))
        run(['codesign', '--force', '--deep', '--sign', '-', output])
        run(['codesign', '--verify', '--deep', '--strict', output])
    resources = output / 'Contents/Resources'
    for name, expected in payload.items():
        if sha(resources / name) != expected:
            raise RuntimeError('Packaged original resource differs: ' + name)
    runtime = output / 'Contents/Frameworks/Adobe AIR.framework/Versions/1.0/Resources/Info.plist'
    manifest.update(status='built_payload_verified', adapter_swf_sha256=sha(resources / entry),
                    runtime_version=plistlib.loads(runtime.read_bytes()).get('CFBundleVersion'),
                    local_signing='ad-hoc; no Developer ID or notarization',
                    data_directory=str(Path.home() / 'Library/Application Support' / app_id / 'Local Store'),
                    bundle_files={str(p.relative_to(output)): sha(p) for p in output.rglob('*')
                                  if p.is_file() and not p.is_symlink()})
    (scratch / 'build-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('sdk', 'game', 'output', 'scratch'):
        parser.add_argument('--' + name, required=True)
    parser.add_argument('--app-id', default=APP_ID)
    parser.add_argument('--seed', help='Optional read-only initial save; copied only into this new bundle')
    parser.add_argument('--diagnostic-suite', help='Build the visibly labelled integration-test app with this case list')
    args = parser.parse_args()
    result = build(args.sdk, args.game, args.output, args.scratch, args.app_id, args.seed, args.diagnostic_suite)
    print(json.dumps({'status': result['status'], 'output': args.output,
                      'manifest': str(Path(args.scratch) / 'build-manifest.json')}, ensure_ascii=False))
