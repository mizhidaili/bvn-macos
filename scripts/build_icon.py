#!/usr/bin/env python3
"""Package the original PNG into a macOS ICNS with Apple's local tools."""
import argparse
from pathlib import Path
import subprocess
import tempfile


def build_icon(source, output):
    source, output = Path(source).resolve(), Path(output).resolve()
    if not source.is_file() or source == output:
        raise ValueError('Choose an existing PNG and a separate ICNS output')
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='bvn-icon-') as temporary:
        iconset = Path(temporary) / 'AppIcon.iconset'
        iconset.mkdir()
        for size in (16, 32, 128, 256, 512):
            for scale in (1, 2):
                suffix = '@2x' if scale == 2 else ''
                target = iconset / f'icon_{size}x{size}{suffix}.png'
                subprocess.run(['sips', '-z', str(size * scale), str(size * scale),
                                str(source), '--out', str(target)],
                               stdout=subprocess.DEVNULL, check=True)
        subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o', str(output)], check=True)
    return output


if __name__ == '__main__':
    project = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=project / 'assets/app-icon.png')
    parser.add_argument('--output', type=Path, default=project / 'assets/AppIcon.icns')
    args = parser.parse_args()
    print(build_icon(args.source, args.output))
