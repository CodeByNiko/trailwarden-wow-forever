# Trailwarden 1.8.2

- Hide the guide, navigator, and Trailwarden route pins during combat; restore the user's saved visibility preferences afterward.
- Pause frequent navigation/UI refreshes and periodic nameplate safety scans during combat, while retaining lightweight XP sampling and event-based safety observations.
- Defer route-affecting events during combat and perform a single refresh when combat ends.

## Verification

- The full `python3 tools/check.py` suite passes, including combat visibility, deferred refresh, and paused periodic-work regression checks.
- Release consistency checks pass and the generated Forever ZIP is valid and directly installable.
- Live World of Warcraft testing is still needed to confirm combat event behavior and assess the reported FPS issue on the affected setup.
