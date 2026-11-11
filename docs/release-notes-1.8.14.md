# Trailwarden 1.8.14

- Keep dynamically discovered cave exits available when the entrance has no bundled bounds or reference coordinates.
- Retain a previously validated entrance if a later game POI refresh returns invalid coordinates.
- Continue using direction-only guidance when cave entry or exit cannot be verified safely.

## Verification
- Added regression cases for a discovered cave exit to its parent surface and invalid refreshed POI coordinates.
- Automated travel/access checks, full test suites, provider integration and package validation pass.
- A live World of Warcraft: Forever smoke test remains necessary for in-game map and transit behavior.
