# Trailwarden 1.8.12

## Changed

- Hover the current target to see why it was selected, how many eligible steps were considered, and up to two other eligible steps with their distance.
- Add `/tw feedback` for a reviewable, copyable summary of addon/provider versions and aggregate planner counts.
- The feedback summary omits character identity, quest names and IDs, exact location/progress, saved preferences, and raw error text. It stays local until the player chooses to share it. `/tw debug` and `/tw trace` remain available and contain more detailed information; review those before sharing.

## Verification

- Feedback export checks verify allowlisted output and absence of synthetic private names, quest IDs, exact coordinates, preferences, and raw text.
- Planner/UI scenario checks verify the current reason and alternate eligible steps appear in the target explanation.
- Full release checks and ZIP package validation pass before merge. Live-client tooltip and copy-field review remain part of the in-game smoke check.
