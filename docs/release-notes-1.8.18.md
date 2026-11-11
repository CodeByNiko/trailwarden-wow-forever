# Trailwarden 1.8.18

- Preserve the matched live quest objective text in monster and item guidance.
- Keep provider target names and item acquisition steps while adding the player's current objective wording.

## Verification
- Added rendering regressions for the live “Forest creature: 1/4” monster row and “Supply pack: 0/1” item row.
- Automated scenario, engine, provider-contract, travel, localization, and replay checks pass.
- Provider integration, install-matrix validation, and package validation pass.
- A live World of Warcraft: Forever smoke test remains necessary for localized in-game wording.
