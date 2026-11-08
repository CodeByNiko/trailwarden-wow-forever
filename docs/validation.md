# Validation for 1.1.0

93 deterministic scenario checks pass locally. The local runner used system Lua 5.4 with test-only compatibility aliases for Lua 5.1 globals; the release workflow installs and runs Lua 5.1 before it can publish a package.

The scenarios cover:

- Night Elf Warrior class/race gating and local Teldrassil routing.
- Existing Darkshire pickups and an already accepted Night Watch-style quest.
- Per-character history, legacy display migration and retained turn-in events.
- Single/all/negative prerequisites, exclusives and live offer overrides.
- Completed group/high-level turn-ins while solo mode is active.
- NPC kill targets, object-sourced items, multiple objectives, deliveries,
  client-waypoint fallback and inventory quest starters.
- Automatic advancement after acceptance; exclusion of completed objectives.
- Full quest logs, group settings, comfort limits, focus release, stable spawn areas,
  temporary skips, undo, skip expiration, pause and death.
- Negative gossip scoped to the inspected NPC and quest snapshot; shared quests
  cannot invent an NPC coordinate.
- Independent distance, all four cardinal bearings using non-Cartesian world axes,
  another continent, missing positions, owned waypoint cleanup and preserving a
  waypoint selected by the user.
- Updated map markers when an objective's target changes, without repeated replacement
  of an unchanged marker.
- Strict frame API doubles for panel/navigator creation, login and diagnostics.

The package builder validates every TOC dependency, the arrow asset, ZIP CRCs and
the single `Wayfinder/` root. It writes deterministic metadata so the same source
produces the same archive.

`docs/previews/` shows development renders made from the actual frame calls and
synthetic quest data. They help inspect spacing and text regions; they are not
screenshots from the Forever client and use a substitute font.

Live-client testing is still outstanding. In particular, actual database coverage,
quest objective ordering, map/phase placement and native client behavior need the
user's gameplay feedback. Automated scenarios cannot prove those external facts.

## Additional 1.1 regressions

Similar creature names and reordered objectives; buy/search/defeat item instructions;
non-mutating source metadata; invalid/degenerate/recovering map projections; missing
facing; arrival jitter and exit; rejected native waypoint updates; saved display
preference repair; expired undo state; retry/caching of optional modules; idle,
movement and event refresh behavior; recovery after planner failure; actual settings
callbacks; locked/unlocked drags; resume, visible undo, empty-list and compact-mode
behavior; fitting long current titles inside their text allocation.
