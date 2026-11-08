# From 0.3.0 to Wayfinder 1.0

The goal is a useful quest-routing companion for an existing level 22 Dwarf Shaman in Duskwood and a level 7 Night Elf Warrior in Teldrassil, using the same rules and resuming their actual progress. Coherent questing, reduced backtracking and clear next actions take priority over speed-leveling claims.

## Findings in 0.3.0

The fallback route catalog and class stage references were written around the shaman. The active-quest planner depended on client waypoints, so absent waypoints left it offering a generic hub. Pickup eligibility and active-work filtering shared checks that could suppress quests already accepted. Navigation used the native distance and guessed world-axis orientation, while the panel had large unused areas and poorly bounded text.

## Implementation phases

| Phase | Result in 1.0 |
| --- | --- |
| Character state | GUID-scoped progress/preferences, legacy display migration, completion snapshots merged with observed turn-ins, full-log awareness |
| Database adapter | Public QuestieDB entity getters, provider-selected map support, optional Questie availability policy, incremental catalog building and map-transform caching |
| Eligibility | Class/race masks, level/maximum level, alternative and group prerequisites, exclusives, parent/chain gating, profession/rep uncertainty, live gossip evidence |
| Action planning | Pickup, active target, delivery, turn-in, follow-up eligibility, bag quest starters, object/item-source lookup and client-waypoint fallback |
| Route quality | Nearby pickups before leaving a hub, nearby turn-ins, useful objective clusters, distance/locality costs, stable target areas, bounded route hysteresis, focus and temporary skip |
| Navigation | Original arrow asset, direct distances from map transforms, calibrated east/north basis, independent native waypoint sync, explicit arrival/unavailable/transit states |
| Interface | Current action card, four planned steps, constrained text areas, local settings, compact view, scale, saved positions and diagnostic copy view |
| Delivery | Deterministic tests, installable ZIP builder and GitHub release workflow |

## Route selection

The planner first builds candidates for every unfinished active quest and ready hand-in. It adds eligible local pickups if the log has room. Item-started quests already in the player's bags are included. An active quest is never tested as if the player were trying to accept it again.

Candidates receive a travel cost, a bounded nearby-work benefit, a local-zone preference and an action preference. Close ready hand-ins and immediate inventory starts are useful; nearby pickups are gathered before a long objective trip. When the present zone has no useful steps, onward zones from the current region are considered using actual eligible database quests. No universal Duskwood fallback remains.

The displayed queue is a preview based on current information. Future quests are not simulated as completed or accepted. Only real quest-log changes advance those states. A focused step is released when it becomes invalid. A working area stays stable while the same objective is unfinished, and small score differences do not switch the route constantly while moving.

This is a practical heuristic over known action targets. It is not a globally optimal traveling-salesperson solution, a terrain pathfinder or a complete scripted guide to all Forever content.

## Specific character behavior

For the shaman, the current Darkshire pickups and accepted Duskwood quests enter the same action pool. Finished objectives are replaced by their receiver; handed-in quests open eligible chains. No manually tracked water-totem stage can dictate another character's route.

For the warrior, class and race restrictions and its own history gate Teldrassil pickups. An existing quest can be resumed in the middle of its chain. Kalimdor context and live available quests guide onward suggestions. The same engine handles a new character without requiring a hand-selected route pack.

## Boundaries and next improvements

V1 depends on the completeness of the selected Forever QuestieDB build and live APIs. Spell-only/scripted objectives, phases, dungeon floors and transport itineraries can remain unresolved. Missing targets are visible in diagnostics; data uncertainty is never turned into fabricated quest completion. The user can defer a phantom quest, focus another step and continue playing.

The next valuable work is live-client feedback from the two characters, followed by verified cave/transport connectors, phase-aware spawn selection and profiling against actual saved quest logs. Wider race/faction route-context curation should follow evidence from additional characters. Database quest coordinates are consumed at runtime rather than copied into this repository.

## Primary integration references

- [QuestieDB public API](https://github.com/Questie/QuestieDB/blob/master/docs/api.md): entity methods, numeric nil semantics, masks and Support maps.
- [QuestieDB Forever scope](https://github.com/Questie/QuestieDB/blob/master/docs/forever.md): provider-selected data and documented coverage limits.
- [Questie availability implementation](https://github.com/Questie/Questie/blob/master/Database/QuestieDB.lua): availability versus active work and known quest tags.
- [Questie ZoneDB](https://github.com/Questie/Questie/blob/master/Database/Zones/zoneDB.lua): AreaID-to-UiMapID support selection.
