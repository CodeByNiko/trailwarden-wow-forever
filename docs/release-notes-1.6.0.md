Wayfinder 1.6.0 corrects enemy-level checks after the reported level-29 encounter.

- Combat sources need known enemy levels within +2 of the player, independently of quest level or quest comfort settings.
- Filter drop sources before choosing the nearest target. Use an appropriate alternative or hold the objective for later.
- Unknown combat levels, rejected client/extra coordinates, manual focus and XP estimates cannot bypass the cap.
- Live hostile observations can correct low database levels and immediately stop navigation near visible high-risk enemies. Owned map markers and the arrow are cleared.
- Show enemy level on combat steps and retained Held objectives. Group mode does not relax the level cap; high-level friendly vendors and completed noncombat hand-ins remain available.
- Automatic grind proposals require suitable observed enemy-level evidence as well as XP measurements.

332 checks and 37 replay frames pass locally; GitHub Actions repeats checks under Lua 5.1 before publishing. Actual in-game verification remains outstanding. This filters assessed destinations and readable visible threats; it is not terrain/aggro pathfinding and cannot guarantee safe travel.

Download **Wayfinder-1.6.0-Forever.zip**, exit WoW and replace `Interface/AddOns/Wayfinder`. Keep SavedVariables and QuestieDB/Questie. The checks are enabled automatically; no new setting or reset is required.
