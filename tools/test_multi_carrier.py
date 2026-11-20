"""Run explicit owned Lua fixtures in the existing restricted Lua test runner."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
RUNNER_HASH = '20ab8facc112dcff805bcfc6c707255b888782d9d30bc8d5edecf1bd3785f5f7'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--regressions-only', action='store_true')
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    runner = ROOT / 'build/lua-policy-tests.exe'
    if sha(runner) != RUNNER_HASH:
        receipt_path=ROOT/'build/TEST_RESULTS.json'
        receipt=json.loads(receipt_path.read_text(encoding='utf-8')) if receipt_path.is_file() else {}
        if (receipt.get('status')!='passed' or receipt.get('runner_sha256')!=sha(runner)
                or receipt.get('source_sha256',{}).get('tests/lua_runner.c')!=sha(ROOT/'tests/lua_runner.c')):
            raise ValueError('Build and verify the owned runner with tools/test.py first')
    runner_hash=sha(runner)
    base = args.baseline.resolve() if args.baseline else ROOT
    def source(relative):
        return (base / relative).read_text(encoding='utf-8')
    runtime = ''
    for name in ('Cruise', 'Defence', 'Runtime'):
        runtime += 'local '+name+'=(function()\n'+source('content/bridge/'+name.lower()+'.lua')+'\nend)()\n'
    policies = {
        'multi_carrier_runtime': runtime+'return {new=function(cc2)return Runtime.new(cc2,Cruise,Defence)end}\n',
        'runtime': runtime+'return {new=function(cc2)return Runtime.new(cc2,Cruise,Defence)end}\n',
        'ui': (ROOT/'tests/ui_setup.lua').read_text(encoding='utf-8')+'\n'+source('content/scripts/library_custom_0.lua'),
        'multi_carrier_ui': (ROOT/'tests/multi_carrier_ui_setup.lua').read_text(encoding='utf-8')+'\n'+source('content/scripts/library_custom_0.lua'),
        'entry': 'return function()\n'+source('content/scripts/library_custom_0.lua')+'\nend\n',
        'main': (ROOT/'tests/main_setup.lua').read_text(encoding='utf-8')+'\n'+source('content/bridge/main.lua'),
        'defence': source('content/bridge/defence.lua'),
        'cruise': 'local reference=(function()\n'+(ROOT/'tests/fixtures/native_cruise_0_1_0.lua').read_text(encoding='utf-8')+
            '\nend)()\nlocal current=(function()\n'+source('content/bridge/cruise.lua')+
            '\nend)()\ncurrent.native_reference=reference.new\nreturn current\n',
    }
    selected = ['multi_carrier_runtime', 'multi_carrier_ui'] if args.regressions_only else list(policies)
    results = []
    for name in selected:
        policy = output / (name+'-policy.lua')
        policy.write_text(policies[name], encoding='utf-8')
        fixture = ROOT / 'tests' / (name+'.lua')
        process = subprocess.run([str(runner), str(policy), str(fixture)], capture_output=True,
            text=True, timeout=30, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        (output/(name+'.log')).write_text(process.stdout+process.stderr, encoding='utf-8')
        markers = [line for line in process.stdout.splitlines() if line.startswith('SCENARIOS ')]
        results.append({'name': name, 'exit_code': process.returncode, 'passed': process.returncode==0,
            'scenarios': int(markers[0].split()[1]) if len(markers)==1 else None,
            'fixture_sha256': sha(fixture), 'policy_sha256': sha(policy)})
        print(name+': '+('PASS' if process.returncode==0 else 'FAIL'))
        if process.returncode:
            print(process.stderr[:1800])
    passed = all(item['passed'] for item in results)
    report = {'status': 'passed' if passed else 'failed', 'results': results,
        'scenarios': sum(item['scenarios'] or 0 for item in results), 'runner_sha256': runner_hash,
        'baseline': str(base), 'validation': 'owned-lua-policies-and-synthetic-ports',
        'game_started': False, 'multiplayer_runtime_tested': False,
        'source_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in
            [*sorted((ROOT/'content').rglob('*.lua')), *sorted((ROOT/'tests').rglob('*.lua')), Path(__file__)]}}
    (output/'RESULTS.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    if not passed:
        raise SystemExit(1)
    print(str(report['scenarios'])+' owned scenarios passed')


if __name__ == '__main__':
    main()
