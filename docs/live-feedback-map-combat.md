# Live feedback: map, combat and quest navigation

Development branch from main at ba98bf6. No PR or release requested yet.

## Changes

- Accept boolean and numeric combat flags and check live combat state every 0.1 seconds as an event fallback. Hide the guide in combat and restore the saved preference afterward.
- Retain the arrow during combat using the last validated access target, with fresh bearing and distance. Suspend route planning, provider/access queries, map-waypoint writes and population scans during combat.
- Coalesce nameplate and mouseover events into periodic safety sampling instead of rescanning the entire visible population for every event. Target changes outside combat still receive immediate safety checks.
- Defer quest capture, access and waypoint work while the world map is visible. Coalesce pending captures after closure. Make inactive map-marker cleanup idempotent and avoid deep-copying forecast data on each navigation tick.
- Click the current quest card or a planned quest to open the exact active quest in the log. Shift-click a planned row to retain manual route focus. Unaccepted quests do not select an unrelated log entry.

## Verification

Automated coverage includes numeric combat flags without regen events, guide/arrow visibility, deferred combat work, nameplate bursts, rapid map toggles, inactive map-marker cleanup and exact quest-log selection. Full release checks pass locally.

The code exposes repeated work consistent with the reported symptoms, but the user's FPS drops have not been reproduced in a live WoW client. Confirm combat hiding, arrow behavior, quest selection and repeated map toggles with the affected addon set and view distance before release. The branch retains version 1.8.3 pending further feedback and release preparation.

## Second map-performance iteration: map-quiet-2

- Map show/hide hooks restart a 0.75-second quiet period, including toggles between update frames. Polling remains as a fallback. During repeated map toggles, defer quest capture, full navigation, safety scanning and waypoint/map-pin updates until the map stays closed.
- Gate immediate target safety scans and combat-exit capture during this quiet period as well. Preserve deferred changes for one catch-up update after settling.
- Prune saved profile caches before deep-copying replay input instead of copying and then discarding them.
- `/tw perfreset` resets local event/work counters; `/tw perf` displays them without capturing the character or starting a new route plan. The output identifies this test build as `map-quiet-2`.

The full suite passes, including 100 map cycles mixed with 8,000 nameplate events: zero quest captures, full navigation updates and safety scans between toggles, with one deferred quest capture after the final close. This is a deterministic workload check, not a reproduction of the reported 15% live CPU reading or an FPS measurement.

Live comparison: install the new test package and restart WoW; run `/tw perfreset`, reproduce the rapid M toggles, wait two seconds after the last close and run `/tw perf`. Record the displayed counters and CPU reading together. Repeat with the reported view-distance setting. No PR or release has been made.
