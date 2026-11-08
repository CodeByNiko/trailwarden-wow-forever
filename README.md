# Wayfinder · WoW: Forever

A calm quest-routing companion that resumes from **the character you are playing**. Wayfinder reads your quest log and completed quests, chooses a useful next action, and guides you with its own movable arrow. Questie remains your quest tracker and map overlay.

**[Download the latest installable version](https://github.com/CodeByNiko/wayfinder-wow-forever/releases/latest)**

## Install or update

1. Download `Wayfinder-1.5.0-Forever.zip` under the release's **Assets**.
2. Exit WoW. Replace `Interface/AddOns/Wayfinder` with the `Wayfinder` folder inside the ZIP.
3. Keep **QuestieDB for Forever** enabled. Questie is strongly recommended for its availability checks, map markers and tracking.
4. Start the game. Your character's route and navigator appear automatically. Existing saved progress is retained.

The resulting path must be `Interface/AddOns/Wayfinder/Wayfinder.toc`. When using GitHub's **Code → Download ZIP**, copy the inner `Wayfinder` folder from the repository archive.

## What Wayfinder does

- Resumes existing characters and new characters from their own live progress. Profiles, skips, preferences and learned completion history are separate per character.
- Plans **accept → quest objective → return → turn in → unlocked follow-up** actions. It never marks a quest complete simply because you arrived somewhere.
- Uses live client waypoints, QuestieDB NPC/object positions, creature and object item sources, deliveries and quest-starting items in your bags.
- Checks level, class, race, prerequisites, alternatives and mutually exclusive chains. Solo mode avoids known group/dungeon quests. New pickup recommendations default to quests up to two levels above you; already accepted quests are retained with an above-range indicator.
- Collects useful nearby pickups, combines objectives in the same area and favors nearby completed turn-ins. A full log switches attention to existing work.
- Shows one current instruction and a configurable preview of up to four planned steps. Plans adapt as quests change. Click a future step to focus it; **Auto route** resumes automatic selection.
- Learns live offers from NPC conversations. If Forever data suggests a quest that is absent, **Skip 15 min** moves the whole quest out of the route temporarily. Above-range accepted work instead offers **Skip for now**, returning automatically when it fits your level range.
- Provides an independent direction arrow and distance. Blizzard's native navigation display can remain disabled.
- Handles Teldrassil and Duskwood with the same planner, with Alliance zone context and onward suggestions across level 1–60.

XP-aware mode ranks modeled cycles within a committed region by estimated XP return, with a conservative discount for uncertain data. Regional continuity, unfinished work, eligibility and explicit focus remain constraints. Unknown cycles retain the normal questing fallback. This is a continuously updated heuristic, not a proof of a globally optimal route.

## New in 1.5

**Stable regional questing and a cleaner XP display.** XP changes no longer cause full planning after every kill. The planner commits to the current region while useful mapped steps remain, keeps an unfinished objective selected, and advances when progress makes that step invalid or complete. Level-ups reveal options without automatically sending you to another zone.

XP forecasts are reused for 45 seconds unless the goal set, eligibility, catalog or meaningful travel changes. Duplicate quest-log events do not rebuild unchanged plans. Forecast/learning failures fall back to normal quest guidance, and a planner error can retain only an independently revalidated live objective/hand-in.

The compact guide now gives measured XP/hour and next-level ETA their own readable two-column section. Uncertain quest/grind projections live in its tooltip. **Auto route** respects the regional batch; **Replan region now** in settings or `/wf refresh` explicitly reconsiders the wider route.

See [stability and polish review](docs/V1.5-stability.md).

## Using it

The main window explains the next action. The arrow shows direction to that action. At the quest giver it says **Accept at quest giver** or **Turn in here**; in an objective area it says **Work in this area**. Accept, quest and turn in normally, and Wayfinder selects the next step from the updated quest log.

Drag the window's header or the navigator to move them. **−/+** collapses the planned list. The settings offer 0/2/4 preview rows. **…** opens character preferences: solo/group quests, comfort level (+2/+4), automatic map waypoint, navigator visibility, independent panel/arrow scales, window locking and pause/resume. Closing the main window leaves the navigator available.

| Command | Action |
| --- | --- |
| `/wf` | Show/hide the guide |
| `/wf arrow` | Show/hide the navigator |
| `/wf settings` | Open/close character preferences |
| `/wf lock` | Lock/unlock window positions |
| `/wf refresh` | Explicitly reconsider the regional plan and return to automatic routing |
| `/wf skip`, `/wf undo` | Defer for 15 minutes / undo the last timed or level skip |
| `/wf later` | Defer the current above-range accepted quest until it fits your level settings |
| `/wf scale 80` | Set panel scale to 80% (60–130%) |
| `/wf arrowscale 90` | Set navigator scale to 90% (60–150%) |
| `/wf pause`, `/wf resume` | Pause/resume route navigation |
| `/wf group` | Toggle known group/dungeon quest inclusion |
| `/wf auto` | Toggle the native map waypoint; the custom arrow is independent |
| `/wf reset` | Reset both window positions |
| `/wf rebuild` | Rebuild the QuestieDB index after data changes |
| `/wf trace` | Copy a bounded local decision replay; export before reload/logout |
| `/wf xp` | Toggle XP-aware routing; measured statistics remain available |
| `/wf xpreset` | Reset this character’s current XP session, retaining learned pace |
| `/wf debug` | Copyable local diagnostics; nothing is transmitted |

Measured XP/h appears after 60 seconds. Its dedicated section shows measured XP/hour and next-level ETA; projected quest/grind rates are in the hover details. It includes actual XP from kills, quests and exploration, with travel and ordinary downtime in the denominator. Pause and AFK are excluded. Hover the XP lines for session statistics, estimate confidence and calculation details. Unknown rates show `--`; a zero measured rate has no finite level ETA.

A grind suggestion requires at least eight locally observed, verified rewarded kills over two minutes, a modeled quest alternative of medium confidence and at least a 25% rate advantage. It lasts at most three minutes, is rechecked as progress changes and can be dismissed with **Questing now**. A two-minute cooldown prevents immediate repetition. No fixed Classic grinding guide is bundled.

## First evening with your characters

**Level 22 Dwarf Shaman in Darkshire:** existing accepted quests are recognized. Wayfinder compares remaining nearby pickups, current Duskwood objectives and ready turn-ins, instead of restarting at a generic Darkshire waypoint. Class quests are considered only through their actual restrictions and progress.

**Level 7 Night Elf Warrior in Teldrassil:** its own class/race, quest history and current location select the route. It is never assigned a shaman totem route or sent to Duskwood because of its level alone. When local eligible work runs out, nearby onward zones are considered from database availability.

## Scope and limits

Forever quest data is still developing. The provider itself documents incomplete new content, objectives, restrictions and live placement. A database position can be absent or out of date; cave floors, phases, moving NPCs, unusual scripted/spell objectives and transport connections may require Questie or the quest text. A fresh live offer can resolve incorrect static restrictions, but cannot override subsequent confirmed blocking progress. Incomplete quest history or a partial/collapsed quest log suspends database pickups; expand quest headers and run `/wf refresh` if diagnostics report an incomplete log. Unknown active quests can use a client waypoint when one exists; otherwise they are shown as unmapped in diagnostics.

The arrow points toward a target; it does **not** calculate a terrain-safe path, bridge/cave entrances or boat schedules. Follow roads and use normal travel connections. It never displays a stale bearing when position data is missing or a target is on another continent. Distances are direct map distances, not walking distance.

The automated scenarios use synthetic client data modeled on the two character contexts. A successful run does not replace testing in the actual Forever client. See [the V1 implementation analysis](docs/V1-implementation.md) and [validation notes](docs/validation.md).

## Development and releases

Lua files live in `Wayfinder/`; the TOC defines load order. `python3 tools/check.py` runs scenarios, pure-engine checks, provider/client contracts, XP accounting/projection checks and replay verification. `python3 tools/package.py` builds a reproducible installable ZIP. On `main`, GitHub Actions runs all checks under Lua 5.1 and publishes a release for a new TOC version.

MIT license for Wayfinder's code and original arrow asset. Questie and QuestieDB are separate dependencies; no database or paid guide content is bundled.

