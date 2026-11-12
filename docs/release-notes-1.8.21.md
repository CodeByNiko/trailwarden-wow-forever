# Trailwarden 1.8.21

- Verify the pinned QuestieDB Forever 1.0.14 release archive against the official asset SHA-256 before extracting or executing provider code.
- Keep dependency-matrix validation checking that the digest step remains before extraction.

## Verification
- Confirmed the digest against the official release metadata and verified the downloaded archive locally.
- Automated scenario, engine, provider-contract, travel, localization, and replay checks pass.
- Provider integration, install-matrix validation, and package validation pass.
- A live World of Warcraft: Forever smoke test remains necessary for real client APIs and gameplay behavior.
