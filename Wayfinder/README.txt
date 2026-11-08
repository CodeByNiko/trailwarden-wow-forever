WAYFINDER 1.5.0 — WORLD OF WARCRAFT: FOREVER

Install the Wayfinder folder in Interface/AddOns. Keep QuestieDB (Forever)
enabled. Questie is strongly recommended. Exit and restart WoW when updating.

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
Skip 15 min remains available through /wf skip; /wf undo restores either skip.

Mouse wheel over the header resizes the panel, over the arrow resizes the
navigator. Both scales are independent. Settings offer 0/2/4 planned steps.
The arrow has a transparent background. Locking prevents wheel resizing.

/wf           show/hide panel
/wf arrow     show/hide navigator
/wf settings  open character preferences
/wf lock      lock/unlock window positions
/wf refresh   explicitly reconsider region and choose an automatic route
/wf rebuild   rebuild the data index
/wf skip      defer current quest for 15 minutes
/wf later     save above-range accepted quest until within level range
/wf undo      undo last skip
/wf scale 80  panel size in percent (60-130)
/wf arrowscale 90  arrow size in percent (60-150)
/wf pause     pause navigation
/wf resume    resume navigation
/wf group     include/exclude known group quests
/wf auto      toggle the native map waypoint
/wf reset     restore window positions
/wf xp        toggle XP-aware route ranking
/wf xpreset   reset current XP session; retain learned pace
/wf debug     copy local diagnostics
/wf trace     copy recent local decisions for replay (before reload/logout)

Regional batches remain committed while useful mapped work exists. XP events
update measurement without rebuilding the whole plan after each kill. Accepted
quests still advance from real progress. Auto route respects this region;
Replan region now in settings or /wf refresh can reconsider other zones.

XP/h and next-level ETA use actual XP bar gains, including kills and quests.
Travel/downtime count; explicit pause/AFK do not. The first minute collects data.
Quest XP/h is an estimate of the remaining cycle, not a guaranteed rate.
Unknown new quest rewards remain unknown; current Forever data is used.
Short grind suggestions require verified local kill data and a clear advantage.
Hover the two-column XP section for projected quest/grind rates and details. Use Questing now to dismiss a grind break.

Data gaps in Forever can cause missing or inaccurate targets. For unmapped
quests use Questie and the quest text. Progress, preferences and skips belong
to this character; no shaman-specific manual stages are reused on alts.

Source, documentation and releases:
https://github.com/CodeByNiko/wayfinder-wow-forever

