"""Fail release checks when addon version, changelog, and release notes drift."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
toc = (root / 'Trailwarden' / 'Trailwarden.toc').read_text()
common = (root / 'Trailwarden' / 'Common.lua').read_text()
changelog = (root / 'Trailwarden' / 'CHANGELOG.md').read_text()
toc_match = re.search(r'^## Version: (\d+\.\d+\.\d+)$', toc, re.M)
common_match = re.search(r'^W\.Version\s*=\s*["\'](\d+\.\d+\.\d+)["\']', common, re.M)
if not toc_match or not common_match:
    raise SystemExit('Could not read a release version from the TOC and Common.lua.')
version = toc_match.group(1)
if common_match.group(1) != version:
    raise SystemExit(f'Version mismatch: TOC={version}, Common.lua={common_match.group(1)}.')
headings = re.findall(r'^## (\d+\.\d+\.\d+)\s*$', changelog, re.M)
if not headings or headings[0] != version:
    raise SystemExit(f'The changelog must start with the current version {version}.')
if len(headings) != len(set(headings)):
    raise SystemExit('The changelog contains duplicate version headings.')
notes_path = root / 'docs' / f'release-notes-{version}.md'
if not notes_path.is_file():
    raise SystemExit(f'Missing release notes: {notes_path.relative_to(root)}.')
notes = notes_path.read_text()
if not notes.startswith(f'# Trailwarden {version}\n') or '## Verification' not in notes:
    raise SystemExit(f'Release notes for {version} need a matching title and verification section.')
package_readme = (root / 'Trailwarden' / 'README.md').read_text()
package_readme_text = (root / 'Trailwarden' / 'README.txt').read_text()
if f'## Current release: {version}' not in package_readme:
    raise SystemExit(f'Bundled README.md must identify current release {version}.')
if not package_readme_text.startswith(f'TRAILWARDEN {version} — WORLD OF WARCRAFT: FOREVER'):
    raise SystemExit(f'Bundled README.txt must identify current release {version}.')
description = (root / 'docs' / 'curseforge-description.md').read_text()
if re.search(r"(?:what's new|new in)\s+(?:in\s+)?1\.[0-7](?:\.|\b)", description, re.I):
    raise SystemExit('CurseForge description contains a stale release-specific heading.')
print(f'Release documentation is consistent for Trailwarden {version}.')
