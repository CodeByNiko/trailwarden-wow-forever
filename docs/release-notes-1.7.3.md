# Trailwarden 1.7.3

This update polishes the route display and makes modeled quest cycles less prone to backtracking.

- The main guide is narrower and shorter, with a clearer next-step card, objective progress and a calmer preview of upcoming steps.
- The navigator uses a new compass-style arrow and more deliberate spacing.
- Live XP/hour and next-level time appear after five active minutes, so a brief sample does not dominate the display.
- Quest-cycle estimates improve the initial nearest-target order with a two-opt pass, and reject invalid negative work values instead of letting them distort the estimate.
- Existing local-work, current-region, cave/interior and escort priorities remain in place.

The arrow is still directional guidance. It does not calculate a verified path around terrain.

Extract `Trailwarden-1.7.3-Forever.zip` into `Interface/AddOns` so the path is
`Interface/AddOns/Trailwarden/Trailwarden.toc`. QuestieDB for Forever is required;
Questie and OpenMap are recommended. Targets Forever 1.60.1 (Interface 16001).
