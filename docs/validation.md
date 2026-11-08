# Validation for 1.4.0

Run `python3 tools/check.py`. The fail-fast suite currently passes **270 checks** and **16 replay frames**:

| Suite | Count | Coverage |
| --- | ---: | --- |
| Client/scenario integration | 154 | Existing 1.0/1.1 regressions, quest truth, profiles, catalog recovery, coordinates, decision ownership, UI callbacks and trace export |
| Pure route engine | 40 | No-client execution, immutable inputs, deterministic ordering, score sums, queue legs, nearby work, Duskwood and Teldrassil journeys, four-quest batching and level-aware deferral |
| Provider/client contracts | 21 | Dot-call signatures, numeric zero/nil semantics, percent spawns, support strings, transient failures, race masks, observations, nullable client rows and shown/total log counts |
| Experience | 55 | XP accounting, level-up ordering/correction, new rewards, full cycles, learning, ranking and grind decisions |
| XP replay | 1 frame | XP-aware unaccepted quest choice through the pure engine |
| Journey replay | 11 frames | Expected decisions reproduced from synthetic serialized inputs |
| Export replay | 4 frames | Exported synthetic integration decisions reproduced |

Local execution uses system Lua 5.4 with test-only Lua 5.1 compatibility globals. GitHub Actions installs Lua 5.1 and repeats all suites before release publication. A failing suite prevents packaging/release. See [XP validation and limits](V1.4-experience.md) and [1.3 regressions](V1.3-live-feedback.md).

Contract fixtures follow primary sources pinned for review:

- [QuestieDB documented API](https://github.com/Questie/QuestieDB/blob/5c14272d61ad2c8d08526b15d633322fc561588e/docs/api.md).
- [Forever quest-log API](https://github.com/Gethe/wow-ui-source/blob/f0da0a9171aa736c8a64d2b3a8ae70195f5d2afb/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

The package builder validates TOC dependencies, arrow asset, ZIP CRCs and the single `Wayfinder/` root. Deterministic metadata produces identical archives from identical inputs.

Development renders in `docs/previews/` come from actual frame calls with synthetic quest data and a substitute font. They support spacing review; they are not in-game screenshots.

Live-client testing remains outstanding. Synthetic scenarios and documented contracts cannot establish actual Forever database coverage, phase placement, transport behavior, or real event timing. `/wf debug` provides current diagnostics and `/wf trace` exports recent local decisions for reproducible follow-up. No real gameplay traces are bundled or claimed.

Audit point 7 (performance profiling/budgets) is intentionally deferred. Existing 1.1 idle/movement regression checks remain, without a new performance claim.

