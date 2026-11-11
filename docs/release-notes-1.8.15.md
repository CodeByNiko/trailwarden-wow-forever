# Trailwarden 1.8.15

- Refresh the full quest panel when navigation enters an unavailable state or recovers, so the title, controls, progress, and queue match the active route.
- Keep ordinary distance and instruction updates on the lighter live-render path.

## Verification
- Added UI integration checks for an access failure and recovery first observed during the periodic navigation update.
- Automated scenario, engine, provider-contract, travel, localization, and replay checks pass.
- Provider integration, install-matrix validation, and package validation pass.
- A live World of Warcraft: Forever smoke test remains necessary for in-game rendering behavior.
