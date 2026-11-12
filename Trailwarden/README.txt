TRAILWARDEN 1.8.0 — WORLD OF WARCRAFT: FOREVER

Install the Trailwarden folder in Interface/AddOns. Keep QuestieDB (Forever)
enabled. Questie is strongly recommended. Exit and restart WoW when updating.

Renamed from Wayfinder in 1.7.2. Commands: /tw and /trailwarden.
For existing settings, exit WoW and follow:
https://github.com/CodeByNiko/trailwarden-wow-forever/blob/main/docs/upgrade-to-trailwarden.md

Current 1.8 improvements include a familiar settings gear icon, safer dynamic
cave access, complete guide
refresh after navigation errors, live objective-name and wording accuracy,
conservative XP comparisons, and transport guidance that takes priority over
local cave directions. The guide stays above ordinary addon panels and uses
clearer header controls with brighter button feedback, and a status line that
keeps the full “Above range” label readable. Provider CI verifies the
pinned QuestieDB archive by SHA-256 and exercises runtime modules, diagnostics,
and slash commands.
See the release notes for full details:
https://github.com/CodeByNiko/trailwarden-wow-forever/tree/main/docs


Earlier 1.7.5 behavior: failed quests and tolerates unknown-position
markers when map metadata is unavailable. QuestieDB is required on CurseForge.

Earlier 1.7.4 improved readability, content-sized layout, objective progress,
collapsed guidance, navigator captions and aligned preferences.

Earlier 1.7.1 kept accepted local collection ahead of distant quest objectives,
even when an outside XP estimate is higher. Recent actual quest progress
protects work beyond named caves. Nearby eligible offers remain visible;
escort offers wait for local collection, then precede departure. Once accepted,
follow the escort NPC until completion/failure; do not run toward its endpoint.
Quest data/availability and recognizable event metadata are still required.

1.7 adds cave entrance guidance and map markers, with no additional navigation
addon. Keep Questie and OpenMap enabled for minimap/world-map markers.
Cyan = entrance, gold = objective. Lord Melenas in Fel Rock is approached via
the entrance first. Shadowthread and Ban'ethil also have access records.
Live Forever entrance POIs take priority; fallback says Reference entrance.
Inside recognized caves, use the cave map; unknown tunnel bearings are hidden.
This version does not draw a continuous walking route or route around all
terrain. Even an entrance arrow is direction guidance, not a confirmed path.

Your route resumes from the current character's quest log and completion
history. Accept and turn in quests normally; the route advances from live
quest changes. Arrival alone never completes a quest step.

Drag the panel header and the separate navigator. The custom arrow does not
require Blizzard's native navigation display. It shows target direction,
not a terrain-safe walking path: use roads, bridges and cave entrances.

... opens character settings. Solo mode and +2 comfort level are defaults.
Click a planned step to focus it; Auto route restores automatic selection.
Accepted above-range quests remain visible. Skip for now saves one until it
fits your level range; Later queue entries can be clicked to resume now.
Skip 15 min remains available through /tw skip; /tw undo restores either skip.

Mouse wheel over the header resizes the panel, over the arrow resizes the
navigator. Both scales are independent. Settings offer 0/2/4 planned steps.
The arrow has a transparent background. Locking prevents wheel resizing.

/tw           show/hide panel
/tw arrow     show/hide navigator
/tw routepins toggle Trailwarden entrance/objective map markers
/tw settings  open character preferences
/tw lock      lock/unlock window positions
/tw refresh   explicitly reconsider region and choose an automatic route
/tw rebuild   rebuild the data index
/tw skip      defer current quest for 15 minutes
/tw later     save above-range accepted quest until within level range
/tw undo      undo last skip
/tw scale 80  panel size in percent (60-130)
/tw arrowscale 90  arrow size in percent (60-150)
/tw pause     pause navigation
/tw resume    resume navigation
/tw group     include/exclude known group quests
/tw auto      toggle the native map waypoint
/tw reset     restore window positions
/tw xp        toggle XP-aware route ranking
/tw xpreset   reset current XP session; retain learned pace
/tw debug     copy local diagnostics
/tw trace     copy recent local decisions for replay (before reload/logout)

Automatic combat targets require known enemy levels no more than +2 above you.
Quest level does not override enemy level. Unknown/dangerous sources are held;
an appropriate alternative is preferred if one exists. Group settings and
manual focus do not override the enemy-level cap. Friendly vendors and
noncombat hand-ins are not combat targets.

Visible over-level hostiles can stop navigation until no longer visible.
This is not a danger-free terrain pathfinder; remain aware of surroundings.

Regional batches remain committed while useful mapped work exists. XP events
update measurement without rebuilding the whole plan after each kill. Accepted
quests still advance from real progress. Auto route respects this region;
Replan region now in settings or /tw refresh can reconsider other zones.

XP/h and next-level ETA use actual XP bar gains, including kills and quests.
Travel/downtime count; explicit pause/AFK do not. Five active minutes are
required before measured XP/h and next-level ETA appear.
Quest XP/h is an estimate of the remaining cycle, not a guaranteed rate.
Unknown new quest rewards remain unknown; current Forever data is used.
Short grind suggestions require verified local kill data and a clear advantage.
Hover the two-column XP section for projected quest/grind rates and details. Use Questing now to dismiss a grind break.

Data gaps in Forever can cause missing or inaccurate targets. For unmapped
quests use Questie and the quest text. Progress, preferences and skips belong
to this character; no shaman-specific manual stages are reused on alts.

Source, documentation and releases:
https://github.com/CodeByNiko/trailwarden-wow-forever

