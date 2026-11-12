# Trailwarden 1.8.17

- Match text against all provider entities before applying claimed-ID constraints, so a long name such as “Dire Wolf” cannot be mistaken for the shorter “Wolf”.
- Leave conflicting objective identity unresolved instead of assigning finished progress to another target.

## Verification
- Added the reported mixed ID/text regression with a generic ID-matched row and a completed long-name row.
- Automated scenario, engine, provider-contract, travel, localization, and replay checks pass.
- Provider integration, install-matrix validation, and package validation pass.
- A live World of Warcraft: Forever smoke test remains necessary for in-game objective text behavior.
