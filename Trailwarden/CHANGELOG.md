# Changelog

## 1.8.5
- Reduce unchanged idle navigation, cave access and UI work, and avoid periodic full replans.
- Reuse quest trip order and update partial progress locally while retaining safety checks.
- Coalesce unchanged quest/reputation events and spread automatic candidate and forecast work across timer slices.
- Reduce repeated combat safety allocations; add idle and scheduler regression coverage.

## 1.8.4
- Coalesce rapid world-map toggles and defer expensive work until the map remains closed; make inactive pin cleanup idempotent.
- Hide the main guide during combat, retain the lightweight arrow, and suspend provider queries, route planning and population scans until combat ends.
- Click current or planned active quests to open their exact quest-log entry; shift-click planned rows to focus a route.
- Replace global starter-spawn decoding with a verified, provider-specific compact zone index; use the bounded runtime builder on mismatches or corrections.
- Bound point caches, diagnostic capture and replay retention; reuse immutable field reads within each planning pass without caching errors.
- Add provider compatibility checks, cache generations and public correction/locale hooks; never clear the provider's shared caches.
- Split automatic route selection across timer slices and discard stale work before publishing a complete decision.
- Reduce repeated route scoring, XP projections, navigation copies and noisy event handling; add /tw perf and /tw perfreset diagnostics.
- Test fresh-copy ownership, cold/warm real-provider workloads, index reproducibility, map storms and stale-work cancellation.

## 1.8.3
- Reduce repeated allocations and provider API calls during navigation and combat-safety polling.
- Reuse identical quest XP projections and precompile localized XP message patterns.
- Avoid XP-accounting work on target, mouseover and nameplate events.

## 1.8.2
- Hide the guide, navigator, and route map pins during combat; restore the user's visibility preferences after combat.
- Suspend frequent navigation/UI updates and periodic nameplate safety scans during combat, while keeping lightweight XP sampling and event-based safety observations.
- Coalesce route-affecting changes into a single refresh after combat.

## 1.8.1
- Polish the CurseForge project description and synchronize the bundled documentation with the 1.8 feature set, including language choices, privacy-conscious feedback, manual travel guidance, and beta limits.

## 1.8.0

- Replace the “SET” header label with the standard in-game options gear texture, while keeping an explanatory settings tooltip.
- Add regression coverage for the gear texture and refresh rendered UI previews.

- Give the objective status caption more horizontal space and reduce its font slightly so “Above range” remains visible beside progress.
- Add a regression check for the full high-level objective status label.

- Raise the guide and navigator above ordinary addon panels and make them top-level so they do not disappear behind overlapping addon windows.
- Replace compact header icons with readable settings, collapse, and close controls; add hover feedback and brief tooltips.
- Increase panel background opacity slightly to keep text clear over busy game scenes.

- Update bundled Markdown and plain-text readmes to describe current 1.8 improvements rather than presenting version 1.7.5 as current.
- Check packaged readme release labels during release-consistency validation.

- Verify the official QuestieDB Forever 1.0.14 provider ZIP against its published SHA-256 digest before extraction.
- Guard the install-matrix workflow against removing or reordering the archive verification.

- Give manual cross-continent transit guidance priority over local cave-entrance directions until the player reaches the destination continent.
- Keep the navigation state explicit that a transport connection is needed.

- Load Locale, Diagnostics, and Commands in the fresh provider-integration addon namespace using the runtime TOC order.
- Assert diagnostics, slash-command registration, and absence of runtime output errors before reporting provider smoke success.

- Restore the matched live objective row's text when building monster and item instructions.
- Keep client-provided target wording visible instead of falling back to generic provider instructions.

- Resolve the strongest objective-name match before considering whether that provider entity is already claimed by an ID match.
- Keep a conflicting or already claimed long-name identity unknown instead of assigning its progress to a shorter substring target.

- Build reference XP normalization only from medium-confidence quest-cycle projections.
- Keep uncertain reward forecasts out of the baseline used to compare otherwise reliable routes.

- Fully rerender the quest panel when navigation enters or recovers from an access error, including title, controls, progress, and queue.
- Keep routine live distance updates lightweight when the navigation state is unchanged.

- Guard cave access checks when a dynamically discovered entrance has no reference bounds or coordinates.
- Preserve a previously validated live entrance when a refreshed POI returns invalid coordinates; keep exit guidance conservative.

- Split diagnostics/target explanations and slash-command dispatch out of the event/planning core into dedicated modules.
- Keep the runtime load order explicit and preserve existing command, feedback, and diagnostic behavior.

- Explain why the current target was chosen, how many eligible steps were considered, and up to two other eligible steps.
- Add `/tw feedback`, a local copyable summary containing only release/provider identity and aggregate route counts; omit character names, quest names/IDs, coordinates, preferences and raw errors.
- Keep `/tw debug` and `/tw trace` available for deeper troubleshooting; neither export is transmitted automatically.

- Add persistent automatic, English, and Danish language selection for Trailwarden action labels and map cues.
- Mark entrances and objectives with distinct E/Q glyphs plus concise help so cues remain identifiable without color.
- Keep quest/provider/world names in their original source language and fall back to English for missing catalog entries.

- Discover additional cave entrances only from unique client POIs linked to the exact interior map.
- Explain cross-continent transport needs and require a manual in-game transit choice before refreshing the route.

- Reconcile current README, CurseForge description, validation guidance, and release instructions with the 1.8 feature line.
- Enforce TOC/Common/changelog/release-note version consistency and unique changelog headings before tests and packaging.

- Run provider contract checks against the pinned QuestieDB Forever 1.0.14 release in CI.
- Check required/optional addon declarations and document the installation matrix and in-game smoke log.

- Calibrate quest reward estimates from observed same-level turn-in XP and expose the latest prediction error in diagnostics.
- Keep XP rate influence out of route ranking unless reward and objective-time evidence reach medium confidence.
- Explain low-confidence fallback in the XP hover details.

- Add explicit start-zone coverage and progression edges for Durotar, Mulgore, The Barrens, Tirisfal Glades and Silverpine Forest.
- Validate zone metadata and graph targets; explain when no supported neighboring zone is configured.

- Cache candidate clustering per planner pass and build the remaining queue once per leg instead of once per candidate.
- Shorten only the queue preview above 128 candidates; preserve full evaluation of the primary route.
- Skip candidate collection entirely while paused or dead and expose planner budget data in diagnostics.

- Hold new quest pickups when optional quest-type classification is unavailable; expose a clear Questie guidance message.
- Preserve routing for already accepted quests and the existing combat-safety gates.

- Clear owned pins and waypoints together when navigation or access calculation fails.
- Show a shared retry state across the panel, navigator, map overlay, and map waypoint.

- Match live objectives to provider targets by validated entity ID and objective type, then by unique text.
- Keep ambiguous objective states unknown instead of assigning completion from list order.

- Refresh active quest guidance when the client waypoint changes without objective progress.
- Release a stabilized client waypoint when a newer authoritative waypoint is reported.

## 1.7.5

- Immediately invalidate cached guidance when a quest fails or restarts, including active escorts.
- Never retain a failed quest as fallback guidance after a planner error.
- Treat QuestieDB {-1,-1} positions as unmapped; retain valid alternatives and allow catalog loading when map metadata is unavailable.
- Declare QuestieDB as a required CurseForge dependency.
- Add regression coverage and an optional integration check against the official QuestieDB Forever package.

## 1.7.4

- Increase objective, instruction, queue and navigator text sizes; improve secondary-text contrast.
- Fit the current card to its actual title, target and instruction height, with distance integrated into the card.
- Show a proportional objective progress bar and a numeric count; hide it for steps without counts.
- Separate planned quest names from their action/target, with hover feedback and readable truncation.
- Keep the current quest and fresh distance visible when collapsed.
- Reserve a separate distance field so long collapsed quest names cannot hide it.
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
