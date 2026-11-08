# Validation for 1.7.1

**409 checks and 40 replay frames** pass: 189 scenario/client, 70 pure engine, 21 provider/client, 56 XP, 36 combat safety and 37 access/map checks. Three new replay frames cover cave collection, last-item persistence and release after local completion.

New synthetic integration tests reproduce Ban'ethil local collection versus Crown of the Earth, a closer outside item source, a remaining quest item, an eligible unaccepted Forever escort, discovery from a cave floor, accepted escort guidance and completion. Separate checks cover progress retention in an unnamed interior, missing-safe-source review and leaving an area. Engine tests challenge the policy with exaggerated outside XP, stale previous goals, floor maps, skips, manual focus, danger and unsafe targets. No successful real-client behavior is claimed yet.

The runtime policy uses area/progress/event metadata rather than quest IDs. The real quest ID 99053 appears only in a provider-contract-shaped test fixture, based on current public QuestieDB Forever records; the original screenshot alone does not establish the user's installed database version or exact eligibility gate.

# Validation for 1.7.0

The scoped OpenMap access release passes **368 checks and 37 replay frames**: 171 client/scenario, 49 pure engine, 21 provider/client, 56 experience, 36 combat safety and 35 access/map checks. Access tests cover live POI precedence, reference fallback, cave-stage truth, preserved arrival instructions, inverse map transforms, real callable-table LibStub lookup, HBD colon-call signatures, pin ownership, marker reuse and recovery from transient map errors.

`python3 tools/check.py` runs all suites. The installable package is checked for TOC files, media, ZIP CRCs and a single Wayfinder/ root. Two builds from the same inputs must be byte-identical. Frame renders include cave-access guidance and show synthetic data, not actual gameplay.

No test establishes real terrain connectivity or successful cave navigation. The accepted 1.7 scope is entrance-first guidance plus minimap/OpenMap markers, **without a continuous walking polyline**. Live validation is next; see [scope and test notes](V1.7-openmap-navigation.md).

## Retained 1.6 coverage


Run `python3 tools/check.py`. The fail-fast suite currently passes **332 checks** and **37 replay frames**:

| Suite | Count | Coverage |
| --- | ---: | --- |
| Client/scenario integration | 170 | Existing 1.0/1.1 regressions, quest truth, profiles, catalog recovery, coordinates, decision ownership, UI callbacks and trace export |
| Pure route engine | 49 | No-client execution, immutable inputs, deterministic ordering, score sums, queue legs, nearby work, Duskwood and Teldrassil journeys, four-quest batching and level-aware deferral |
| Provider/client contracts | 21 | Dot-call signatures, numeric zero/nil semantics, percent spawns, support strings, transient failures, race masks, observations, nullable client rows and shown/total log counts |
| Experience | 56 | XP accounting, level-up ordering/correction, new rewards, full cycles, learning, ranking and grind decisions |
| Combat safety | 36 | Source level/rank checks, live corrections, held goals and navigation interlocks |
| Safety replay | 1 frame | Live level-29 danger overrides a committed goal |
| XP replay | 1 frame | XP-aware unaccepted quest choice through the pure engine |
| Journey replay | 31 frames | Expected decisions reproduced from synthetic serialized inputs |
| Export replay | 4 frames | Exported synthetic integration decisions reproduced |

Local execution uses system Lua 5.4 with test-only Lua 5.1 compatibility globals. GitHub Actions installs Lua 5.1 and repeats all suites before release publication. A failing suite prevents packaging/release. See [combat-level review](V1.6-combat-safety.md), [stability review](V1.5-stability.md), [XP validation and limits](V1.4-experience.md) and [1.3 regressions](V1.3-live-feedback.md).

Contract fixtures follow primary sources pinned for review:

- [QuestieDB documented API](https://github.com/Questie/QuestieDB/blob/5c14272d61ad2c8d08526b15d633322fc561588e/docs/api.md).
- [Forever quest-log API](https://github.com/Gethe/wow-ui-source/blob/f0da0a9171aa736c8a64d2b3a8ae70195f5d2afb/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

The package builder validates TOC dependencies, arrow asset, ZIP CRCs and the single `Wayfinder/` root. Deterministic metadata produces identical archives from identical inputs.

Development renders in `docs/previews/` come from actual frame calls with synthetic quest data and a substitute font. They support spacing review; they are not in-game screenshots.

Live-client testing remains outstanding. Synthetic scenarios and documented contracts cannot establish actual Forever database coverage, phase placement, transport behavior, or real event timing. `/wf debug` provides current diagnostics and `/wf trace` exports recent local decisions for reproducible follow-up. No real gameplay traces are bundled or claimed.

Audit point 7 (performance profiling/budgets) is intentionally deferred. Existing 1.1 idle/movement regression checks remain, without a new performance claim.

