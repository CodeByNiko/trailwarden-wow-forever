# Wayfinder 1.7.0 — cave access and OpenMap guidance

A scoped release for live testing, with no additional navigation addon. Keep QuestieDB, Questie and your existing OpenMap enabled.

- **Entrance first:** for Lord Melenas in Fel Rock, the arrow and native waypoint guide toward the cave entrance instead of the underground target's hillside projection.
- **Map/minimap markers:** cyan identifies the entrance; gold identifies the quest objective. OpenMap shows the world-map markers through its existing HereBeDragons integration.
- **Three access records:** Fel Rock, Shadowthread Cave and Ban'ethil Barrow Den. Live Forever entrance POIs take priority; a historical fallback is labeled Reference entrance.
- **Inside caves:** the guide switches to cave-map guidance instead of inventing a bearing through tunnel walls. Actual cave/subzone evidence is required; proximity does not complete a quest or advance a cave stage.
- **Client compatibility:** correct callable-table LibStub detection, automatic retry of temporary map failures, and `/wf debug` details for access stage, entrance source and map pins.
- **Existing behavior:** ordinary quest routing, per-character progress, quest batching and 1.6 combat restrictions remain.

**Scope:** this version displays access/objective markers, not a continuous walking-route line. Even the entrance arrow is direction guidance, not a verified approach corridor. Unknown roads, cave tunnels and terrain still require map reading. Full terrain routing is a later phase.

Install: exit WoW, replace Interface/AddOns/Wayfinder with the folder in Wayfinder-1.7.0-Forever.zip, then restart. Existing progress and settings are retained. Markers default on; `/wf routepins` toggles them. OpenMap also has a Wayfinder access-points menu toggle.

First test: use Twisted Hatred outside Fel Rock, follow the cyan entrance guidance, check the indoor/cave-map transition, and confirm actual quest progress still advances the plan. If behavior differs, copy `/wf debug` and note your coordinates and nearest entrance.

Validation: 368 synthetic checks and 37 replay frames. Live-client validation is not claimed.
