# Trailwarden 1.8.11

## Changed

- Add per-character `/tw language auto|en|da` selection for Trailwarden's action labels and map cues. Existing profiles default safely to automatic English unless the client locale is Danish.
- Mark entrance and objective pins with large **E** and **Q** glyphs as well as their existing colors. Tooltips explain each marker and warn that a destination marker is not a walking path.
- Keep QuestieDB quest text and game world names unchanged. Missing catalog entries fall back to English.

## Verification

- Localization checks cover locale selection, fallback behavior, and caller-owned quest/provider text.
- Travel UI checks cover distinct entrance/objective glyphs independent of marker color, alongside existing map pin behavior.
- Full release checks and ZIP package validation are run before merge. Actual in-game font rendering and screen-reader behavior require the game client.
