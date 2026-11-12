# Planner performance budget

## Behavior

- Trailwarden evaluates every eligible candidate for the primary route; it does not silently drop active quests or database offers to meet a count limit.
- At 128 candidates or fewer, the optional queue preview can contain up to four follow-up steps.
- Above 128 candidates, the selector keeps full primary-route scoring and reduces the optional queue preview to one follow-up step. This bounds redundant work while keeping the selected action intact.
- Paused/dead decisions bypass provider candidate enumeration and XP forecast work.
- `/tw debug` records the candidate count, score evaluations and whether the preview was shortened.

## Synthetic baseline

Run `python3 tools/run_lua.py tools/benchmark_planner.lua`. The benchmark reports the median of seven selector-only runs in the local Lua 5.4 runtime; it does not measure WoW frames or player hardware.

| Candidates | Median selector time |
| ---: | ---: |
| 40 | 2.47 ms |
| 80 | 9.67 ms |
| 128 | 23.47 ms |
| 160 | 17.86 ms |
| 320 | 67.61 ms |

The lower 160-candidate timing relative to 128 reflects the one-step preview threshold. This is a regression guard and planning budget, not a claim of a live frame-time guarantee. Re-run the benchmark after selector changes and validate real client timing before making a hardware performance claim.
