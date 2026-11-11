# Trailwarden 1.8.13

## Changed

- Refactor the addon runtime into focused modules: `Core.lua` handles events and decision publication, `Diagnostics.lua` builds explanations/reports, and `Commands.lua` handles slash commands.
- Preserve the public slash commands and their behavior while making module boundaries and TOC load order explicit.

## Verification

- Full scenario, engine, provider-contract, travel, localization, feedback, and replay checks pass after the refactor.
- Installation dependency and release-consistency checks pass; package builds as `Trailwarden-1.8.13-Forever.zip`.
