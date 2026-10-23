"""Verify committed Godot Web artifacts match the source used for export."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'godot'
EXPORT = ROOT / 'web' / 'play'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def sources():
    return {str(p.relative_to(ROOT)): digest(p) for p in sorted(SOURCE.rglob('*'))
            if p.is_file() and '.godot' not in p.relative_to(SOURCE).parts}

def artifacts():
    required = ['index.html', 'index.js', 'index.wasm', 'index.pck',
                'index.png', 'index.icon.png', 'index.apple-touch-icon.png',
                'index.audio.worklet.js', 'index.audio.position.worklet.js']
    for name in required:
        if not (EXPORT / name).is_file() or (EXPORT / name).stat().st_size == 0:
            raise SystemExit(f'Missing Web export: {name}. Run tools/export_web.sh.')
    if (EXPORT / 'index.wasm').read_bytes()[:4] != b'\0asm':
        raise SystemExit('The WebAssembly artifact is invalid.')
    return {name: digest(EXPORT / name) for name in required}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    current = {'godot': '4.6.3.stable', 'threaded': False,
               'source': sources(), 'export': artifacts()}
    path = EXPORT / 'build.json'
    if args.write:
        path.write_text(json.dumps(current, indent=2) + '\n')
        print('Godot Web build manifest saved.')
    elif not path.exists() or json.loads(path.read_text()) != current:
        raise SystemExit('Godot source/export mismatch. Run tools/export_web.sh before deployment.')
    else:
        print('Godot Web export and source hashes verified.')
