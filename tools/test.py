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
    parser.add_argument('--legacy-sdk', type=Path, help='Also test the provenance-verified older SDK Lua facade')
    args = parser.parse_args()
    sdk = args.sdk.resolve(strict=True)
    zig = args.zig.resolve(strict=True)
    build = ROOT / 'build'
    build.mkdir(exist_ok=True)
    output = build / 'TEST_RESULTS.json'
    output.unlink(missing_ok=True)
    evidence = json.loads((sdk / 'dist/dinput8.build.json').read_text())
    sdk_tests = json.loads((sdk / 'build/unified/test-results.json').read_text())
    if sdk_tests['status'] != 'passed' or sdk_tests['artifact_sha256'] != evidence['artifact_sha256']:
        raise ValueError('Matching passing SDK tests are required')
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
    runtime_source = ''
    for name in ('Cruise', 'Defence', 'Runtime'):
        source = (ROOT / 'content/bridge' / (name.lower()+'.lua')).read_text(encoding='utf-8')
        runtime_source += f'local {name} = (function()\n{source}\nend)()\n'
    runtime_policy = build / 'runtime-test.lua'
    runtime_policy.write_text(runtime_source+'return {new=function(cc2) return Runtime.new(cc2,Cruise,Defence) end}\n', encoding='utf-8')
    cruise_policy = build / 'cruise-test.lua'
    cruise_policy.write_text('local reference=(function()\n'+
        (ROOT/'tests/fixtures/native_cruise_0_1_0.lua').read_text(encoding='utf-8')+
        '\nend)()\nlocal current=(function()\n'+
        (ROOT/'content/bridge/cruise.lua').read_text(encoding='utf-8')+
        '\nend)()\ncurrent.native_reference=reference.new\nreturn current\n', encoding='utf-8')
    ui_policy = build / 'ui-test.lua'
    ui_policy.write_text((ROOT / 'tests/ui_setup.lua').read_text(encoding='utf-8')+'\n'+
                         (ROOT / 'content/scripts/library_custom_0.lua').read_text(encoding='utf-8'), encoding='utf-8')
    entry_policy = build / 'entry-test.lua'
    entry_policy.write_text('return function()\n'+(ROOT / 'content/scripts/library_custom_0.lua').read_text(encoding='utf-8')+'\nend\n', encoding='utf-8')
    main_policy = build / 'main-test.lua'
    main_policy.write_text((ROOT / 'tests/main_setup.lua').read_text(encoding='utf-8')+'\n'+
                           (ROOT / 'content/bridge/main.lua').read_text(encoding='utf-8'), encoding='utf-8')
    for name in ('defence', 'cruise', 'runtime', 'ui', 'entry', 'main'):
        policy = runtime_policy if name=='runtime' else cruise_policy if name=='cruise' else ui_policy if name=='ui' else entry_policy if name=='entry' else main_policy if name=='main' else ROOT / 'content/bridge' / (name + '.lua')
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
    facade_results = []
    for facade_sdk in (sdk, *([args.legacy_sdk.resolve(strict=True)] if args.legacy_sdk else [])):
        facade_path=facade_sdk/'sdk/cc2.lua'
        facade_build=json.loads((facade_sdk/'dist/dinput8.build.json').read_text())
        facade_hash=sha(facade_path)
        if facade_build['source_sha256'].get('sdk/cc2.lua') != facade_hash:
            raise ValueError('SDK facade differs from its build provenance')
        facade_policy=build/'sdk-facade-test.lua'
        facade_policy.write_text('local sdk=(function()\n'+facade_path.read_text(encoding='utf-8')+
            '\nend)()\n'+runtime_source+
            "local function require(name)\nif name=='cc2'then return sdk\n"+
            "elseif name=='bridge.runtime'then return Runtime\nelseif name=='bridge.cruise'then return Cruise\n"+
            "elseif name=='bridge.defence'then return Defence end\nerror(name)\nend\n"+
            'return {sdk=sdk,entry=function()\n'+(ROOT/'content/bridge/main.lua').read_text(encoding='utf-8')+
            '\nend}\n',encoding='utf-8')
        result=subprocess.run([str(runner),str(facade_policy),str(ROOT/'tests/sdk_facade.lua')],
                              capture_output=True,text=True,timeout=30)
        print(result.stdout,end='')
        if result.returncode:
            print(result.stderr,end='');raise SystemExit(result.returncode)
        marker=[line for line in result.stdout.splitlines() if line.startswith('SCENARIOS ')]
        if len(marker)!=1 or sha(facade_path)!=facade_hash:raise ValueError('Invalid facade test evidence')
        scenarios+=int(marker[0].split()[1])
        facade_results.append({'facade_sha256':facade_hash,'sdk_artifact_sha256':facade_build['artifact_sha256'],
                               'scenarios':int(marker[0].split()[1]),'validation':'real-sdk-lua-facade-synthetic-native-callbacks'})
    negative_controls = []
    mutations = [
        ('runtime', 'if motion.manual or s.was_active',
         'if false or s.was_active', 'manual_takeover_removed'),
        ('defence', '(c.detected == true or c.radar == true or c.visual == true)',
         '(c.detected == true or c.radar == true and c.visual == true)', 'radar_visual_or_replaced_with_and'),
        ('runtime', 'precise=current~=0 and navigation_available()',
         'precise=current~=0', 'optional_sdk_forced_on_legacy'),
        ('runtime', 'if not precise then',
         'if not precise or not navigation_available() then', 'coastal_failure_switches_to_native'),
    ]
    with tempfile.TemporaryDirectory(prefix='negative-controls-', dir=build) as temporary:
        for name, before, after, label in mutations:
            original = (runtime_policy if name == 'runtime' else ROOT / 'content/bridge' / (name + '.lua')).read_text(encoding='utf-8')
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
              'sdk_facades_tested':facade_results,
              'negative_controls_rejected': negative_controls,
              'game_runtime_tested': False, 'remote_multiplayer_tested': False,
              'runtime_adapter_tested': True, 'native_saved_route': True}
    output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'{scenarios} scenarios passed; real game acceptance is separate')


if __name__ == '__main__':
    main()
