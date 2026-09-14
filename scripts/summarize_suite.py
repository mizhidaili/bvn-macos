#!/usr/bin/env python3
"""Summarize observed integration evidence; missing actions remain partial."""
import argparse
import json
from pathlib import Path


def summarize(path):
    cases = {}
    terminal = None
    with Path(path).open() as stream:
        for line in stream:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue  # A live report may end with a not-yet-finished line.
            kind = row['type']
            if kind in ('done', 'stop', 'error'):
                terminal = row
            if 'index' not in row:
                continue
            case = cases.setdefault(row['index'], {'index': row['index'], 'states': set(), 'actual_ids': set()})
            if kind == 'case_start':
                case['config'] = row['config']
            elif kind == 'state':
                case['states'].add(row['a']['state'])
                case['actual_ids'].add(row['a']['id'])
            elif kind == 'case_result':
                case['result'] = row['result']
    output = []
    for case in cases.values():
        states = case['states']
        result = case.get('result')
        if result:
            if result['reason'] == 'load_timeout' and 'random' in (case['config'].get('fighter'), case['config'].get('assist')):
                case['known_fixture_issue'] = 'Random selector placeholder was passed directly to asset loading; resolve through selector or retest with concrete IDs.'
            labels = result['labels']
            checks = {
                'loaded': result['loaded'],
                'observed_movement': '走' in labels and result['maxX'] - result['minX'] > 5,
                'normal_attack': 10 in states,
                'skill': bool(states.intersection({11, 12, 13})),
                'jump': 14 in states,
                'received_damage': result['minHP'] < 1000,
                'dealt_damage': result['minEnemyHP'] < 1000,
                'assist_trigger': result.get('assistSeen', False),
                'digital_audio_active': result.get('audioPeak', 0) > 0.00001,
                'sequence_complete': result['reason'] == 'duration_complete',
            }
            case['checks'] = checks
            case['status'] = 'smoke_pass' if all(checks.values()) else 'partial'
            case['missing'] = [key for key, value in checks.items() if not value]
        else:
            case['status'] = 'running_or_incomplete'
        case['states'] = sorted(states)
        case['actual_ids'] = sorted(case['actual_ids'])
        output.append(case)
    return {'source': str(path), 'scope': 'Synthetic input smoke tests; not physical keyboard, full matches, or final acceptance',
            'completed': sum('result' in c for c in output), 'smoke_pass': sum(c['status'] == 'smoke_pass' for c in output),
            'partial': sum(c['status'] == 'partial' for c in output), 'terminal': terminal, 'cases': output}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = summarize(args.report)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2))
    print(json.dumps({k: v for k, v in report.items() if k != 'cases'}, ensure_ascii=False))
    for case in report['cases']:
        if case['status'] == 'partial':
            print(json.dumps({'fighter': case['config']['fighter'], 'missing': case['missing']}, ensure_ascii=False))
