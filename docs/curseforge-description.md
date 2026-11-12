# Trailwarden

**Quest guidance that follows the character you are actually playing.**

Trailwarden is an open-source quest-routing companion for **World of Warcraft: Forever**. It uses your character and quest progress to recommend useful next steps, groups nearby work, and guides you to a selected objective with a movable compass arrow. It can help with a new character or continue from an existing quest log; it does not assume you are following a fixed leveling guide.

**Public beta for Forever 1.60.1 (Interface 16001).** Feedback is welcome. **QuestieDB for Forever is required.** Forever-compatible Questie and OpenMap complement Trailwarden with quest tracking, map pins, and cave layouts.

## What it does

* Adapts recommendations to your character's level, class, race, accepted quests, and completed history.
* Plans quest pickups, objectives, turn-ins, and unlocked follow-ups.
* Groups nearby work and prioritizes unfinished local objectives over distant tasks.
* Keeps nearby quest opportunities in view and recognizes escorts when the quest data supports them.
* Shows one current action and a configurable preview of upcoming steps.
* Offers optional XP-aware route prioritization alongside measured session XP/hour.
* Lets you choose automatic language, English, or Danish for Trailwarden action labels and map cues.
* Keeps settings, skips, and learned progress separate for each character.
* Checks known combat destinations against enemy levels; automatic combat sources must be within two levels above your character.

## Quick start

* **/tw** — show or hide the guide.
* **/tw settings** — open character preferences.
* **/tw arrow** — show or hide the navigator.
* **/tw refresh** — reconsider the plan and resume automatic routing.
* **/tw skip** and **/tw undo** — temporarily defer a quest or undo the last skip.
* **/tw pause** and **/tw resume** — pause or resume guidance.
* **/tw feedback** — copy a privacy-conscious routing summary for feedback.

Drag the guide header or navigator to move them. Accept quests, complete objectives, and turn them in normally; Trailwarden updates as your progress changes. **IN AREA** means you reached an objective area, not that the quest is complete.

## Navigation and beta limits

The arrow points toward a target. It does **not** calculate a continuous walkable path, avoid every hazard, or navigate a universal tunnel network. Distances are direct map distances, not walking distances. For cross-continent targets, Trailwarden explains when manual travel is needed; refresh the route after you arrive.

Entrance-first guidance currently covers **Fel Rock, Shadowthread Cave, and Ban'ethil Barrow Den** in Teldrassil. Use OpenMap's cave layout and objective markers inside. Other areas use ordinary direction guidance.

Recommendations depend on Forever quest data and live client information. Missing quests, moving NPCs, incomplete history, and unusual scripted objectives can require manual judgment. Escort discovery depends on recognizable provider metadata. XP forecasts are estimates, not a guarantee of the fastest route.

## Feedback and contributions

Found a confusing route or layout problem? Tell us in the comments or [GitHub Issues](https://github.com/CodeByNiko/trailwarden-wow-forever/issues). Include the addon version, character level/class/race, zone, quest name, what Trailwarden suggested, and what you expected. Screenshots help.

For deeper routing diagnostics, copy **/tw debug** and **/tw trace** before reloading or logging out. Review them before posting publicly. **/tw feedback** copies only release/provider identity and aggregate route counts; it omits character and quest names/IDs, coordinates, preferences, and raw errors. Nothing is transmitted automatically.

Code contributions are welcome through [GitHub pull requests](https://github.com/CodeByNiko/trailwarden-wow-forever/pulls); changes go through the repository's checks and review process.

[Source code and full command reference](https://github.com/CodeByNiko/trailwarden-wow-forever) · [GitHub releases](https://github.com/CodeByNiko/trailwarden-wow-forever/releases)

MIT licensed. Questie and QuestieDB are separate projects.
