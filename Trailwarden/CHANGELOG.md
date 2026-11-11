# Changelog

## 1.7.4

- Increase objective, instruction, queue and navigator text sizes; improve secondary-text contrast.
- Fit the current card to its actual title, target and instruction height, with distance integrated into the card.
- Show a proportional objective progress bar and a numeric count; hide it for steps without counts.
- Separate planned quest names from their action/target, with hover feedback and readable truncation.
- Keep the current quest and fresh distance visible when collapsed.
- Align preference labels and values, and let long instructions and warnings grow without clipping.
- Retain the transparent compass pointer with larger distance and two-line captions; arrival reads "IN AREA".

## 1.7.3

- Fix non-terminating multi-goal forecasts, bound route optimization and reject malformed/non-finite projection data.
- Invalidate forecast models immediately when objective progress changes; never show an old navigator bearing for a new decision.
- Size the panel to the actual preview, hide the entire body when collapsed, retain warnings alongside nearby offers, and keep long titles readable.
- Rework the route panel into a narrower, shorter hierarchy with clearer objective progress and less diagnostic clutter.
- Replace the navigator pointer with a compact compass needle and improve its spacing and labels.
- Wait for five active minutes before showing the live XP rate and next-level ETA, avoiding misleading short-session projections.
- Improve modeled quest-cycle travel ordering with a two-opt pass after the initial nearest-objective route; reject invalid negative work inputs.
- Keep the current-region, local-work, cave/interior and escort priorities from 1.7.1 intact.

## 1.7.2

- Rename to Trailwarden across the addon, commands, settings, map registration and release packaging.
- Add one-time settings migration instructions and a copy utility that preserves the original.
- Retain the 1.7.1 routing behavior.

## 1.7.1

- Protect unfinished local work against remote objectives as well as town returns; XP cannot override the boundary.
- Capture cave/interior context before selection and resolve floor maps to their parent quest region.
- Prefer an eligible known source inside the current cave over a nearer outside source.
- Learn temporary work focus from actual quest progress, including unmapped interiors; review unavailable safe targets rather than silently leave.
- Retain nearby eligible pickup opportunities, including Forever escort offers; show their names in the existing status area.
- Defer starting escorts until local work is done, then consider them before leaving.
- Keep accepted escorts active without an endpoint bearing until completion/failure, using provider event metadata.
- Preserve safety, explicit skips/focus and deterministic replay; no quest-ID exceptions in runtime policy.
- 409 checks and 40 replay frames; live confirmation remains outstanding.

## 1.7.0

- Separate quest target from cave access target.
- Prefer live Forever entrance POIs, with labeled reference locations as fallback.
- Add entrance/objective pins through HereBeDragons and OpenMap menu integration.
- Suppress unsupported direct tunnel guidance; preserve quest-giver arrival instructions.
- Fix real-client callable-table LibStub lookup; retry transient map-pin failures.
- No additional navigation addon dependency; scoped entrance/map-marker release, without a continuous walking line.
- Preserve 1.6 combat-safety and quest-batching behavior.
- 368 checks and 37 replay frames; live-client confirmation remains outstanding.
- See docs/V1.7-openmap-navigation.md for live-test instructions and explicit limits.

## 1.6.0

- Require known enemy levels within +2 of the player for automatic combat destinations.
- Filter drop sources and kill-credit alternatives before distance/XP ranking.
- Prevent client/extra-objective coordinates and manual focus from bypassing combat checks.
- Hold blocked/unknown combat objectives visibly and reconsider after level/data changes.
- Let fresh hostile observations raise provider levels; stop navigation for visible over-level threats.
- Invalidate committed sources/cached forecasts after risk changes; clear owned waypoints on danger.
- Keep high-level friendly vendors and completed noncombat hand-ins available.
- Require suitable observed enemy evidence before automatic grind suggestions.
- 332 checks and 37 replay frames, including the level-22 / quest-25 / enemy-29 regression.

## 1.5.0

- Separate XP event measurement, live step progression and regional planning.
- Commit to a viable regional batch and unfinished objective instead of reacting to every XP estimate.
- Reuse forecasts for 45 seconds; invalidate when goals, eligibility, catalog or travel materially change.
- Coalesce quest events, ignore identical log updates and reduce idle/movement refresh churn.
- Isolate XP sampling, learning, forecasting and per-quest target failures from the guide.
- Preserve only freshly revalidated guidance after planner errors; never retain a completed objective.
- Redesign XP display as labeled two-column metrics, with projections in the tooltip.
- Add explicit regional replan in settings; Auto route keeps current region.
- 291 checks and 36 replay frames, including a 20-kill/level-up zone-stability journey.

## 1.4.0

- Measure rolling/session XP per hour from actual bar deltas and estimate time to next level.
- Handle level-up ordering, pause/AFK, source attribution, character changes and session reset.
- Project complete remaining quest cycles for accepted and eligible unaccepted Forever quests.
- Learn movement/progress timing; use current provider rewards and keep unknown data explicit.
- Combine nearby accepted work and shared hand-ins without duplicating rewards or common sources.
- Rank modeled cycles by conservative XP return while retaining local batching and manual focus.
- Compare verified local kill XP with quest estimates and offer bounded, dismissible grind breaks.
- Add compact XP lines, tooltips, XP-aware routing setting and /tw xp /tw xpreset.
- 270 checks and 16 replay frames; live-client verification remains outstanding.

## 1.3.0

- Keep accepted above-range quests available instead of applying pickup comfort filters.
- Add Skip for now / Later entries with automatic level/range reactivation, manual resume and undo.
- Read standard quest capacity from the Forever API instead of assuming 25.
- Prioritize local accepted objectives before outbound hand-ins/pickups; retain each objective in the queue.
- Ignore skipped/deferred work when evaluating local batches; allow explicit manual focus.
- Reduce panel dimensions, default to two preview rows, and add independent scale controls.
- Remove navigator background/header; retain draggable arrow, distance and quest caption.
- Expand verification to 208 checks and 15 replay frames.

## 1.2.0

- Distinguish eligible, blocked and unknown quests; expire live offers after progress changes.
- Validate saved profiles and repair malformed nested data.
- Build catalogs transactionally, retain published data on failure and retry with bounds.
- Separate percent and normalized coordinates; validate observation age, provider and entity identity.
- Commit one decision for panel, navigation and map; isolate route selection from live reads.
- Score each queue leg from its predecessor; preserve nearby unfinished work.
- Add local decision trace/replay, provider/client contracts and whole-character journeys.
- 165 automated checks plus 14 replay frames. Performance profiling remains deferred.

## 1.1.0

- Match similar objective names by specificity, including reordered live rows.
- Explain whether an item is bought, looted from a creature or searched for in an object.
- Stabilize arrival states and show missing facing explicitly.
- Reject non-finite/degenerate map data and clear owned markers after rejected updates.
- Avoid full idle planning every two seconds while retaining event and movement updates.
- Reuse successful module imports; recover from temporary missing modules.
- Add visible Undo skip, empty-plan guidance, window locking and `/tw settings`.
- Fix Resume route, bound long titles, repair invalid saved display preferences,
  and improve recovery diagnostics.
- Expand automated coverage from 59 to 93 checks.

## 1.0.0

- Replaced character-specific zone fallbacks with a common live quest planner.
- Added GUID-scoped profiles, retained turn-in history, and migration from 0.3.
- Added race/class/level/chain/exclusivity checks and solo/group comfort settings.
- Added NPC/object pickup and turn-in routing, item-source objectives, kill credit,
  delivery steps, quest events, client-waypoint fallback and quest-starting items.
- Added local pickup batching, area clustering, completion-aware queue updates,
  quest-log capacity handling, focused steps, hysteresis and temporary quest skips.
- Added live gossip observations and snapshot-scoped missing-offer suppression.
- Rebuilt the panel with bounded text regions, four planned steps, tooltips,
  compact mode, character settings, scale and saved panel position.
- Replaced native-navigation dependence with an original draggable arrow texture,
  independent map-derived distances, calibrated map axes and explicit arrival states.
- Added safe handling for missing positions, another continent, death, pause and
  user-owned map waypoints.
- Added diagnostics, scenario verification and reproducible release packaging.

## 0.3.0

- Introduced the custom movable arrow and dynamic pickup queue.
- Imported Questie's ZoneDB through its module loader.

## 0.2.1

- Corrected Forever UI map IDs.

## 0.2.0

- Focused the interface on routing and automatic map waypoints.

## 0.1.0

- Initial installable foundation.
