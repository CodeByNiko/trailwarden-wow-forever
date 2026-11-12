# Trailwarden 1.8.0

The complete 1.8 feature line is delivered together as version 1.8.0.

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


## Verification

- Automated checks, release consistency checks, and ZIP packaging are run on the 1.8.0 versioned tree as part of this PR.
