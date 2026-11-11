# Trailwarden

**Your next quest step, based on the character you are actually playing.**

Trailwarden is an open-source quest-routing companion for **World of Warcraft: Forever**. It reads your quest log and completed quests, recommends what to do next, and guides you with a movable compass arrow. Start a new character or pick up an existing adventure without following a fixed guide from the beginning.

**Public beta for Forever 1.60.1 (Interface 16001).** Feedback is very welcome. Requires **QuestieDB for Forever**; use Forever-compatible Questie and OpenMap for quest tracking, map pins and cave layouts.

## Recent improvements

- Waypoint-aware quest updates, verified objective matching and synchronized fail-safe navigation.
- Conservative routing when Questie policy is incomplete, with bounded planner previews and Horde starter-zone coverage.
- Same-level XP reward calibration and a pinned provider integration in CI.

The interface includes a compact current-step card, progress feedback, a movable compass and a collapsible planned-step list. Measured XP/hour and next-level ETA appear after **five active minutes**.

## What it does

- Adapts to your character's level, class, race, accepted quests and completed history.
- Plans quest pickups, objectives, turn-ins and unlocked follow-ups.
- Groups nearby work and prioritizes unfinished local objectives before distant tasks.
- Retains nearby quest opportunities and recognizes escorts when supported by quest data.
- Shows one current action and a configurable preview of upcoming steps.
- Offers optional XP-aware prioritization alongside measured session XP/hour.
- Keeps settings, skips and learned progress separate for each character.
- Checks known combat destinations against enemy levels; automatic combat sources must be within +2 levels of your character.

## Install or update

1. Download the latest **Forever** file from the Files tab.
2. Exit the game and replace the existing Trailwarden folder with the folder from the ZIP.
3. Confirm the path is `Interface/AddOns/Trailwarden/Trailwarden.toc`.
4. Enable **QuestieDB for Forever**, then start the game and quest normally.

Questie and OpenMap are recommended, separate addons; they are not bundled. Use their Forever-compatible versions. Compatibility with Blizzard Retail or Classic clients is not claimed.

Upgrading from Wayfinder? Follow the [one-time settings migration](https://github.com/CodeByNiko/trailwarden-wow-forever/blob/main/docs/upgrade-to-trailwarden.md) before removing the old addon.

## Quick start

- `/tw` — show or hide the guide.
- `/tw settings` — open character preferences.
- `/tw arrow` — show or hide the navigator.
- `/tw refresh` — reconsider the plan and resume automatic routing.
- `/tw skip` and `/tw undo` — temporarily defer a quest or undo the last skip.
- `/tw pause` and `/tw resume` — pause or resume guidance.

Drag the header or navigator to move them. Accept quests, complete objectives and turn them in normally; Trailwarden updates as your progress changes. **IN AREA** means you reached an objective area, not that the quest is complete.

## Navigation and beta limits

The arrow points toward a target. It does **not** calculate a continuous walkable path, avoid every hazard or navigate a universal tunnel network. Distances are direct map distances, not walking distances.

Entrance-first guidance currently covers **Fel Rock, Shadowthread Cave and Ban'ethil Barrow Den** in Teldrassil. Use OpenMap's cave layout and objective markers inside. Other areas use ordinary direction guidance.

Recommendations depend on Forever quest data and live client information. Missing quests, moving NPCs, incomplete history and unusual scripted objectives can require manual judgment. Escort discovery depends on recognizable provider metadata. XP forecasts are estimates, not a guarantee of the fastest route.

## Feedback and contributions

Found a confusing route or a layout problem? Tell us in the comments or [GitHub Issues](https://github.com/CodeByNiko/trailwarden-wow-forever/issues). Include the addon version, character level/class/race, zone, quest name, what was suggested and what you expected. Screenshots help.

For routing problems, copy `/tw debug` and `/tw trace` **before reloading or logging out**. Review diagnostics before posting publicly; nothing is transmitted automatically.

Code contributions are welcome through [GitHub pull requests](https://github.com/CodeByNiko/trailwarden-wow-forever/pulls). Changes go through the repository's checks and review process.

[Source code and full command reference](https://github.com/CodeByNiko/trailwarden-wow-forever) · [GitHub releases](https://github.com/CodeByNiko/trailwarden-wow-forever/releases)

MIT licensed. Questie and QuestieDB remain separate projects.
