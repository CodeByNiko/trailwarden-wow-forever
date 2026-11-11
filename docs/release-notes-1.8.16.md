# Trailwarden 1.8.16

- Use only medium-confidence quest-cycle projections to build the reference XP rate used for route normalization.
- Keep low-confidence reward guesses from distorting comparisons between reliable candidates.

## Verification
- Added a mixed-confidence regression where uncertain reward values change by four orders of magnitude while the reliable route's normalization remains stable.
- Automated scenario, engine, provider-contract, travel, localization, and replay checks pass.
- Provider integration, install-matrix validation, and package validation pass.
- A live World of Warcraft: Forever smoke test remains necessary for in-game behavior.
