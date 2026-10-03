"""Runs integration_test/store_media_test.dart and takes the screenshots it
asks for, through its @@ markers.

    python tool/store_media/capture.py <simulator udid> <iphone|ipad> [scene]
    python tool/store_media/capture.py mac [scene]

On a simulator the status bar is set to 9:41 with a full battery first, and
each screenshot is saved twice in build/store_media/<iphone|ipad>/: raw/
(plain) and masked/ (with the device's rounded corners and notch, for the
framed versions).

On "mac" the test runs on this Mac and draws the app off screen, at the size
and scale of a Retina window; the screenshots come back through the log, as
@@DATA lines of base64, and land in build/store_media/mac/raw/.

Then run compose.py.
"""

import base64
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]
MARKER = re.compile(r'@@(\w+)(?: (\S+))?(?: (\S+))? t=(\d+)')

# The simulator service may not be allowed to write to external volumes, so
# files are saved here first and then moved to the output folder.
STAGING = pathlib.Path(tempfile.mkdtemp(prefix='store_media_'))


def run_test(device, defines):
    command = ['flutter', 'test', 'integration_test/store_media_test.dart',
               '-d', device, *[f'--dart-define={d}' for d in defines]]
    return subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, bufsize=1)


def capture_mac(scene):
    out = ROOT / 'build' / 'store_media' / 'mac' / 'raw'
    out.mkdir(parents=True, exist_ok=True)
    test = run_test('macos', ['MAC=true', f'SCENE={scene}'])
    data = {}
    for line in test.stdout:
        match = MARKER.search(line)
        if not match:
            sys.stdout.write(line)
            continue
        kind, name, payload = match.group(1, 2, 3)
        if kind == 'DATA':
            data.setdefault(name, []).append(payload)
        elif kind == 'SHOT':
            (out / f'{name}.png').write_bytes(
                base64.b64decode(''.join(data.pop(name))))
            print(f'[capture] {name}')
    sys.exit(test.wait())


def capture_simulator(udid, device, scene):
    out = ROOT / 'build' / 'store_media' / device
    for folder in ('raw', 'masked'):
        (out / folder).mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ['xcrun', 'simctl', 'status_bar', udid, 'override', '--time', '9:41',
         '--dataNetwork', 'wifi', '--wifiBars', '3', '--cellularBars', '4',
         '--batteryState', 'charged', '--batteryLevel', '100'],
        check=True)

    test = run_test(udid, [f'SCENE={scene}'])
    for line in test.stdout:
        sys.stdout.write(line)
        match = MARKER.search(line)
        if not match or match.group(1) != 'SHOT':
            continue
        name, sent = match.group(2), int(match.group(4))
        delay = time.time() - sent / 1000
        for folder, mask in (('raw', []), ('masked', ['--mask=alpha'])):
            staged = STAGING / f'{folder}_{name}.png'
            subprocess.run(
                ['xcrun', 'simctl', 'io', udid, 'screenshot', '--type=png',
                 *mask, str(staged)],
                check=True, capture_output=True)
            shutil.move(staged, out / folder / f'{name}.png')
        print(f'[capture] {name}: marker arrived {delay:.2f}s late, '
              f'taken {time.time() - sent / 1000:.2f}s after it')
    sys.exit(test.wait())


def main():
    if sys.argv[1] == 'mac':
        capture_mac(sys.argv[2] if len(sys.argv) > 2 else '')
    udid, device = sys.argv[1:3]
    capture_simulator(udid, device, sys.argv[3] if len(sys.argv) > 3 else '')


if __name__ == '__main__':
    main()
