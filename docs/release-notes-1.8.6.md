# Trailwarden 1.8.6

## Changed

- Add the missing Horde start and early progression maps: Durotar, Mulgore, The Barrens, Tirisfal Glades and Silverpine Forest.
- Declare Alliance and Horde start-zone coverage explicitly, validate zone metadata and graph edges, and fail tests when a start or edge target is missing.
- When local opportunities are exhausted in an unmapped area, show that automatic zone continuation is unsupported and direct the player to choose an area manually.

## Verification

- Added start-zone, Horde transition and unsupported-area fallback regressions.
- Full Lua 5.1 and Lua 5.4 suites and package validation are required before merging this feature.
- Zone transition edges are guidance hints; this does not claim terrain-aware walking or live verification of every flight/boat route.
