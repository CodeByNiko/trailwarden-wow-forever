"""Create a reproducible, directly installable Trailwarden archive."""
from pathlib import Path
import os
import re
import subprocess
import sys
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
addon = root / 'Trailwarden'
toc = (addon / 'Trailwarden.toc').read_text()
match = re.search(r'^## Version: (\d+\.\d+\.\d+)$', toc, re.M)
if not match:
    raise SystemExit('Unreleased development version: finish release prerequisites before packaging.')
version = match.group(1)
subprocess.run([sys.executable, str(root / 'tools' / 'check_release_consistency.py')], cwd=root, check=True)
for entry in toc.splitlines():
    entry = entry.strip()
    if entry and not entry.startswith('#') and not (addon / entry).is_file():
        raise SystemExit(f'Missing TOC dependency: {entry}')
if not (addon / 'Media/Arrow.tga').is_file():
    raise SystemExit('Missing navigator texture')
output = root / 'artifacts' / f'Trailwarden-{version}-Forever.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output, 'w', compression=ZIP_DEFLATED) as archive:
    for path in sorted(addon.rglob('*')):
        if path.is_file() and path.suffix in {'.lua', '.toc', '.txt', '.md', '.tga'}:
            info = ZipInfo(path.relative_to(root).as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert 'Trailwarden/Trailwarden.toc' in archive.namelist()
    assert all(name.startswith('Trailwarden/') and '..' not in name for name in archive.namelist())
print(output)
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
        file.write(f'version={version}\nasset={output}\n')

