#!/usr/bin/env python3
"""Read resource use for one explicitly supplied test PID until it exits."""
import argparse
import datetime
import json
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pid', type=int)
parser.add_argument('output', type=Path)
args = parser.parse_args()
args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open('a', buffering=1) as output:
    while True:
        result = subprocess.run(['ps', '-o', 'pid=,etime=,%cpu=,rss=,stat=', '-p', str(args.pid)],
                                text=True, capture_output=True)
        if result.returncode or not result.stdout.strip():
            break
        output.write(json.dumps({'time': datetime.datetime.now().astimezone().isoformat(),
                                 'ps': result.stdout.strip(), 'rss_unit': 'KiB'}) + '\n')
        time.sleep(15)
