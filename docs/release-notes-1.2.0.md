Wayfinder 1.2.0 strengthens the existing foundation through audit points 1–6.

- Confirmed, blocked and unknown quest states prevent stale offers or partial data from inventing availability.
- Safer per-character saved data and transactional quest indexes with bounded recovery.
- Explicit coordinate units and expiring, identity-checked interaction observations.
- One committed decision shared by the guide, arrow and map marker.
- More coherent local questing: finish nearby work and evaluate each planned leg from its preceding stop.
- Copyable local `/wf trace` exports, deterministic replay, client/provider contracts and Duskwood/Teldrassil journey checks.

165 automated checks and 14 replay frames pass locally. GitHub Actions repeats the release checks under Lua 5.1 before publication. Actual live-client testing remains outstanding; synthetic fixtures cannot establish Forever database coverage or phase placement. Point 7 (performance profiling and budgets) is intentionally deferred.

Download **Wayfinder-1.2.0-Forever.zip**. Exit WoW and replace `Interface/AddOns/Wayfinder` with the included `Wayfinder` folder. Retain your saved variables and keep QuestieDB for Forever / Questie enabled. Use `/wf debug` for diagnostics and `/wf trace` to copy recent decisions before reload/logout. Nothing is uploaded automatically.
