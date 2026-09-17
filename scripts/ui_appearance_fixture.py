#!/usr/bin/env python3
"""Serve state-based Simulator appearance requests from the UI-test runner.

The app never uses this fixture. Requests contain only a UUID and light/dark;
responses acknowledge simctl's observed device setting. No polling sleeps,
application data writes, appearance guesses, or test-success injection.
"""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import uuid


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('device')
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    requests = args.directory / 'requests'
    responses = args.directory / 'responses'
    requests.mkdir(parents=True)
    responses.mkdir()
    descriptor = os.open(requests, os.O_RDONLY)
    queue = select.kqueue()
    event = select.kevent(descriptor, filter=select.KQ_FILTER_VNODE,
                         flags=select.KQ_EV_ADD | select.KQ_EV_CLEAR,
                         fflags=select.KQ_NOTE_WRITE)
    queue.control([event], 0)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    (args.directory / 'ready').write_text(args.device)
    try:
        while True:
            for request in sorted(requests.glob('*.json')):
                respond(request, responses, args.device)
            queue.control(None, 1)
    finally:
        queue.close()
        os.close(descriptor)


def respond(path, responses, device):
    result = {'ok': False}
    try:
        request = json.loads(path.read_text())
        identifier = str(uuid.UUID(request['id'])).upper()
        assert path.name == identifier + '.json', 'request identity mismatch'
        mode = request['appearance']
        assert mode in ('light', 'dark'), 'unsupported appearance'
        run_simctl(device, mode)
        actual = run_simctl(device)
        result = {'id': identifier, 'requested': mode, 'actual': actual, 'ok': actual == mode}
    except (AssertionError, KeyError, ValueError, OSError, subprocess.SubprocessError) as error:
        result['error'] = str(error)
    temporary = responses / (path.name + '.tmp')
    temporary.write_text(json.dumps(result))
    temporary.replace(responses / path.name)
    path.unlink()
    print(datetime.now(timezone.utc).isoformat(), json.dumps(result), flush=True)


def run_simctl(device, mode=None):
    command = ['xcrun', 'simctl', 'ui', device, 'appearance']
    if mode is not None:
        command.append(mode)
    return subprocess.run(command, text=True, capture_output=True,
                          check=True, timeout=10).stdout.strip()


if __name__ == '__main__':
    main()
