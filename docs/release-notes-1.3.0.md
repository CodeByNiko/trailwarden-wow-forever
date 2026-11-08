Wayfinder 1.3.0 addresses the first live cemetery-routing feedback and reduces screen space.

- Accepted quests stay in routing above the pickup level range, with a clear ABOVE RANGE indicator.
- Skip for now preserves an above-range quest as Later work and resumes it automatically when level/range settings permit. Click Later or use Undo to resume immediately.
- Nearby unfinished objectives take priority over unnecessary trips back to town. Plans retain multiple objectives from the same quest and avoid letting skipped/deferred work block the local batch.
- Standard quest-log capacity now comes from the Forever client (including 40-slot logs).
- Smaller main panel with 0/2/4 upcoming steps; independent panel/arrow scales through settings, mouse wheel or slash commands.
- Transparent draggable navigator with arrow, distance and quest caption, without the large background box/header.

208 automated checks and 15 replay frames pass; GitHub Actions repeats the suites under Lua 5.1 before publication. Actual in-game verification of this revision remains outstanding. Synthetic fixtures do not prove provider data coverage or phase placement.

Download **Wayfinder-1.3.0-Forever.zip**, exit WoW and replace `Interface/AddOns/Wayfinder`. Keep SavedVariables and QuestieDB/Questie. `/wf scale 80` sets the panel to 80%; `/wf arrowscale 90` sets the arrow to 90%. Mouse wheel over the header/arrow also resizes them unless locked. Use `/wf debug` or `/wf trace` for local diagnostics; nothing uploads automatically.
