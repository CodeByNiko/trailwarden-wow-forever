# Trailwarden 1.8.8

## Changed

- Add pull-request CI integration against the pinned QuestieDB Forever 1.0.14 release, verifying the TOC version before exercising provider code.
- Pin the integration-test Python dependencies and guard that QuestieDB remains required while Questie and OpenMap remain optional.
- Document the automated installation matrix and add a structured in-game smoke log template for real Forever client checks.

## Verification

- Run the complete local check suite, installation-metadata check, and package validation.
- GitHub Actions runs the provider integration against the downloaded Forever release under Lua 5.1.
- The client smoke template is evidence to collect in the game; synthetic APIs do not count as a completed in-game test.
