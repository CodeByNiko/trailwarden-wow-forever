# Trailwarden 1.8.7

## Changed

- Record actual same-level quest turn-in XP and use it for later estimates of that quest.
- Show the latest predicted-versus-observed XP difference in `/tw debug`, including a clear marker for errors of 50% or more.
- Exclude low-confidence XP estimates from route ranking. Normal quest routing remains the fallback until reward and objective-time evidence support medium confidence.
- Clarify estimate confidence in the XP hover details.

## Verification

- Regression coverage checks same-level reward calibration, visible error measurement, and confidence gating.
- Run the full release check suite and package validation before merging this feature.
- Estimates may differ when player level, server multipliers, buffs, or objective time changes; the diagnostic surfaces uncertainty rather than encouraging a low-confidence detour.
