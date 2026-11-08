WAYFINDER 1.2.0 — WORLD OF WARCRAFT: FOREVER

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
Skip 15 min defers a missing or unwanted quest; /wf undo restores it.

/wf           show/hide panel
/wf arrow     show/hide navigator
/wf settings  open character preferences
/wf lock      lock/unlock window positions
/wf refresh   rescan and choose an automatic route
/wf rebuild   rebuild the data index
/wf skip      defer current quest for 15 minutes
/wf undo      undo last skip
/wf pause     pause navigation
/wf resume    resume navigation
/wf group     include/exclude known group quests
/wf auto      toggle the native map waypoint
/wf reset     restore window positions
/wf debug     copy local diagnostics
/wf trace     copy recent local decisions for replay (before reload/logout)

Data gaps in Forever can cause missing or inaccurate targets. For unmapped
quests use Questie and the quest text. Progress, preferences and skips belong
to this character; no shaman-specific manual stages are reused on alts.

Source, documentation and releases:
https://github.com/CodeByNiko/wayfinder-wow-forever
