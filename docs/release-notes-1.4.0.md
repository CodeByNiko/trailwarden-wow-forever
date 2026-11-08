Wayfinder 1.4.0 adds measured XP/hour, next-level ETA and XP-aware questing.

- Actual rolling/session XP rates include kills, quests and exploration without counting quest rewards twice. Travel/downtime count; pause and AFK do not.
- Remaining quest-cycle projections include accepted and eligible unaccepted quests, travel, objectives, kill XP and hand-ins. Shared work/rewards are valued together.
- Rewards and targets come from the installed Forever provider, including new-quest corrections. Missing data stays unknown; unseen work and unknown bonuses are low-confidence estimates.
- Verified local kills can establish a grind comparison. A clear advantage over a reliable quest projection can trigger a short, dismissible grind break, with continuous re-evaluation and cooldown.
- Compact XP lines, detail tooltip, XP-aware routing setting, `/wf xp` and `/wf xpreset`.

270 automated checks and 16 replay frames pass locally; GitHub Actions repeats release checks under Lua 5.1. Actual in-game testing of this revision is outstanding. This is an adaptive projection, not a guarantee of a globally optimal route or complete provider coverage.

Download **Wayfinder-1.4.0-Forever.zip**, exit WoW and replace `Interface/AddOns/Wayfinder`. Keep SavedVariables and QuestieDB/Questie enabled. XP-aware mode is on by default. Allow at least one minute for measured XP/hour; grind comparisons require enough verified kills over at least two minutes. Hover the XP lines for confidence and details. `/wf debug` and `/wf trace` remain local diagnostics.
