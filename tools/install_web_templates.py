"""Install the matching official Web templates after checking SHA-512.

The upstream archive contains all platforms (~1.2 GB); only Web files are retained.
"""
import hashlib
import os
from pathlib import Path
import urllib.request
import zipfile

VERSION = '4.6.3'
RELEASE = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable'
NAME = f'Godot_v{VERSION}-stable_export_templates.tpz'
ROOT = Path(__file__).resolve().parent.parent
CLOUD = str(ROOT).startswith('/workspace/')
CACHE = Path('/workspace/.cache/godot') if CLOUD else Path.home() / '.cache' / 'hospital-godot'
DATA = Path(os.environ.get('XDG_DATA_HOME', '/workspace/.cache/godot/data' if CLOUD else str(Path.home() / '.local/share')))

if __name__ == '__main__':
    CACHE.mkdir(parents=True, exist_ok=True)
    archive = CACHE / 'templates.tpz'
    # Fetch the official checksum over verified HTTPS; do not disable TLS.
    with urllib.request.urlopen(f'{RELEASE}/SHA512-SUMS.txt') as response:
        sums = response.read().decode()
    expected = next(line.split()[0] for line in sums.splitlines() if line.endswith(NAME))
    if not archive.exists():
        print('Downloading official Godot export templates (~1.2 GB)...', flush=True)
        partial = archive.with_suffix('.partial')
        with urllib.request.urlopen(f'{RELEASE}/{NAME}') as response, partial.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
        partial.rename(archive)
    with archive.open('rb') as source:
        actual = hashlib.file_digest(source, 'sha512').hexdigest()
    if actual != expected:
        raise SystemExit('SHA-512 mismatch. Do not use this archive; remove it and retry from the official source.')
    target = DATA / 'godot' / 'export_templates' / f'{VERSION}.stable'
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as source:
        for name in ['web_nothreads_release.zip', 'web_nothreads_debug.zip']:
            entry = next(item for item in source.namelist() if Path(item).name == name)
            (target / name).write_bytes(source.read(entry))
    print(f'Official SHA-512 verified. Web templates installed in {target}')
