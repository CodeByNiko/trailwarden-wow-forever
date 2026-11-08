# Wayfinder for World of Warcraft: Forever

Wayfinder is a route companion for questing in WoW: Forever. It recommends a useful next destination from your active quest log and completed quests, then guides you toward that destination with a separate, draggable on-screen arrow.

It is designed around **good, coherent quest routes**, not speed leveling. Questie remains responsible for quest tracking and map markers.

## Features

- Prioritizes available waypoints for quests already in your log.
- Uses QuestieDB quest and NPC spawn data to suggest nearby level-appropriate pickup hubs when no active objective is available.
- Adapts when quests are accepted, completed, or turned in, and when you change zone or level.
- Queues a few nearby quest pickups as clear next steps, then advances after each quest enters your log.
- Changes the pickup instruction from travel to accept when you arrive at its quest giver.
- Sets and supertracks a native WoW waypoint automatically while **Auto arrow** is on.
- Provides a separate, draggable on-screen arrow with the current destination and distance.
- Shows a compact route card and nearby quest stops without duplicating Questie's objective tracker.

## Requirements

- WoW: Forever.
- QuestieDB for Forever. Questie is recommended for tracking quests and map markers.
- The custom arrow works without changing WoW settings. To also show Blizzard's native arrow, enable **Options → Interface → Display → In Game Navigation**.

## Install

1. Use **Code → Download ZIP** on this repository.
2. Extract its `Wayfinder` folder into the game's `Interface/AddOns` directory.
3. Enable Wayfinder and Questie at the character selection screen.
4. Log in. Wayfinder opens automatically.

## Controls

- Drag the header to move the panel; **×** hides it.
- `/wf` shows or hides the panel.
- **Refresh route** rescans your progress and route data.
- **Navigator · On/Off** or `/wf arrow` shows and hides the custom on-screen arrow; drag it to reposition.
- `/wf auto` toggles native waypoint tracking.

Wayfinder's waypoint uses WoW's user waypoint and can replace another currently tracked user waypoint.

## Current scope

The dynamic planner depends on QuestieDB having usable quest-giver and spawn coordinates for the current map. Some Forever-specific quest changes may not yet be represented. When it cannot find a mapped local pickup route, Wayfinder uses its included zone recommendations. Route priorities and data will improve with in-game feedback.

## Development

The addon is written in Lua and targets the WoW: Forever 1.60.1 client API. Addon source files are in the `Wayfinder/` folder; `Wayfinder.toc` defines the load order and dependency on QuestieDB.

## License

MIT. See [MIT License](LICENSE.txt).
