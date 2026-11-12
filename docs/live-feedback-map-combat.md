# Live feedback: map, combat and quest navigation

Development branch from main at ba98bf6. The iterations below are historical. The user has now authorized final QA, PR and merge as 1.8.4; see [completed provider work](questiedb-implementation-1.8.4.md) and [release notes](release-notes-1.8.4.md).

## Changes

- Accept boolean and numeric combat flags and check live combat state every 0.1 seconds as an event fallback. Hide the guide in combat and restore the saved preference afterward.
- Retain the arrow during combat using the last validated access target, with fresh bearing and distance. Suspend route planning, provider/access queries, map-waypoint writes and population scans during combat.
- Coalesce nameplate and mouseover events into periodic safety sampling instead of rescanning the entire visible population for every event. Target changes outside combat still receive immediate safety checks.
- Defer quest capture, access and waypoint work while the world map is visible. Coalesce pending captures after closure. Make inactive map-marker cleanup idempotent and avoid deep-copying forecast data on each navigation tick.
- Click the current quest card or a planned quest to open the exact active quest in the log. Shift-click a planned row to retain manual route focus. Unaccepted quests do not select an unrelated log entry.

## Verification

Automated coverage includes numeric combat flags without regen events, guide/arrow visibility, deferred combat work, nameplate bursts, rapid map toggles, inactive map-marker cleanup and exact quest-log selection. Full release checks pass locally.

The code exposes repeated work consistent with the reported symptoms, but the user's FPS drops have not been reproduced in a live WoW client. Confirm combat hiding, arrow behavior, quest selection and repeated map toggles with the affected addon set and view distance before release. The branch retains version 1.8.3 pending further feedback and release preparation.

## Second map-performance iteration: map-quiet-2

- Map show/hide hooks restart a 0.75-second quiet period, including toggles between update frames. Polling remains as a fallback. During repeated map toggles, defer quest capture, full navigation, safety scanning and waypoint/map-pin updates until the map stays closed.
- Gate immediate target safety scans and combat-exit capture during this quiet period as well. Preserve deferred changes for one catch-up update after settling.
- Prune saved profile caches before deep-copying replay input instead of copying and then discarding them.
- `/tw perfreset` resets local event/work counters; `/tw perf` displays them without capturing the character or starting a new route plan. The output identifies this test build as `map-quiet-2`.

The full suite passes, including 100 map cycles mixed with 8,000 nameplate events: zero quest captures, full navigation updates and safety scans between toggles, with one deferred quest capture after the final close. This is a deterministic workload check, not a reproduction of the reported 15% live CPU reading or an FPS measurement.

Live comparison: install the new test package and restart WoW; run `/tw perfreset`, reproduce the rapid M toggles, wait two seconds after the last close and run `/tw perf`. Record the displayed counters and CPU reading together. Repeat with the reported view-distance setting. No PR or release has been made.

## CPU and memory iteration: spikes-3

The global catalog previously expanded and retained NPC/object coordinates worldwide merely to index quest zones. It now indexes zone IDs directly; full points are resolved on demand. Runtime point caching is limited to 128 entities and 4,096 points. Character/planner snapshots exclude the XP-learning and combat-observation stores. Replay retention is additionally limited to 24,000 copied entries in total and 12,000 per frame; oversized diagnostic snapshots are skipped without changing route decisions.

Catalog timer slices now pause during combat, map display and map-settling. Each slice stops after an item when it reaches approximately 2 ms, or after 20 quests, and subsequent slices are spaced 50 ms apart. One individual provider call cannot be preempted.

The route selector uses spatial indexes for cluster comparisons, computes nearby-work distances once per route leg, skips scoring projections for low-confidence models and shares immutable forecast copies/calculations within each pass. Sixty mixed-coordinate/action fixtures produced exactly the same selected route, queue and scores as commit f5650ce. Regression coverage adds a work budget for 500 dispersed candidates, bounded caches/replays, catalog pausing and timing error isolation.

Synthetic measurements on the same local runtime (not live WoW):

| Workload | Before | After |
| --- | --- | --- |
| 500-quest catalog, retained after GC | 14,678.9 KiB | 396.7 KiB |
| 500-quest catalog, total CPU | 121.4 ms | 14.9 ms |
| Selector, 320 candidates, median of 7 | 70.82 ms | 17.51 ms |
| Selector, 128 candidates, median of 7 | 24.77 ms | 12.34 ms |

`/tw perf` identifies `spikes-3` and includes total/peak milliseconds per work section, the largest section with its event/trigger, and retained point/replay budgets. `/tw perfreset` resets the measurement window. CPU timing depends on `debugprofilestop`; if the client does not expose it, only workload counters are available. Restart WoW after installing the updated test package so the old global point cache is released. Live memory/CPU behavior remains to be confirmed on the affected setup. No PR or merge is authorized yet.
