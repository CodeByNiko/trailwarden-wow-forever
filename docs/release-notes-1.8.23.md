# Trailwarden 1.8.23

- Put the main guide and navigator on the HIGH frame strata and make them top-level so they stay visible when overlapping ordinary addon panels.
- Replace the top settings glyph with a readable SET label, use plain-text collapse/close controls, and give all buttons clearer hover feedback.
- Add short tooltips to the header actions and increase the panel background opacity slightly.

## Verification
- UI regression checks cover frame strata, top-level behavior, and header control labels and sizes.
- Full scenario and engine suites, package validation, and static release checks pass.
- A live World of Warcraft: Forever smoke test is still needed to inspect frame layering with the user's installed addon collection and actual client rendering.
