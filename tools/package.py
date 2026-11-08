"""Create a reproducible, directly installable Wayfinder archive."""
from pathlib import Path
import os
import re
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
addon = root / 'Wayfinder'
toc = (addon / 'Wayfinder.toc').read_text()
version = re.search(r'^## Version: (\d+\.\d+\.\d+)$', toc, re.M).group(1)
for entry in toc.splitlines():
    entry = entry.strip()
    if entry and not entry.startswith('#') and not (addon / entry).is_file():
        raise SystemExit(f'Missing TOC dependency: {entry}')
if not (addon / 'Media/Arrow.tga').is_file():
    raise SystemExit('Missing navigator texture')
output = root / 'artifacts' / f'Wayfinder-{version}-Forever.zip'
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
    assert 'Wayfinder/Wayfinder.toc' in archive.namelist()
    assert all(name.startswith('Wayfinder/') and '..' not in name for name in archive.namelist())
print(output)
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
        file.write(f'version={version}\nasset={output}\n')
