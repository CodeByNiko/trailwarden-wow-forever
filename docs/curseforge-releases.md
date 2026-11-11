# CurseForge publishing

Project: https://www.curseforge.com/wow/addons/trailwarden (ID 1792839).
Repository: https://github.com/CodeByNiko/trailwarden-wow-forever.

## Source configuration

Use GitHub as the source and package **tagged commits only**. The Source setting
does not create a GitHub webhook. A separate repository push webhook must point
to CurseForge's package endpoint using a CurseForge API token. Never commit that
token or the complete webhook URL to this public repository.

Only tag a verified commit from main. Tags containing `beta` produce beta files;
plain version tags produce release files. Keep public testing builds in the beta
channel, for example `v1.7.5-beta.1`. The addon TOC version remains `1.7.5`.
Do not move or reuse an already published tag.

The GitHub release workflow defaults to `v<TOC version>-beta` tags and GitHub
prereleases after main passes its checks. The manual workflow's `release` channel
creates a plain version tag for a deliberate stable release. The job only runs
on main. Existing tags/releases are retained, not overwritten. Do not assume the
Source setting changes tag classification.

## Package contents and version checklist

`.pkgmeta` flattens the repository's nested addon directory and uses the bundled
`Trailwarden/CHANGELOG.md` as the CurseForge changelog. Development files remain
outside the installable package. `required-dependencies` declares `questiedb`; the
project Default Relations must also retain QuestieDB as Required Dependency.
Default Relations do not retrofit existing files: inspect the file-specific
Related Projects section when repairing an already published package. No external libraries or quest databases are
downloaded into it.

For each release, update the TOC, bundled README/version references, changelog,
root and bundled README highlights, and `docs/release-notes-<version>.md` together.
Run `python3 tools/check.py` and `python3 tools/package.py`; required PR checks
must pass before merge.

After the CurseForge build, verify:

- The ZIP contains `Trailwarden/Trailwarden.toc` directly and includes its media.
- TOC version matches the intended release; supported game version is Forever
  1.60.1 / Interface 16001, not an unrelated Retail or Classic client.
- File type is Beta during public testing and the changelog matches the build.
- The file is approved/published before calling it available on CurseForge.

Check the GitHub webhook delivery and CurseForge Builds when tags do not appear.
Existing tags are not automatically replayed when a new webhook is installed.

References:
- https://support.curseforge.com/support/solutions/articles/9000197281
- https://support.curseforge.com/support/solutions/articles/9000203228

Optional real-provider check (developer dependencies only): install `lupa` and
`cbor2`, extract the official QuestieDB Forever ZIP, then run
`python3 tools/check_provider.py /path/to/QuestieDB`. It checks actual provider
code/data with synthetic client APIs; it does not replace in-game testing.
