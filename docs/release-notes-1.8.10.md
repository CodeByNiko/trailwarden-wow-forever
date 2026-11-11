# Trailwarden 1.8.10

## Changed

- Discover additional cave entrances from a surface Area POI only when it links uniquely to the exact cave UiMapID. The discovered entrance is reused for cave guidance and local-work grouping.
- Keep unknown, ambiguous, or unavailable links in direction-only/manual guidance; never choose a nearest POI or infer entry from proximity.
- Add destination-aware guidance for cross-continent routes. Players use the in-game transport map and refresh after arrival; Trailwarden does not invent boat, zeppelin, or flight paths.
- Update README coverage and limits to distinguish exact game links from the three bundled reference fallbacks.

## Verification

- Travel tests cover dynamic POI discovery, ambiguous-safe selection, work-area reuse, and manual cross-continent guidance.
- Full local check suite and package validation pass for this version before merge.
- Cave interiors, transport timing, and terrain remain unverified in a live game client.
