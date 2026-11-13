# Trailwarden 1.8.5

- Add a verified QuestieDB 1.0.15 Forever index for build 70938, with fallback on other data.
- Measure planning stages separately and reduce diagnostic/replay budgets.
- Reduce navigation, cave lookup and UI work when position, direction and quest state are unchanged.
- Keep the current quest trip and update partial objectives without full replanning; reconsider safe next steps when necessary.
- Coalesce unchanged quest and faction events, and spread automatic candidate selection and forecasting over timer slices.
- Reduce repeated safety-observation allocations.

## Verification

Automated Lua 5.1 scenarios, idle workload, provider, engine, scheduler, safety and replay checks cover the changes. QuestieDB Forever 1.0.14 and 1.0.15 are exercised using a checksum-verified archive and synthetic client APIs. Actual FPS, timing, extended memory use and behavior require live testing in WoW. One provider call, character capture and manual forced replanning may still run synchronously.

## Live profiling

This third 1.8.5 test build identifies itself as `perf-1015-3` in `/tw perf`. Planning stage timings split candidate collection, forecast, snapshot and selection. `plan slice` includes those stages, so their times must not be added to it. Stage checkpoints cannot preempt a single expensive provider/client call, an individual sort or a synchronous snapshot. Live FPS and spike behavior still require measurement. QuestieDB versions/builds not matching a verified bundled index retain the runtime fallback.

Fact capture truncates beyond 2,000 entries. Replay retains at most 6,000 copied entries per decision and 12,000 across the session; oversized frames are skipped and counted. These are diagnostic budgets and do not limit quest routing.

The current test checks inventory before loading quest eligibility for quest-starting items. Index fallback reports the specific observed reason; provider cache invalidation alone no longer marks the index as a changed database. Structural correction application still invalidates it. Live provider startup and correction order may differ from the test doubles.
