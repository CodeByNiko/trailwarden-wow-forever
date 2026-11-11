# Trailwarden 1.8.2

## Fixed

- Live objective IDs are now matched to provider entities within the corresponding objective type before text matching is considered.
- Ambiguous live rows no longer inherit completion state from provider order; they remain unresolved and cannot become an automatic target based on a guess.
- A unique one-row/one-entity objective can still match when the client omits IDs and its text is localized or generic.

## Verification

- Added regressions for reversed IDs with generic text and ambiguous rows without IDs.
- Full Lua 5.1 and Lua 5.4 suites and package validation are required before merging this feature.
