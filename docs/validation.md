# Validation process and client evidence

## Automated release checks

Run `python3 tools/check.py` for installation-metadata checks, scenario/client simulations, pure route-engine checks, provider/client contracts, XP accounting, combat safety, travel, and replay verification. The local Lua runner uses Lua 5.4 with the compatibility layer; GitHub Actions repeats the suites under Lua 5.1.

Every feature pull request also runs `python3 tools/check_install_matrix.py`, the installable package validator, and an integration check against the pinned QuestieDB Forever release. The integration loads real provider code and data under Lua 5.1 while client APIs, position, and objective counts remain synthetic. It is not a live-client test.

Use [the installation matrix](installation-matrix.md) to see which suite covers each addon combination. Use [the client smoke log template](client-smoke-template.md) to record the actual Forever build, installed addon versions, route behavior, and visual outcome. Keep that evidence separate from automated test results.

The package builder checks TOC dependencies, required media, ZIP CRCs, and a single `Trailwarden/` root. Repeated builds from identical inputs must be byte-identical.

## Recorded evidence limits

No automated scenario establishes real terrain connectivity, accurate transport routing, real fonts, in-game event timing, phase placement, or successful live cave navigation. Synthetic scenarios and provider contracts cannot replace testing in the actual Forever client. Do not mark a client smoke check as passed without running it in game.

Historic feature-branch snapshots follow. Their counts and runtime notes describe those earlier branches, not the current release process.

## Archived: Validation for 1.7.3

The 1.7.3 feature branch recorded 440 checks and 40 replay frames under its then-current local and CI runners. It covered bounded quest-cycle optimization, objective refresh, panel layout scenarios, tooltip behavior, XP estimates, and navigation decision consistency. Those counts are a historical snapshot.

The branch used synthetic frame renders and did not establish live Forever behavior. The current commands and client evidence requirements are described above.

## Archived: Validation for 1.7.1

The 1.7.1 branch added three replay frames for cave collection, last-item persistence, and local-work release. Its scenarios used synthetic client data and did not establish successful real-client behavior.

## Archived: Validation for 1.7.0

The 1.7.0 OpenMap access branch recorded 368 checks and 37 replay frames. It covered entrance guidance, map transforms, marker ownership, and recovery from temporary map errors. It did not draw a continuous walking route or establish real terrain connectivity.

## Archived: Validation for 1.6 and earlier

Older release records and contract references remain in the Git history. Current provider and client contracts are exercised through the versioned workflow and repository tests.
