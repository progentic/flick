#!/usr/bin/env python3
"""Execute platform gates and keep full current-run output outside the checkout."""
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def main():
    if platform.system() != 'Darwin' or not shutil.which('swift') or not shutil.which('xcodebuild'):
        print('INCONCLUSIVE: macOS, Swift, and Xcode are required for platform gates')
        return 2
    output = Path(os.environ.get('FLICK_VALIDATION_DIR') or tempfile.mkdtemp(prefix='flick-packages-'))
    output.mkdir(parents=True, exist_ok=True)
    try:
        version = run(['swift', '--version'], output / 'swift-version.log')
        print(version.strip())
        match = re.search(r'Swift version (\d+)\.(\d+)', version)
        if not match or tuple(map(int, match.groups())) < (6, 3):
            print('INCONCLUSIVE: Swift tools 6.3 or newer required')
            return 2
        print(run(['xcodebuild', '-version'], output / 'xcode-version.log').strip())
        policy = json.loads((ROOT / '.repo-policy.json').read_text())
        for name, dependencies in policy['packages'].items():
            validate_package(name, dependencies, policy, output)
        if (ROOT / policy['app_project']).exists():
            run(['xcodebuild', '-project', policy['app_project'], '-scheme', policy['app_scheme'],
                 '-sdk', 'iphonesimulator', '-destination', 'generic/platform=iOS Simulator',
                 '-derivedDataPath', str(output / 'app'), 'CODE_SIGN_IDENTITY=-', 'CODE_SIGNING_ALLOWED=YES', 'build'], output / 'app.log')
            print('PASS: app build')
        else:
            print('NOT_APPLICABLE: App/Flick.xcodeproj does not exist')
        print(f'PASS: all applicable package gates; logs: {output}')
        return 0
    except subprocess.CalledProcessError as error:
        print(f'FAIL: {error.cmd}; current output:\n{error.output}')
        return 1
    except (AssertionError, ValueError) as error:
        print(f'FAIL: {error}')
        return 1
    except OSError as error:
        print(f'INCONCLUSIVE: {error}')
        return 2


def validate_package(name, dependencies, policy, output):
    options = ['--package-path', str(ROOT / 'Packages' / name),
               '--scratch-path', str(output / 'build' / name)]
    manifest = json.loads(run(['swift', 'package', *options, 'dump-package'], output / f'{name}-manifest.json'))
    actual = [item['fileSystem'][0]['path'] for item in manifest['dependencies']]
    expected = [str(ROOT / 'Packages' / dep) for dep in dependencies]
    assert sorted(actual) == sorted(expected), f'{name}: evaluated dependencies differ from policy'
    assert manifest['toolsVersion']['_version'] == '6.3.0', f'{name}: evaluated tools version'
    assert manifest['swiftLanguageVersions'] == ['6'], f'{name}: evaluated language mode'
    assert any(p['platformName'] == 'ios' and p['version'] == '26.0' for p in manifest['platforms']), f'{name}: evaluated iOS target'
    run(['swift', 'package', *options, 'resolve'], output / f'{name}-resolve.log')
    print(f'PASS: {name} manifest and dependency resolution', flush=True)
    run(['swift', 'build', *options], output / f'{name}-build.log')
    print(f'PASS: {name} build/import validation', flush=True)
    has_tests = any(target['type'] == 'test' for target in manifest['targets'])
    assert has_tests == (name in policy['test_packages']), f'{name}: unexpected test target inventory'
    if has_tests:
        text = run(['swift', 'test', *options], output / f'{name}-test.log')
        match = re.search(r'Test run with (\d+) tests? in (\d+) suites? passed', text)
        assert match and int(match[1]) > 0, f'{name}: no executed Swift Testing evidence'
        print(f'PASS: {name} {match[1]} tests in {match[2]} suites', flush=True)
    else:
        print(f'NOT_APPLICABLE: {name} behavior tests (interface/import scaffold only)')


def run(command, log):
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    log.write_text(result.stdout + result.stderr)
    if result.returncode:
        raise subprocess.CalledProcessError(result.returncode, command, result.stdout + result.stderr)
    # Manifest JSON must not include stderr warnings.
    return result.stdout if 'dump-package' in command else result.stdout + result.stderr


if __name__ == '__main__':
    sys.exit(main())
