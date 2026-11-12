# Trailwarden 1.8.4

- Reduce repeated work from rapid map toggles, nameplates and mouseover events. Wait until the map stays closed before one catch-up update.
- Hide the main guide in combat, retain lightweight arrow guidance, and suspend planning/provider/population work until combat ends.
- Click active quest cards or planned rows to open the exact quest-log entry. Shift-click a planned row to focus its route.
- Avoid worldwide starter-spawn decoding with a verified QuestieDB Forever 1.0.14 zone index; fall back safely for other versions or corrected data.
- Bound point caches, provider-pass reuse, diagnostic capture and replay retention. Cancel stale automatic route-selection slices before publishing.
- Add provider compatibility/lifecycle handling and detailed `/tw perf` and `/tw perfreset` measurements.

Restart WoW after updating to release caches retained by an older build. QuestieDB remains required. The addon never clears QuestieDB's shared caches or forces garbage collection.

## Verification

Automated Lua 5.1 scenarios, engine, safety, provider lifecycle/contract, scheduler, performance and replay checks pass locally. Tests cover 100 rapid map cycles with noisy events, combat UI/arrow behavior, exact quest selection, cache eviction, bounded capture, correction/locale invalidation and stale asynchronous work.

The checksum-pinned real QuestieDB Forever 1.0.14 package builds all 5,682 catalog quests without global NPC/object spawn reads on the verified-index path. Cold catalog and repeated warm-plan allocation/retention are measured separately; generated index reproduction is checked against the same package. These are emulated-client checks, not live FPS measurements. The affected WoW setup must confirm combat visibility, repeated M toggles, high view distance, CPU peaks and memory stability.
