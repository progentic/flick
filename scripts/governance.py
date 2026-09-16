#!/usr/bin/env python3
"""Portable structural gates. Swift compilation is a separate platform gate."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


class Inconclusive(Exception):
    pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base', default=os.environ.get('BASE_SHA') or 'HEAD')
    parser.add_argument('--source', default=os.environ.get('SOURCE_SHA'))
    parser.add_argument('--ui-only', action='store_true')
    parser.add_argument('--inventory-write', action='store_true')
    args = parser.parse_args()
    try:
        establish_root()
        if args.inventory_write:
            write_inventory()
            return 0
        changed = changed_paths(args.base, args.source)
        print(f'PASS: change detection ({len(changed)} paths including untracked files)')
        if args.ui_only:
            check_ui()
            return 0
        policy = json.loads((ROOT / '.repo-policy.json').read_text())
        check_metadata()
        check_packages(policy)
        check_workflows()
        check_inventory()
        print('PASS: repository governance (portable structural checks only)')
        return 0
    except Inconclusive as error:
        print(f'INCONCLUSIVE: {error}')
        return 2
    except (AssertionError, ValueError) as error:
        print(f'FAIL: {error}')
        return 1
    except (OSError, subprocess.CalledProcessError) as error:
        print(f'INCONCLUSIVE: {error}')
        return 2


def establish_root():
    actual = Path(git('rev-parse', '--show-toplevel').strip()).resolve()
    assert actual == ROOT, f'Git root {actual} is not Flick root {ROOT}'


def changed_paths(base, source=None):
    head = git('rev-parse', '--verify', 'HEAD^{commit}').strip()
    if source:
        assert re.fullmatch(r'[0-9a-f]{40}', source), 'source must be a full commit SHA'
        assert head == source, 'checkout does not match the exact requested source SHA'
        assert not git('status', '--porcelain', '--untracked-files=all').strip(), 'source checkout has uncommitted changes'
    if not base or set(base) == {'0'}:
        raise Inconclusive('comparison base is missing; supply a reachable commit')
    try:
        base_sha = git('rev-parse', '--verify', base + '^{commit}').strip()
        common = git('merge-base', base_sha, head).strip()
    except subprocess.CalledProcessError as error:
        raise Inconclusive('comparison base is missing or unrelated') from error
    changed = git('diff', '--name-only', '-z', common, '--').split('\0')
    untracked = git('ls-files', '--others', '--exclude-standard', '-z').split('\0')
    mode = 'exact-clean-source' if source else 'working-tree-plus-untracked'
    print(f'PASS: source={head}, comparison={common}, mode={mode}')
    return sorted(set(changed + untracked) - {''})


def check_metadata():
    required = ['LICENSE', 'AGENTS.md', 'DESIGN.md', 'SECURITY.md', 'UI-REVIEW.md',
                '.editorconfig', '.gitattributes', '.gitignore', '.github/CODEOWNERS',
                '.github/pull_request_template.md', '.github/dependabot.yml',
                'TASK_PROMPT-v0.0.0-to-v0.0.1.md']
    required += ['docs/' + name + '.md' for name in [
        'REPOSITORY_STATE', 'GOVERNANCE', 'INVARIANTS', 'ARCHITECTURE', 'ROADMAP',
        'TESTING', 'DEPENDENCIES', 'RELEASES', 'CODING_STYLE', 'ERROR_HANDLING']]
    for name in required:
        assert (ROOT / name).is_file(), f'missing required file: {name}'
    license_text = (ROOT / 'LICENSE').read_bytes()
    assert hashlib.sha256(license_text).hexdigest() == '1b51746b0630b04c37f5dfcec488a2a50412c92574790e2315e06d72040d260e', 'BSD license changed'
    for number in range(1, 8):
        matches = list((ROOT / 'docs/adr').glob(f'{number:04}-*.md'))
        assert len(matches) == 1, f'ADR-{number:04} missing or duplicated'
        status = [line.rstrip(' \\') for line in matches[0].read_text().splitlines() if line.startswith('Status:')]
        assert status == ['Status: Proposed'], f'ADR-{number:04} requires owner acceptance'
    assert '@progentic' in (ROOT / '.github/CODEOWNERS').read_text(), 'CODEOWNERS must name progentic'
    if (ROOT / 'App/Flick.xcodeproj').exists():
        assert (ROOT / 'CHANGELOG.md').is_file(), 'application changes need CHANGELOG.md'
        assert (ROOT / 'App/Flick.xcodeproj/xcshareddata/xcschemes/Flick.xcscheme').is_file(), 'shared Flick scheme missing'
        project = (ROOT / 'App/Flick.xcodeproj/project.pbxproj').read_text()
        assert 'IPHONEOS_DEPLOYMENT_TARGET = "26.0"' in project, 'app iOS 26 target missing'
        assert 'SWIFT_STRICT_CONCURRENCY = "complete"' in project, 'strict concurrency missing'
        assert 'INFOPLIST_KEY_UIUserInterfaceStyle = "Automatic"' in project, 'explicit system appearance support missing'
    print('PASS: metadata, exact license, and Proposed ADR status')


def check_packages(policy):
    graph = policy['packages']
    found = {p.parent.name for p in (ROOT / 'Packages').glob('*/Package.swift')}
    assert found == set(graph), 'package inventory differs from policy'
    for name, dependencies in graph.items():
        base = ROOT / 'Packages' / name
        manifest = (base / 'Package.swift').read_text()
        assert manifest.startswith('// swift-tools-version: ' + policy['tools'] + '\n'), f'{name}: tools version'
        assert 'swiftLanguageModes: [.v6]' in manifest, f'{name}: Swift 6 mode'
        assert 'platforms: [.iOS(.v26)' in manifest, f'{name}: iOS 26 minimum'
        paths = re.findall(r'\.package\(path: "([^"\n]+)"\)', manifest)
        assert sorted(paths) == sorted('../' + dep for dep in dependencies), f'{name}: dependency graph'
        assert manifest.count('.package(') == len(paths), f'{name}: unsupported package dependency declaration'
        products = re.findall(r'\.product\(name: "(\w+)", package: "(\w+)"\)', manifest)
        assert set(products) == {(dep, dep) for dep in dependencies}, f'{name}: target dependency products'
        sources = list((base / 'Sources' / name).rglob('*.swift'))
        assert sources, f'{name}: no source files'
        for relative in paths:
            assert (base / relative / 'Package.swift').is_file(), f'{name}: missing local package {relative}'
        for source in sources:
            code = re.sub(r'/\*.*?\*/|//[^\n]*', '', source.read_text(), flags=re.S)
            imports = set(re.findall(r'\bimport\s+(\w+)', code))
            allowed = set(dependencies) | {'Foundation'} | set(policy.get('system_imports', {}).get(name, []))
            assert imports <= allowed, f'{source}: prohibited import {imports}'
        tests = list((base / 'Tests').rglob('*.swift'))
        assert bool(tests) == (name in policy['test_packages']), f'{name}: tests differ from policy'
        assert all(not re.search(r'#expect\(\s*true\s*\)', p.read_text()) for p in tests), f'{name}: placeholder test'
    visit_dependencies(graph)
    print('PASS: static package graph and import boundaries; resolution/build run separately')


def visit_dependencies(graph):
    def visit(name, ancestors):
        assert name not in ancestors, f'package cycle at {name}'
        assert name in graph, f'unknown package {name}'
        for dependency in graph[name]:
            visit(dependency, ancestors | {name})
    for name in graph:
        visit(name, set())


def check_workflows():
    workflows = list((ROOT / '.github/workflows').glob('*.yml'))
    assert len(workflows) == 2, 'expected governance and package workflows'
    for path in workflows:
        text = path.read_text()
        refs = re.findall(r'uses:\s*([^\s#]+)', text)
        assert refs, f'{path}: missing checkout action'
        assert all(re.fullmatch(r'[\w./-]+@[0-9a-f]{40}', ref) for ref in refs), f'{path}: mutable action reference'
        assert 'persist-credentials: false' in text, f'{path}: persisted credentials'
        assert 'ref: ${{ github.event.pull_request.head.sha || github.sha }}' in text, f'{path}: source correlation'
        assert 'fetch-depth: 0' in text, f'{path}: comparison history missing'
        assert 'pull_request_target' not in text, f'{path}: privileged PR trigger'
        assert 'contents: read' in text, f'{path}: permissions not restricted'
    print('PASS: CI pinning and exact-source checkout structure')


def check_ui():
    app = ROOT / 'App'
    candidates = list((ROOT / 'Packages').rglob('*.swift'))
    if app.exists():
        candidates += list(app.rglob('*.swift'))
    has_ui = (app / 'Flick.xcodeproj').exists() or any(
        re.search(r'\bimport\s+(SwiftUI|UIKit)|:\s*(?:some\s+)?View\b', p.read_text())
        for p in candidates)
    if has_ui:
        check_ui_evidence()
        return
    print('NOT_APPLICABLE: no application target or UI implementation')


def check_ui_evidence():
    evidence_path = ROOT / '.ui-evidence.json'
    if not evidence_path.exists():
        raise Inconclusive('UI evidence and explicit human approval are required')
    evidence = json.loads(evidence_path.read_text())
    fingerprint = ui_source_fingerprint()
    assert evidence.get('source_fingerprint') == fingerprint, 'UI evidence is stale for this source tree'
    required = {'empty', 'entry', 'saving', 'processing', 'note', 'save_failure',
                'load_failure', 'processing_failure', 'dark', 'large_type', 'high_contrast'}
    surfaces = evidence.get('surfaces', {})
    assert required <= surfaces.keys(), 'required rendered surfaces missing'
    for surface in surfaces.values():
        path = (ROOT / surface['path']).resolve()
        assert path.is_relative_to(ROOT), 'UI evidence path escapes repository'
        assert path.is_file(), f'missing rendered evidence: {path}'
        assert path.suffix == '.png' and path.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'), f'not a PNG screenshot: {path}'
        assert hashlib.sha256(path.read_bytes()).hexdigest() == surface['sha256'], f'changed screenshot: {path}'
    checks = evidence.get('checks', {})
    for check in ['ui_tests', 'accessibility_audits', 'contrast', 'dynamic_type']:
        if checks.get(check) != 'PASS':
            raise Inconclusive(f'UI verification incomplete: {check}')
    approval = evidence.get('human_approval')
    if not approval:
        raise Inconclusive('HIGH-criticality UI awaits explicit human visual approval; rendered evidence is available')
    assert approval.get('reviewer') and approval.get('decision') == 'approved', 'human approval missing identity or decision'
    assert approval.get('source_fingerprint') == fingerprint, 'human approval belongs to a different source tree'
    assert '**Status:** PASS' in (ROOT / 'UI-REVIEW.md').read_text(), 'human-readable UI review is not approved'
    print('PASS: current UI evidence and recorded human approval')


def ui_source_fingerprint():
    included = set(inventory())
    paths = [ROOT / 'DESIGN.md']
    paths += list((ROOT / 'Packages').glob('*/Package.swift'))
    paths += [path for path in (ROOT / 'App').rglob('*') if path.is_file()
              and 'FlickUITests' not in path.parts and 'xcuserdata' not in path.parts]
    paths += [path for source in (ROOT / 'Packages').glob('*/Sources')
              for path in source.rglob('*') if path.is_file()]
    entries = [str(path.relative_to(ROOT)) + '\0' + hashlib.sha256(path.read_bytes()).hexdigest()
               for path in sorted(paths) if str(path.relative_to(ROOT)) in included]
    return hashlib.sha256('\n'.join(entries).encode()).hexdigest()


def inventory():
    names = git('ls-files', '--cached', '--others', '--exclude-standard', '-z').split('\0')
    files = sorted({name for name in names if name and (ROOT / name).is_file()})
    assert not any('\n' in name for name in files), 'newline filename unsupported by inventory'
    return files


def inventory_content(files):
    return ''.join('./' + name + '\n' for name in files)


def checksums_content(files):
    return ''.join(hashlib.sha256((ROOT / name).read_bytes()).hexdigest() + '  ' + name + '\n'
                   for name in files if name != 'SHA256SUMS.txt')


def write_inventory():
    for name in ['MANIFEST.txt', 'SHA256SUMS.txt']:
        (ROOT / name).touch(exist_ok=True)
    files = inventory()
    (ROOT / 'MANIFEST.txt').write_text(inventory_content(files))
    (ROOT / 'SHA256SUMS.txt').write_text(checksums_content(files))
    print(f'PASS: generated manifest and checksums for {len(files)} files')


def check_inventory():
    files = inventory()
    assert (ROOT / 'MANIFEST.txt').read_text() == inventory_content(files), 'MANIFEST.txt does not match checkout'
    assert (ROOT / 'SHA256SUMS.txt').read_text() == checksums_content(files), 'SHA256SUMS.txt is stale'
    print(f'PASS: checkout inventory and checksums ({len(files)} files)')


def git(*arguments):
    return subprocess.run(['git', *arguments], cwd=ROOT, check=True,
                          capture_output=True, text=True).stdout


if __name__ == '__main__':
    sys.exit(main())
