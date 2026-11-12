# Trailwarden 1.8.20

- Show the required in-game transport guidance before a cave entrance when the cave is on another continent.
- Preserve the “Travel connection needed” navigator state until the player reaches the destination continent.

## Verification
- Added a navigation regression proving cross-continent transit guidance overrides the cave approach instruction while keeping the cave entrance route intact.
- Automated scenario, engine, provider-contract, travel, localization, and replay checks pass.
- Provider integration, install-matrix validation, and package validation pass.
- Actual continent transport remains a live-client behavior and needs an in-game smoke test.
