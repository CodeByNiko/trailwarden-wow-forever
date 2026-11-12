# Trailwarden · WoW: Forever

A calm quest-routing companion that resumes from **the character you are playing**. Trailwarden reads your quest log and completed quests, chooses a useful next action, and guides you with its own movable arrow. Questie remains your quest tracker and map overlay.

**[Download the latest beta or stable version](https://github.com/CodeByNiko/trailwarden-wow-forever/releases)**

## Current release: 1.8.1

The 1.8.0 feature set is delivered together as one release. This 1.8.1 follow-up aligns the project description and packaged documentation with current language, feedback, navigation, and beta-scope behavior. The 1.8 series improves route reliability, objective matching, navigation recovery, cave handling, and a clearer guide that remains above ordinary addon panels. Recent fixes include:

- Keep local quest guidance intact when a cave access point is refreshed with invalid coordinates.
- Refresh the complete guide when navigation errors start or recover, and prioritize required cross-continent travel over local cave directions.
- Match the strongest live objective name, preserve its client-provided wording, and keep uncertain XP projections out of reliable route comparisons.
- Verify the pinned QuestieDB provider archive with its official SHA-256 before extraction.
- Expand provider smoke checks to cover runtime modules, diagnostics, slash commands, and unexpected output errors.
- Keep the guide visually distinct from overlapping addon panels, with clearer header controls and brighter hover feedback. The settings action uses the standard in-game options gear icon.
- Keep the objective status line readable at common UI scales without cutting off “Above range”.

See the [release notes](https://github.com/CodeByNiko/trailwarden-wow-forever/tree/main/docs) for all changes.

## Selected improvements from 1.7

## New in 1.7.4: easier to read at a glance

Larger text, clearer contrast and a content-sized quest card put the current objective first. Progress uses a count and a slim bar; distance is part of the same card. Planned steps separate the quest name from its action, while the collapsed guide retains your current quest and distance. Navigator captions are larger and preferences use aligned labels and values.

## New in 1.7.3: compact routes and clearer estimates

The route panel uses a tighter layout, shows objective progress at a glance and keeps route details in the hover explanation. The navigator has a redesigned compass pointer. Quest-cycle estimates reduce unnecessary backtracking, while live XP/hour and next-level time wait for a five-minute active sample.

## New in 1.7.2: Trailwarden

Renamed from Wayfinder with a separate addon namespace, settings file and `/tw` command. See [upgrade instructions](https://github.com/CodeByNiko/trailwarden-wow-forever/blob/main/docs/upgrade-to-trailwarden.md) before removing the old addon.

## New in 1.7.1: finish local work and retain nearby opportunities

Unfinished accepted objectives now take priority over distant objectives, not only town returns. XP forecasts cannot override that area boundary. The planner receives the same observed cave context as navigation, treats cave floors as part of their parent quest region, and prefers a known safe item source inside the current cave when one exists.

The same guideline applies beyond named caves: actual quest-progress changes create a temporary local work focus, and live interior/subzone context plus map hierarchy provide location evidence. Focus releases when the quest finishes/fails, the player leaves the area, or the player explicitly skips/changes focus. Unavailable safe targets produce a review step instead of silently abandoning recently engaged work. Enemy-level checks still apply.

Nearby eligible quest offers are retained as opportunities. Escort offers wait until local collection is finished and are considered before leaving; accepting an escort commits guidance to following its NPC until completion/failure. Escort detection uses provider event metadata, not quest-ID exceptions. The UI names nearby opportunities in its existing status area. Fresh provider/client availability is still required: an unknown or unavailable quest cannot be promised, and an escort without recognizable event metadata may need manual guidance.

## New in 1.7: cave access and map guidance

**No additional navigation addon is required.** Keep your existing Questie and OpenMap enabled. Trailwarden now separates a cave's entrance from the quest target inside it. For Lord Melenas in Fel Rock, the arrow and native waypoint first target the entrance instead of the underground objective's hillside projection.

- **Cyan marker:** cave entrance; approach this first. **Gold marker:** final quest objective. Markers appear on the minimap and through OpenMap's supported world-map integration.
- Known access records cover **Fel Rock, Shadowthread Cave and Ban'ethil Barrow Den** in Teldrassil. Matching live Forever entrance POIs take priority; fallback locations are labeled **Reference entrance**.
- On a recognized cave map, or matching indoor subzone, guidance switches to the cave map. It does not keep pointing through tunnel walls. Getting near the entrance or target alone never completes a quest or proves you entered the cave.
- Ordinary quests retain the existing routing and arrow. The map library is detected automatically, including its real callable-table LibStub interface; temporary marker failures retry without a quest update.

**This is an entrance-and-marker release for live testing. It does not draw a continuous walking route or calculate a universal path around terrain.** The entrance arrow is still a direction, not a verified approach corridor. Inside caves, use OpenMap's cave layout and the objective marker; outside the known access coverage, normal direction guidance remains. See [1.7 scope and live-test notes](https://github.com/CodeByNiko/trailwarden-wow-forever/blob/main/docs/V1.7-openmap-navigation.md).

## Install or update

1. Open **Releases**, choose the newest Forever beta or stable version, and download its `Trailwarden-<version>-Forever.zip` under **Assets**.
2. Exit WoW. Replace `Interface/AddOns/Trailwarden` with the `Trailwarden` folder inside the ZIP.
3. Keep **QuestieDB for Forever**, **Questie** and your existing **OpenMap** enabled. Questie supplies the map-pin library; the core quest planner still requires QuestieDB.
4. Start the game. Your character's route and navigator appear automatically. For an upgrade from Wayfinder, migrate your saved settings as described below.

The resulting path must be `Interface/AddOns/Trailwarden/Trailwarden.toc`. When using GitHub's **Code → Download ZIP**, copy the inner `Trailwarden` folder from the repository archive.

## What Trailwarden does

- Resumes existing characters and new characters from their own live progress. Profiles, skips, preferences and learned completion history are separate per character.
- Plans **accept → quest objective → return → turn in → unlocked follow-up** actions. It never marks a quest complete simply because you arrived somewhere.
- Uses live client waypoints, QuestieDB NPC/object positions, creature and object item sources, deliveries and quest-starting items in your bags.
- Checks level, class, race, prerequisites, alternatives and mutually exclusive chains. Solo mode avoids known group/dungeon quests. New pickup recommendations default to quests up to two levels above you; already accepted quests are retained with an above-range indicator. Their combat sources must independently satisfy the +2 enemy-level cap.
- Collects useful nearby pickups, combines objectives in the same area and favors nearby completed turn-ins. A full log switches attention to existing work.
- Shows one current instruction and a configurable preview of up to four planned steps. Plans adapt as quests change. Click a future step to focus it; **Auto route** resumes automatic selection.
- Learns live offers from NPC conversations. If Forever data suggests a quest that is absent, **Skip 15 min** moves the whole quest out of the route temporarily. Above-range accepted work instead offers **Skip for now**, returning automatically when it fits your level range.
- Provides an independent direction arrow and distance. Blizzard's native navigation display can remain disabled.
- Handles Teldrassil and Duskwood with the same planner, with Alliance zone context and onward suggestions across level 1–60.

XP-aware mode ranks modeled cycles within a committed region by estimated XP return, with a conservative discount for uncertain data. Regional continuity, unfinished work, eligibility and explicit focus remain constraints. Unknown cycles retain the normal questing fallback. This is a continuously updated heuristic, not a proof of a globally optimal route.

## New in 1.6

**Combat targets are checked by enemy level, not quest level.** Automatic combat sources must have known levels within **+2 of your character**, using the provider's maximum enemy level. A level-25 quest does not authorize a level-29 enemy for a level-22 character. Item drops and kill-credit alternatives are filtered before choosing the nearest source. Unknown combat levels are held for review.

If no appropriate source exists, the objective stays recorded and appears as **Held** in the bounded preview when space permits. Live target/mouseover/nameplate observations can raise an underestimated provider level. A visible over-level hostile temporarily stops navigation; group settings and manual focus cannot bypass the level cap. High-level friendly vendors and noncombat turn-ins remain available.

This filters known combat destinations. The arrow still does not calculate a terrain- or danger-free walking path, and the client may not reveal every nearby enemy. See [combat-level review and limits](docs/V1.6-combat-safety.md).

## Using it

The main window explains the next action. The arrow shows direction to that action. At the quest giver it says **Accept at quest giver** or **Turn in here**; in an objective area it says **Work in this area**. Accept, quest and turn in normally, and Trailwarden selects the next step from the updated quest log.

Drag the window's header or the navigator to move them. **−/+** collapses the planned list. The settings offer 0/2/4 preview rows. **…** opens character preferences: solo/group quests, comfort level (+2/+4), automatic map waypoint, navigator visibility, independent panel/arrow scales, window locking and pause/resume. Closing the main window leaves the navigator available.

| Command | Action |
| --- | --- |
| `/tw` | Show/hide the guide |
| `/tw arrow` | Show/hide the navigator |
| `/tw routepins` | Toggle Trailwarden entrance/objective markers; also available in OpenMap’s menu |
| `/tw settings` | Open/close character preferences |
| `/tw lock` | Lock/unlock window positions |
| `/tw refresh` | Explicitly reconsider the regional plan and return to automatic routing |
| `/tw skip`, `/tw undo` | Defer for 15 minutes / undo the last timed or level skip |
| `/tw later` | Defer the current above-range accepted quest until it fits your level settings |
| `/tw scale 80` | Set panel scale to 80% (60–130%) |
| `/tw arrowscale 90` | Set navigator scale to 90% (60–150%) |
| `/tw pause`, `/tw resume` | Pause/resume route navigation |
| `/tw group` | Toggle known group/dungeon quest inclusion |
| `/tw auto` | Toggle the native map waypoint; the custom arrow is independent |
| `/tw reset` | Reset both window positions |
| `/tw rebuild` | Rebuild the QuestieDB index after data changes |
| `/tw trace` | Copy a bounded local decision replay; export before reload/logout |
| `/tw xp` | Toggle XP-aware routing; measured statistics remain available |
| `/tw xpreset` | Reset this character’s current XP session, retaining learned pace |
| `/tw debug` | Copyable local diagnostics; nothing is transmitted |

Measured XP/h appears after five active minutes. Its dedicated section shows measured XP/hour and next-level ETA; projected quest/grind rates are in the hover details. It includes actual XP from kills, quests and exploration, with travel and ordinary downtime in the denominator. Pause and AFK are excluded. Hover the XP lines for session statistics, estimate confidence and calculation details. Unknown rates show `--`; a zero measured rate has no finite level ETA.

A grind suggestion also requires recent suitable enemy-level observations in the area. It requires at least eight locally observed, verified rewarded kills over two minutes, a modeled quest alternative of medium confidence and at least a 25% rate advantage. It lasts at most three minutes, is rechecked as progress changes and can be dismissed with **Questing now**. A two-minute cooldown prevents immediate repetition. No fixed Classic grinding guide is bundled.

## First evening with your characters

**Level 22 Dwarf Shaman in Darkshire:** existing accepted quests are recognized. Trailwarden compares remaining nearby pickups, current Duskwood objectives and ready turn-ins, instead of restarting at a generic Darkshire waypoint. Class quests are considered only through their actual restrictions and progress.

**Level 7 Night Elf Warrior in Teldrassil:** its own class/race, quest history and current location select the route. It is never assigned a shaman totem route or sent to Duskwood because of its level alone. When local eligible work runs out, nearby onward zones are considered from database availability.

## Scope and limits

Forever quest data is still developing. The provider itself documents incomplete new content, objectives, restrictions and live placement. A database position can be absent or out of date; cave floors, phases, moving NPCs, unusual scripted/spell objectives and transport connections may require Questie or the quest text. A fresh live offer can resolve incorrect static restrictions, but cannot override subsequent confirmed blocking progress. Incomplete quest history or a partial/collapsed quest log suspends database pickups; expand quest headers and run `/tw refresh` if diagnostics report an incomplete log. Unknown active quests can use a client waypoint when one exists; otherwise they are shown as unmapped in diagnostics.

The arrow points toward a target, with entrance-first access guidance for the three documented Teldrassil caves. It does **not** calculate a terrain-safe walking path, tunnel graph, general bridge access or boat schedules. Follow roads and use normal travel connections. It never displays a stale bearing when position data is missing or a target is on another continent. Distances are direct map distances, not walking distance.

The automated scenarios use synthetic client data modeled on the two character contexts. A successful run does not replace testing in the actual Forever client. See [the V1 implementation analysis](docs/V1-implementation.md) and [validation notes](docs/validation.md).

## Development and releases

Lua files live in `Trailwarden/`; the TOC defines load order. `python3 tools/check.py` runs scenarios, pure-engine checks, provider/client contracts, XP accounting/projection checks and replay verification, with a 90-second timeout per suite. `python3 tools/package.py` builds a reproducible installable ZIP. GitHub Actions verifies feature-branch pushes and pull requests under Lua 5.1 with read-only repository permissions. On `main`, the separate release workflow runs the checks and publishes a release for a new TOC version.

MIT license for Trailwarden's code and original arrow asset. Questie and QuestieDB are separate dependencies; no database or paid guide content is bundled.
