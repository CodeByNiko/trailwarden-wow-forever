# Trailwarden 1.8.5

- Reduce navigation, cave lookup and UI work when position, direction and quest state are unchanged.
- Keep the current quest trip and update partial objectives without full replanning; reconsider safe next steps when necessary.
- Coalesce unchanged quest and faction events, and spread automatic candidate selection and forecasting over timer slices.
- Reduce repeated safety-observation allocations.

## Verification

Automated Lua 5.1 scenarios, idle workload, provider, engine, scheduler, safety and replay checks cover the changes. QuestieDB Forever 1.0.14 is exercised using a checksum-verified archive and synthetic client APIs. Actual FPS, timing, extended memory use and behavior require live testing in WoW. One provider call, character capture and manual forced replanning may still run synchronously.
