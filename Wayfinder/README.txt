WAYFINDER 0.3.0 — ROUTE COMPANION FOR WOW: FOREVER

Wayfinder focuses on choosing useful quest hubs and guiding you to them. It is
not a speed-leveling addon and does not duplicate Questie's quest tracker.

INSTALL
1. Install the Forever-compatible Questie release (QuestieDB is its required database addon).
2. Extract the Wayfinder folder into the game client's Interface/AddOns directory.
3. Enable Wayfinder and Questie at the character-select AddOns screen.
4. Log in. Wayfinder opens automatically and starts choosing a route.

HOW ROUTING WORKS
• Active quest waypoints are preferred. Wayfinder reads your live quest log,
  objective waypoints and completed quest records, then updates as you progress.
• When there is no usable active waypoint, it looks for eligible quest givers
  from QuestieDB and favors nearby hubs with several level-appropriate quests.
• Questie remains the source of quest tracking and map markers; Wayfinder gives
  a route recommendation and can list a few nearby pickup stops.
• The Blizzard navigation arrow automatically points to the selected waypoint
  while Auto arrow is on. This uses WoW's user waypoint and may replace the
  currently tracked user waypoint. Toggle Auto arrow off to pause it.
• A separate, draggable on-screen navigator arrow points to the current route
  destination and shows its name and distance.
• In WoW Forever, enable Options > Interface > Display > In Game Navigation to
  show Blizzard's on-screen navigation arrow.

CONTROLS
• Drag the header to move the window.
• X hides the window; /wf shows or hides it.
• Refresh route rescans current progress and route data.
• Navigator · On/Off shows or hides the custom arrow; drag it to reposition.
• /wf arrow toggles the custom arrow. /wf auto toggles native waypoint tracking.

CURRENT LIMITS
The first route pack is a foundation. Dynamic pickup routing depends on QuestieDB
having quest giver and spawn data that maps to a WoW map. Some quests may be
excluded when their source data is incomplete, and route quality can vary by
Forever-specific changes. When no dynamic location is available, Wayfinder uses
its included zone recommendations. Please share in-game feedback so the data
and routing priorities can be tuned against the Forever server.

When a pickup route is active, Wayfinder lists the next quests to accept at the
current nearby hub. It moves the route forward after a quest is accepted, and
changes the instruction from travel to accept when you reach the quest giver.

This addon does not contain or redistribute Questie data.
