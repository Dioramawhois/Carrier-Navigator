# SPDX-License-Identifier: GPL-3.0-or-later
"""Prepare a minimal Workshop payload and complete GitHub source. Never uploads."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PLAYER_FOLDER = 'Carrier Autopilot Waypoints'
ASSET_PREFIX = 'Carrier-Autopilot-Waypoints'
RUNTIME_FILES = (
    'content/bridge.json',
    'content/bridge/main.lua',
    'content/bridge/runtime.lua',
    'content/bridge/cruise.lua',
    'content/bridge/defence.lua',
    'content/scripts/library_custom_0.lua',
)
STEAM_FILES = ('mod.xml', 'LICENSE', *RUNTIME_FILES)
# The owner tested alpha.4 before choosing the public title. These literal
# presentation changes are the only permitted differences from that candidate.
BRANDING_REPLACEMENTS = {
    'content/bridge/main.lua': (
        (b"'Carrier Navigator requires the updated motion-enabled CC2X 0.10 test runtime'",
         b"'Carrier: Autopilot Waypoints requires the updated motion-enabled CC2X 0.10 test runtime'"),
        (b"'Carrier Navigator: native navigation, cruise control and team-contact defence ready'",
         b"'Carrier: Autopilot Waypoints: native navigation, cruise control and team-contact defence ready'"),
    ),
    'content/scripts/library_custom_0.lua': (
        (b"'CARRIER NAVIGATOR'", b"'AUTOPILOT WAYPOINTS'"),
    ),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def json_bytes(value):
    return (json.dumps(value, indent=2) + '\n').encode('utf-8')


def safe_name(name):
    path = PurePosixPath(name)
    if not name or '\\' in name or path.is_absolute() or '..' in path.parts or ':' in name:
        raise ValueError('Unsafe release path')
    return path


def branded_candidate(name, data):
    for before, after in BRANDING_REPLACEMENTS.get(name, ()):
        if data.count(before) != 1:
            raise ValueError('Expected branding literal missing or ambiguous: ' + name)
        data = data.replace(before, after)
    return data


def validate_payload(root, candidate, receipt, acceptance, *, authorized_beta=False):
    explicit_beta=(authorized_beta and acceptance.get('schema')==2 and
        acceptance.get('publication_authorized') is True and
        acceptance.get('kind')=='owner-authorized-beta' and
        acceptance.get('game_runtime_tested') is False)
    if ((acceptance.get('game_runtime_tested') is not True and not explicit_beta)
            or acceptance.get('candidate_source_commit') != receipt['source_commit']
            or acceptance.get('runtime_sha256') != receipt['sdk_sha256']):
        raise ValueError('Owner acceptance does not match the tested candidate/runtime')
    actual = set()
    for path in (root / 'content').rglob('*'):
        if path.is_symlink() or path.is_junction():
            raise ValueError('Linked content is not a release input')
        if path.is_file():
            actual.add(path.relative_to(root).as_posix())
    if actual != set(RUNTIME_FILES):
        raise ValueError('Unexpected or missing functional payload file')
    files = {}
    for name in STEAM_FILES:
        path = root / name
        if path.is_symlink() or path.is_junction():
            raise ValueError('Linked payload file')
        files[name] = path.read_bytes()
    for name in RUNTIME_FILES:
        key = 'Carrier Navigator/' + name
        accepted = (candidate / key).read_bytes()
        digest = sha(accepted)
        if (digest != receipt['files'][key]
                or digest != acceptance['functional_sha256'].get(name)):
            raise ValueError('Accepted candidate hash changed: ' + name)
        if files[name] != accepted and files[name] != branded_candidate(name, accepted):
            raise ValueError('Gameplay differs from the accepted candidate: ' + name)
    if files['LICENSE'] != (candidate / 'Carrier Navigator/LICENSE').read_bytes():
        raise ValueError('Accepted package license changed')
    bridge = json.loads(files['content/bridge.json'])
    if bridge != {'id': 'carrier_navigator', 'scripts': ['bridge/main.lua']}:
        raise ValueError('Private observer or unexpected entrypoint in release')
    return files


def validate_source_archive(payload):
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        names = [info.orig_filename for info in archive.infolist()]
        if len(names) != len(set(names)):
            raise ValueError('Duplicate source archive path')
        for name in names:
            path = safe_name(name)
            if path.parts[0] != 'Carrier-Navigator-source':
                raise ValueError('Unexpected source archive root')
            if any(part in {'.git', 'build', 'dist', 'research', '__pycache__'} for part in path.parts):
                raise ValueError('Private/generated folder in source archive')
            if path.suffix.lower() in {'.dll', '.exe', '.pdb', '.obj', '.pyc', '.log'}:
                raise ValueError('Binary/private artifact in source archive')
        required = {'tools/release.py', 'tests/runtime.lua', 'tests/ui.lua', 'README.md', 'LICENSE', *RUNTIME_FILES}
        if not {'Carrier-Navigator-source/' + name for name in required}.issubset(names):
            raise ValueError('Incomplete source archive')
    return names


def zip_files(files):
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            safe_name(name)
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    return output.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tested-candidate', type=Path, required=True)
    parser.add_argument('--acceptance', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--authorized-beta', action='store_true',
                        help='Use explicit owner beta-publication authorization without claiming game acceptance')
    args = parser.parse_args()
    candidate = args.tested_candidate.resolve(strict=True)
    output = args.output.resolve()
    if output.exists() or output.is_relative_to(candidate):
        raise ValueError('Use a new release output separate from the tested candidate')
    git = lambda *values: subprocess.check_output(['git', *values], cwd=ROOT)
    if git('status', '--porcelain').strip():
        raise ValueError('Commit release inputs before packaging')
    commit = git('rev-parse', 'HEAD').decode().strip()
    receipt = json.loads((candidate / 'BUILD_CHECK.json').read_text(encoding='utf-8'))
    acceptance = json.loads(args.acceptance.read_text(encoding='utf-8'))
    files = validate_payload(ROOT, candidate, receipt, acceptance,authorized_beta=args.authorized_beta)
    import xml.etree.ElementTree as ET
    version = ET.fromstring(files['mod.xml']).attrib['version']
    if not re.fullmatch(r'\d+\.\d+\.\d+-client-beta\.\d+', version):
        raise ValueError('Concrete client beta version required')
    tests = json.loads((ROOT / 'build/TEST_RESULTS.json').read_text(encoding='utf-8'))
    if tests.get('status') != 'passed' or tests['sdk_artifact_sha256'] != receipt['sdk_sha256']:
        raise ValueError('Matching passing offline fixtures required')
    for name, digest in tests['source_sha256'].items():
        safe_name(name)
        if sha((ROOT / name).read_bytes()) != digest:
            raise ValueError('Owned fixture/source changed since validation: ' + name)
    sources = git('archive', '--format=zip', '--prefix=Carrier-Navigator-source/', 'HEAD')
    source_names = validate_source_archive(sources)
    with zipfile.ZipFile(io.BytesIO(sources)) as archive:
        for name in RUNTIME_FILES:
            if archive.read('Carrier-Navigator-source/' + name) != files[name]:
                raise ValueError('Committed gameplay source differs from accepted bytes')
    player = zip_files({PLAYER_FOLDER + '/' + name: data for name, data in files.items()})
    branding = {name: {'accepted_sha256': acceptance['functional_sha256'][name],
            'release_sha256': sha(files[name])}
        for name in RUNTIME_FILES if sha(files[name]) != acceptance['functional_sha256'][name]}
    artwork = ROOT / 'workshop/artwork/cover.png'
    publication_status = 'prepared' if artwork.is_file() else 'awaiting-owner-images'
    metadata = {'schema': 1, 'release_tag': 'v' + version, 'version': version,
        'source_commit': commit, 'candidate_source_commit': receipt['source_commit'],
        'runtime_sha256': receipt['sdk_sha256'],
        'functional_payload_matches_accepted_candidate': not branding,
        'presentation_only_title_changes': branding,
        'accepted_gameplay_preserved': acceptance.get('game_runtime_tested') is True,
        'owner_authorized_beta': args.authorized_beta,
        'workshop_files': {name: sha(data) for name, data in sorted(files.items())},
        'workshop_file_count': len(files), 'source_file_count': len(source_names),
        'offline_scenarios': tests['scenarios'], 'runtime_acceptance': acceptance,
        'remote_multiplayer_supported': False, 'publication_status': publication_status,
        'owner_artwork_sha256': sha(artwork.read_bytes()) if artwork.is_file() else None}
    assets = {f'{ASSET_PREFIX}-{version}.zip': player,
        f'{ASSET_PREFIX}-{version}-source.zip': sources,
        'PLAYER_README.md': (ROOT / 'PLAYER_README.md').read_bytes(),
        'RELEASE.json': json_bytes(metadata)}
    assets['SHA256SUMS.txt'] = ''.join(sha(data) + '  ' + name + '\n'
        for name, data in sorted(assets.items())).encode('ascii')
    output.mkdir(parents=True)
    for name, data in files.items():
        target = output / 'steam' / PLAYER_FOLDER / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    for name, data in assets.items():
        target = output / 'github' / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    evidence = output / 'evidence'
    evidence.mkdir()
    (evidence / 'OFFLINE_TESTS.json').write_bytes(json_bytes(tests))
    (evidence / 'WORKSHOP_MANIFEST.json').write_bytes(json_bytes(metadata))
    print(json.dumps({'output': str(output), 'version': version, 'steam_files': len(files),
        'source_commit': commit, 'publication': publication_status}))


if __name__ == '__main__':
    main()
