# Trailwarden in-game smoke log

Copy this template for each candidate release and complete it in World of Warcraft: Forever. Do not include account names, character names, screenshots with chat identity, or other personal identifiers in shared logs.

## Build and setup

- Trailwarden version:
- Forever client build / interface:
- QuestieDB version:
- Questie version, or `disabled`:
- OpenMap version, or `disabled`:
- Character faction / race / class / level:
- Date and tester:

## Checks

| Check | Steps | Expected result | Result / notes |
| --- | --- | --- | --- |
| Login and first route | Log in, wait for catalog and quest log | One coherent route appears; no Lua errors or stale waypoint | Not run |
| Quest progress | Update an objective, then finish it | Route advances only after verified progress | Not run |
| Client waypoint | Change the active quest's waypoint without changing objective counts | Route refreshes to the authoritative waypoint | Not run |
| Quest turn-in | Complete a quest and inspect `/tw debug` | Actual XP is counted once; same-level reward calibration is recorded | Not run |
| Map and route pins | Open/close map; move between route steps | Trailwarden-owned pins match the current route and clear on unavailable navigation | Not run |
| Optional addons | Repeat relevant checks with Questie and OpenMap enabled, then disabled | Required QuestieDB-only behavior remains available; optional behavior degrades with clear guidance | Not run |
| Pause, death, recovery | Pause/resume; die/release; trigger a temporary data/navigation failure | No actionable route while unsafe/unavailable; correct guidance returns after recovery | Not run |

## Release decision

- Lua errors or taint observed:
- Incorrect route or waypoint:
- Visual/layout issue:
- Follow-up issue links:
- Overall: `Not run / Pass / Blocked`
