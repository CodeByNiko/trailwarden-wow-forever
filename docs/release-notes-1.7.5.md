# Trailwarden 1.7.5 — quest update reliability

- Failed quests and escorts release guidance on the next quest-log update, without waiting for the one-minute idle refresh. Restarting the quest immediately restores eligibility.
- Planner-error recovery cannot preserve a failed quest.
- Unknown-position markers in QuestieDB are skipped without discarding valid positions or failing catalog loading when map metadata is unavailable.
- CurseForge packages declare QuestieDB as required. Use its Forever version; Questie and OpenMap remain recommended separate addons.

Existing character settings and progress remain in TrailwardenDB. No settings reset or manual migration is required from 1.7.2–1.7.4. Previously published archives are retained.

Regression checks and integration with the real QuestieDB 1.0.14 dataset are covered in [the quality review](quality-review-2026-11-11.md). Client APIs in automated checks are simulated; an in-game smoke test remains necessary.
