#!/usr/bin/env python3
"""Run an imported private candidate with a user-provided, licensed Mac AIR SDK."""
import argparse, datetime, hashlib, json, os, subprocess, sys
from pathlib import Path
import xml.etree.ElementTree as ET
from import_game import APP_ID, LAUNCH_SHA256, sha

def prepare(sdk, game, evidence):
    sdk, game, evidence = map(lambda p: Path(p).resolve(), (sdk, game, evidence))
    report = json.loads((game / 'import-report.json').read_text())
    if report.get('application_id') != APP_ID or not report.get('source_unchanged'):
        raise ValueError('Missing successful isolated import report')
    descriptor = game / 'application-macos.xml'
    root = ET.fromstring(descriptor.read_text())
    ns = {'a':'http://ns.adobe.com/air/application/32.0'}
    if root.find('a:id', ns).text != APP_ID:
        raise ValueError('Original/shared application ID is not allowed')
    if sha(game / 'launch.f') != LAUNCH_SHA256:
        raise ValueError('Entry fingerprint changed; create a separately documented experiment')
    for rel, expected in report['files'].items():
        if rel == 'bvnsave.sav':
            continue
        p = game / rel
        if p.is_symlink() or game not in p.resolve().parents or sha(p) != expected:
            raise ValueError('Imported resource changed: ' + rel)
    adl = sdk / 'bin/adl'
    if not adl.is_file():
        raise ValueError('Mac ADL is missing: ' + str(adl))
    identity = subprocess.check_output(['file', str(adl)], text=True).strip()
    if 'Mach-O' not in identity:
        raise ValueError('ADL is not a macOS executable: ' + identity)
    stamp = datetime.datetime.now().astimezone().strftime('%Y%m%d-%H%M%S-%f')
    run = evidence / ('adl-' + stamp); run.mkdir(parents=True)
    command = [str(adl), '-profile', 'extendedDesktop', str(descriptor), str(game)]
    data = {'started_at': datetime.datetime.now().astimezone().isoformat(),
            'command':command,'cwd':str(game),'adl_identity':identity,'adl_sha256':sha(adl),
            'descriptor_sha256':sha(descriptor),'game_entry_sha256':sha(game/'launch.f'),
            'save_path_expected':str(game/'bvnsave.sav'),
            'air_storage_expected':str(Path.home()/'Library/Application Support'/APP_ID/'Local Store'),
            'storage_runtime_verified':False}
    (run/'run.json').write_text(json.dumps(data,indent=2))
    return command, game, run, data

if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--sdk',required=True);p.add_argument('--game',required=True)
    p.add_argument('--evidence',default='.workflow/bvn-macos/evidence')
    a=p.parse_args()
    try:
        command,game,run,data=prepare(a.sdk,a.game,a.evidence)
    except (OSError,ValueError,KeyError,ET.ParseError) as e:
        p.exit(1,str(e)+'\n')
    with (run/'stdout.log').open('w') as log:
        proc=subprocess.Popen(command,cwd=game,stdout=log,stderr=subprocess.STDOUT)
        data['pid']=proc.pid;(run/'run.json').write_text(json.dumps(data,indent=2))
        print(json.dumps({'pid':proc.pid,'evidence':str(run)},indent=2),flush=True)
        try: code=proc.wait()
        except KeyboardInterrupt:
            proc.terminate();code=proc.wait()
        data.update(exit_code=code,ended_at=datetime.datetime.now().astimezone().isoformat())
        (run/'run.json').write_text(json.dumps(data,indent=2))
    sys.exit(code)
