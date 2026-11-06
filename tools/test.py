"""Compile a real Lua runner from hash-verified external SDK sources; no game access."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--zig', type=Path, required=True)
    args = parser.parse_args()
    sdk = args.sdk.resolve(strict=True)
    zig = args.zig.resolve(strict=True)
    build = ROOT / 'build'
    build.mkdir(exist_ok=True)
    output = build / 'TEST_RESULTS.json'
    output.unlink(missing_ok=True)
    evidence = json.loads((sdk / 'dist/dinput8.build.json').read_text())
    if sha(zig) != evidence['compiler_sha256']:
        raise ValueError('Compiler differs from the external SDK build')
    lua = sdk / 'third_party/lua'
    dependency_hashes = {}
    sources = [p for p in sorted(lua.glob('*.c'))
               if p.relative_to(sdk).as_posix() in evidence['source_sha256']]
    for path in [*sources, *sorted(lua.glob('*.h'))]:
        name = path.relative_to(sdk).as_posix()
        digest = sha(path)
        if evidence['source_sha256'].get(name) != digest:
            raise ValueError('Lua source differs from external SDK build: ' + name)
        dependency_hashes[name] = digest
    if len(sources) < 30:
        raise ValueError('Incomplete external Lua sources')
    inputs = [*sorted((ROOT / 'content').rglob('*.lua')),
              *sorted((ROOT / 'tests').rglob('*.lua')), ROOT / 'tests/lua_runner.c',
              Path(__file__).resolve()]
    hashes = {p.relative_to(ROOT).as_posix(): sha(p) for p in inputs}
    runner = build / 'lua-policy-tests.exe'
    env = dict(os.environ, ZIG_GLOBAL_CACHE_DIR=str(build / 'zig-cache'))
    subprocess.run([str(zig), 'cc', '-target', 'x86-windows-gnu', '-O1', '-UNDEBUG',
                    '-I', str(lua), str(ROOT / 'tests/lua_runner.c'),
                    *map(str, sources), '-o', str(runner)], check=True, env=env)
    scenarios = 0
    for name in ('navigation', 'defence'):
        policy = ROOT / 'content/bridge' / (name + '.lua')
        fixture = ROOT / 'tests' / (name + '.lua')
        if not policy.is_file() or not fixture.is_file():
            raise ValueError('Missing policy/fixture: ' + name)
        result = subprocess.run([str(runner), str(policy), str(fixture)],
                                capture_output=True, text=True, timeout=30)
        print(result.stdout, end='')
        if result.returncode:
            print(result.stderr, end='')
            raise SystemExit(result.returncode)
        marker = [line for line in result.stdout.splitlines() if line.startswith('SCENARIOS ')]
        if len(marker) != 1:
            raise ValueError('Missing scenario count: ' + name)
        scenarios += int(marker[0].split()[1])
    negative_controls = []
    mutations = [
        ('navigation', "if f.manual then return release('manual_control', false) end",
         "if false then return release('manual_control', false) end", 'manual_takeover_removed'),
        ('defence', '(c.radar == true or c.visual == true)',
         '(c.radar == true and c.visual == true)', 'radar_visual_or_replaced_with_and'),
    ]
    with tempfile.TemporaryDirectory(prefix='negative-controls-', dir=build) as temporary:
        for name, before, after, label in mutations:
            original = (ROOT / 'content/bridge' / (name + '.lua')).read_text(encoding='utf-8')
            if original.count(before) != 1:
                raise ValueError('Negative control anchor changed: ' + label)
            mutant = Path(temporary) / (name + '.lua')
            mutant.write_text(original.replace(before, after), encoding='utf-8')
            rejected = subprocess.run([str(runner), str(mutant), str(ROOT / 'tests' / (name + '.lua'))],
                                      capture_output=True, text=True, timeout=30)
            if rejected.returncode == 0 or 'assertion failed' not in rejected.stderr:
                raise ValueError('Regression fixture did not reject the broken policy: ' + label)
            negative_controls.append(label)
    if (hashes != {p.relative_to(ROOT).as_posix(): sha(p) for p in inputs}
            or dependency_hashes != {name: sha(sdk / name) for name in dependency_hashes}):
        raise ValueError('Sources changed during validation')
    report = {'schema': 1, 'status': 'passed', 'scenarios': scenarios,
              'validation': 'owned-policy-real-lua-synthetic-telemetry',
              'source_sha256': hashes, 'runner_sha256': sha(runner),
              'compiler_sha256': sha(zig), 'lua_source_sha256': dependency_hashes,
              'sdk_artifact_sha256': evidence['artifact_sha256'],
              'negative_controls_rejected': negative_controls,
              'game_runtime_tested': False, 'remote_multiplayer_tested': False,
              'native_controls_connected': False, 'save_hook_connected': False}
    output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'{scenarios} scenarios passed; game integration is not yet connected')


if __name__ == '__main__':
    main()
