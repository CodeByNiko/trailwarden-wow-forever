# QuestieDB improvements delivered in 1.8.4

This completes the implementation proposed in [the analysis](questiedb-integration-review.md), together with the live feedback branch. The original analysis describes the state before these changes.

| Finding | Implementation | Verification |
| --- | --- | --- |
| Fresh ownership and realistic allocation | Fresh nested spawn fixtures and the actual baked Forever provider | performance.lua, check_provider.py |
| Repeated field reads and capture copies | Immutable per-pass cache (512 entries), no error caching, duplicate-fact suppression, 4,000-entry capture budget | provider_lifecycle.lua; real-provider same/cross-pass assertions |
| Global startup spawns | Generated quest/starter-zone/item IDs bound to exact provider version, contract, mode, flavor and build; membership and provenance checks | generator --check; all 5,682 real quests; zero global spawn reads |
| Corrections and locale changes | Own cache generation; hooks on public correction registration/application/removal, invalidation and locale APIs | provider_lifecycle.lua, async catalog cancellation |
| Compatibility and metadata | RequireContract(3), explicit unsupported-provider wait/error, provider identity and counters in /tw perf | provider contract/lifecycle and fresh-namespace diagnostics |
| Getter overhead and ownership | Public named getters with Get fallback; no GetRaw or global name index; support-map copies preserved | contract and actual-provider checks |
| Unfinished async work | Timer-sliced pure route selection with token/provider/character validation and combat/map cancellation; publish complete decisions only | scheduler.lua, scenario and replay suites |
| Cold/warm behavior | Pinned baked provider, allocation/retention measured separately, repeated plans/map storm; no runtime forced GC | check_provider.py, bounded workload tests |

## Index provenance and lifecycle

`CatalogIndex.lua` contains factual quest/entity/item IDs and zone membership generated through the public provider API, without names, coordinates, provider implementation or provider source files. Source: QuestieDB Forever 1.0.14 ZIP, SHA-256 `becb9b3cea4a99ae31f115a187179c242f5cf8ef28bf4f9579a86393f18f45c3`. Generation and exact comparison run in CI. The dependency retains its own notices and license; the integration uses independently written consumer code.

The index is accepted only when metadata, quest IDs and provenance match. Structural changes mark it dirty for the session; the existing timed builder then reads current public API data. Names are always read at runtime. Provider pointer/metadata, public corrections and locale changes invalidate only Trailwarden's caches. No provider-global cache clear is used. If public post-hooks are unavailable, the index fast path is disabled; `/tw rebuild` refreshes consumer data after external changes. Changes bypassing the provider's public APIs require a rebuild/restart.

A timer budget applies between Lua work items. A single native provider decode cannot be preempted. Input capture and candidate collection remain synchronous; `/tw perf` identifies their cost separately from selection slices. Live WoW FPS, addon-attributed memory and long-session behavior cannot be established by the emulator.

## Local measurements

One run using Lua 5.1, baked Forever 1.0.14, build 70245, enUS and synthetic client APIs measured approximately 101 ms total CPU / 7,035 KiB retained for the complete cold catalog, and 134 ms / 20,734 KiB temporarily allocated / 431 KiB retained for ten warm forced plans. These include real provider decoding and consumer work, are workload-specific, and are not per-frame or live FPS guarantees. Test-only GC separates temporary allocation from retention; addon runtime does not force collection.

For live validation, restart WoW, run `/tw perfreset`, reproduce map/combat feedback, then record `/tw perf` alongside the profiling addon's readings. Repeat after a longer session with the same profiling settings and addon set.
