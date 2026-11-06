"""Freeze an owned local test package and matching tested SDK. Never installs or publishes."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sdk = args.sdk.resolve(strict=True)
    output = args.output.resolve()
    if output.exists():
        raise ValueError('Existing candidate is preserved; use a new output folder')
    tests = json.loads((ROOT / 'build/TEST_RESULTS.json').read_text())
    sdk_tests = json.loads((sdk / 'build/unified/test-results.json').read_text())
    build = json.loads((sdk / 'dist/dinput8.build.json').read_text())
    if tests['status'] != 'passed' or sdk_tests['status'] != 'passed':
        raise ValueError('Passing addon and SDK tests are required')
    for digest in (tests['sdk_artifact_sha256'], sdk_tests['artifact_sha256'], sha(sdk / 'dist/dinput8.dll')):
        if digest != build['artifact_sha256']:
            raise ValueError('SDK artifact/evidence mismatch')
    for base, inputs in ((ROOT, tests['source_sha256']), (sdk, build['source_sha256'])):
        for name, digest in inputs.items():
            if sha(base / name) != digest:
                raise ValueError('Input changed since validation: ' + name)
    version = ET.parse(ROOT / 'mod.xml').getroot().attrib['version']
    sources = [ROOT / 'mod.xml', ROOT / 'LICENSE', ROOT / 'PLAYER_README.md',
               *sorted((ROOT / 'content').rglob('*'))]
    files = []
    for path in sources:
        if path.is_symlink() or path.is_junction():
            raise ValueError('Links are not package inputs')
        if path.is_file():
            if path.suffix.lower() in ('.dll', '.exe', '.obj'):
                raise ValueError('Gameplay package must be Lua only')
            files.append(path)
    output.mkdir(parents=True)
    package = output / 'Carrier Navigator'
    for path in files:
        target = package / path.relative_to(ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
    runtime = output / 'SDK'
    runtime.mkdir()
    for name in ('dinput8.dll', 'dinput8.build.json'):
        shutil.copy2(sdk / 'dist' / name, runtime / name)
    shutil.copy2(sdk / 'LICENSE', runtime / 'LICENSE')
    result = {'schema': 1, 'version': version, 'validation': 'local-test-candidate',
              'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'source_dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True)),
              'sdk_sha256': build['artifact_sha256'], 'game_runtime_tested': False,
              'remote_multiplayer_tested': False, 'files': {
                  p.relative_to(output).as_posix(): sha(p) for p in output.rglob('*') if p.is_file()}}
    (output / 'BUILD_CHECK.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'candidate': str(output), 'files': len(result['files']), 'sdk_sha256': result['sdk_sha256']}))


if __name__ == '__main__':
    main()
