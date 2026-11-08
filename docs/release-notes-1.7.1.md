# Wayfinder 1.7.1 — finish the area, then leave

This hotfix addresses two related live reports: abandoning unfinished collection in Ban'ethil for Crown of the Earth, and overlooking an available escort in the cave.

- Unfinished local accepted objectives now constrain other quest objectives as well as trips to town. XP forecasts cannot override this boundary.
- Cave context reaches the quest planner before selection. Cave floors resolve to their parent quest region; eligible nearby offers are no longer lost solely because the player is on a floor map.
- Prefer a known, eligible source inside the current cave when an item also has nearer outside sources. Combat restrictions remain unchanged.
- Actual quest-progress changes create a temporary local focus, independently of XP measurement. This general rule also covers unnamed interiors and outdoor quest areas. Finish/failure, explicit skip/focus and leaving the area release it. If the current safe target becomes unavailable, show a review step instead of silently moving to another quest.
- Keep nearby eligible offers visible in the existing status area. Escort pickups wait until current local collection is finished, then are considered before departure.
- An accepted escort uses its provider event metadata to keep guidance on following the NPC, without a misleading endpoint arrow. Completion/failure releases that activity. No quest-ID exceptions drive this behavior.

Validation: 409 synthetic checks and 40 replay frames. Includes last-item collection, high outside XP, floor maps, closer outdoor sources, unaccepted/active escorts, unnamed-interior progress, missing-source review, safety and manual overrides. Actual client validation is still needed.

Limitations: quest discovery requires current provider/client availability; missing quest data and unrecognized escort event metadata cannot be inferred perfectly. This patch does not add a walking mesh, tunnel route or continuous terrain path.

Update: exit WoW, replace Interface/AddOns/Wayfinder with the release folder, restart with QuestieDB, Questie and OpenMap enabled. Existing settings/progress remain. No reset is needed.

Suggested live test: finish remaining Relics of Wakening collection before leaving Ban'ethil; check the nearby escort opportunity, then follow it after acceptance. If the route still differs, send `/wf debug` and `/wf trace`, including the selected quest and current coordinates.
