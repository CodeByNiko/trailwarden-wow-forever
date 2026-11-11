# Installation and provider validation matrix

| Addons enabled | Automated coverage | Limits |
| --- | --- | --- |
| QuestieDB only | `tests/provider_contract.lua` and the CI integration against QuestieDB Forever 1.0.14 | Quest log, map position, and event APIs are synthetic in the provider integration. |
| QuestieDB + Questie | `tests/scenarios.lua` exercises Questie quest policy and optional module behavior. | Questie UI and live client coexistence are not simulated. |
| QuestieDB + OpenMap | `tests/travel.lua` exercises the optional travel and map API contract. | Map interaction and rendering are synthetic. |
| QuestieDB + Questie + OpenMap | Combined dependencies are checked from the addon TOC; component contracts run independently. | No combined live-client smoke test is claimed by CI. |

QuestieDB is the sole required addon. Questie and OpenMap are optional. CI downloads the immutable `v1.0.14` Forever asset and checks its TOC version before loading the real provider code under Lua 5.1. `lupa` and `cbor2` are pinned in the workflow; no provider files or Python packages are included in the addon.

Use [the client smoke log template](client-smoke-template.md) for in-game checks. Record the actual Forever client build, installed addon versions, character faction/level, steps, and outcome. Mark a check blocked when the game client is unavailable; do not treat synthetic provider tests as a substitute.
