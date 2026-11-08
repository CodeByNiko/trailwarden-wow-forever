Wayfinder 1.5.0 prioritizes stable questing and a calmer display after live feedback.

- Keep a committed regional batch and unfinished objective; changing XP estimates do not bounce the route between Duskwood and Redridge.
- XP measurements no longer schedule full planning after every kill. Duplicate log updates are ignored, forecasts are cached, and real quest progress still advances steps promptly.
- Isolate XP/learning/forecast failures from quest guidance. Recover only a freshly revalidated live step, never a completed objective.
- Replace forced inline XP text with readable XP/hour and next-level metric columns. Forecasts and grind comparisons are available on hover.
- Auto route keeps regional continuity. Use Replan region now in settings or /wf refresh to explicitly consider a different region.

291 checks and 36 replay frames pass locally; GitHub Actions repeats them under Lua 5.1. The precise live exception is not identifiable from screenshots alone; diagnostics are improved and actual client testing of this revision remains outstanding.

Download **Wayfinder-1.5.0-Forever.zip**. Exit WoW and replace `Interface/AddOns/Wayfinder`. Retain SavedVariables and keep QuestieDB/Questie enabled. No reset or new activation is needed. XP/ETA remain measured estimates; projected rates are not a guarantee of global optimality.
