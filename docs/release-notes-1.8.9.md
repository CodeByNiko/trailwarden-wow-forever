# Trailwarden 1.8.9

## Changed

- Refresh the README and CurseForge description so they describe the 1.8 routing, safety, XP, and provider-validation improvements without presenting older 1.7 notes as current.
- Replace the validation page's stale headline and commands with the current local/CI process, installation matrix, and explicit in-game evidence limits.
- Remove duplicate changelog headings and use neutral version placeholders in the publishing guide.
- Add a release consistency check for the TOC, runtime version, changelog, and versioned release notes; run it before tests and package creation.

## Verification

- The consistency check rejects mismatched versions, missing/mistitled notes, duplicate changelog headings, and stale release-specific CurseForge headings.
- The check runs through both `python3 tools/check.py` and `python3 tools/package.py`.
