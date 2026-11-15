#!/usr/bin/env python3
"""Asset/package invariants and actual Haxe command-state transitions; no device claims."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'docs/V2_ASSET_MANIFEST.json').read_text())
for entry in manifest['removed']:
    assert entry['path'].startswith('assets/base_game/'), entry
    assert not (ROOT / entry['path']).exists(), entry
assert sum(x['bytes'] for x in manifest['removed']) == manifest['removed_bytes']
for entry in manifest['protected']:
    assert hashlib.sha256((ROOT / entry['path']).read_bytes()).hexdigest() == entry['sha256'], entry
for entry in manifest['relocated']:
    assert not (ROOT / entry['from']).exists(), entry
    assert hashlib.sha256((ROOT / entry['to']).read_bytes()).hexdigest() == entry['sha256'], entry
weeks = ROOT / 'assets/base_game/shared/weeks'
assert sorted(p.name for p in weeks.glob('*.json')) == ['tutorial.json']
assert (ROOT / 'assets/shared/weeks/weekList.txt').read_text().split() == ['tutorial']
for chart in ('tutorial', 'tutorial-easy', 'tutorial-hard', 'events'):
    json.loads((ROOT / f'assets/base_game/shared/data/tutorial/{chart}.json').read_text())
for suffix in ('ogg', 'mp3'):
    for part in ('Inst', 'Voices-Player', 'Voices-Opponent'):
        assert (ROOT / f'assets/base_game/songs/tutorial/{part}.{suffix}').stat().st_size > 0
files = [p for p in (ROOT / 'assets').rglob('*') if p.is_file()]
assert {'files': len(files), 'bytes': sum(p.stat().st_size for p in files)} == manifest['source_assets_after']

with tempfile.TemporaryDirectory(prefix='psych-v2-') as directory:
    work = Path(directory)
    target = work / 'backend/ui'
    target.mkdir(parents=True)
    shutil.copyfile(ROOT / 'source/backend/ui/EditorKeyState.hx', target / 'EditorKeyState.hx')
    (work / 'Commands.hx').write_text('''
import backend.ui.EditorKeyState;
class Commands {
 static var assertions=0;
 static function check(ok:Bool) { assertions++; if(!ok) throw 'command transition '+assertions; }
 static function main() {
  var keys=new EditorKeyState();
  keys.beginFrame(); check(!keys.pressed(37));check(!keys.justReleased(37));
  keys.hold(37);keys.hold(37); check(keys.pressed(37));check(keys.justPressed(37));
  keys.beginFrame();keys.hold(37); check(keys.pressed(37));check(!keys.justPressed(37));
  keys.repeat(37);check(keys.justPressed(37));
  keys.beginFrame();keys.hold(37);check(!keys.justPressed(37));
  keys.hold(17);keys.hold(67);check(keys.justPressed(17)&&keys.justPressed(67));
  keys.beginFrame();keys.hold(37);check(keys.justReleased(17)&&keys.justReleased(67));
  keys.beginFrame();check(keys.justReleased(37));check(!keys.pressed(37));
  keys.beginFrame();check(!keys.justReleased(37));
  keys.hold(40);keys.hold(17);keys.clear();check(!keys.pressed(40)&&!keys.pressed(17));
  check(!keys.justReleased(40)&&!keys.justPressed(40));
  keys.beginFrame();keys.hold(40);check(keys.justPressed(40));
  keys.clear();keys.beginFrame();check(!keys.pressed(40)&&!keys.justReleased(40));
  Sys.println('PASS: '+assertions+' command-state assertions (press, repeat, combos, cancel, re-entry)');
 }
}''')
    subprocess.run(['haxe', '-cp', str(work), '-main', 'Commands', '--interp'], check=True)
    # Exercise the real compile-time validator, including both expected failure paths.
    (work / 'Empty.hx').write_text('class Empty {static function main() {}}')
    command = ['haxe', '-cp', str(work), '-cp', str(ROOT / 'source'), '--macro',
               'backend.LiteAssets.validate()', '-main', 'Empty', '--interp']
    subprocess.run(command, cwd=ROOT, check=True)
    (work / 'docs').mkdir()
    (work / 'docs/V2_ASSET_MANIFEST.json').write_text(json.dumps(manifest))
    failure = subprocess.run(command, cwd=work, capture_output=True, text=True)
    assert failure.returncode != 0 and 'Missing Lite asset:' in failure.stderr, failure.stderr
    entry = manifest['protected'][0]
    destination = work / entry['path']
    destination.parent.mkdir(parents=True)
    destination.write_text('changed asset')
    failure = subprocess.run(command, cwd=work, capture_output=True, text=True)
    assert failure.returncode != 0 and 'Protected Lite asset changed:' in failure.stderr, failure.stderr
print(f"PASS: {len(manifest['removed'])} deletions, protected Tutorial/relocations, built-in week list, exact source bytes, build validator")
print('Android touch, IME, SAF providers, gameplay/mod runtime, FPS and RAM: UNTESTED on device')
