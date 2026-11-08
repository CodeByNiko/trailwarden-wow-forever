# Trailwarden 1.7.2

Wayfinder is now **Trailwarden** to distinguish it from another WoW addon.

- Renamed addon folder/TOC, Lua namespace, UI frames, map registrations and saved variables.
- Commands are now `/tw` and `/trailwarden`.
- Updated packaging, GitHub links and release automation; added the new logo.
- Routing retains the local-work, nearby-opportunity and escort behavior from 1.7.1.

**Upgrading from Wayfinder:** exit WoW and follow
[the settings migration instructions](https://github.com/CodeByNiko/trailwarden-wow-forever/blob/main/docs/upgrade-to-trailwarden.md)
before replacing the old addon. Settings do not transfer automatically between addon folders.

Extract `Trailwarden-1.7.2-Forever.zip` into `Interface/AddOns` so the path is
`Interface/AddOns/Trailwarden/Trailwarden.toc`. QuestieDB for Forever is required;
Questie and OpenMap are recommended. Targets Forever 1.60.1 (Interface 16001).

Navigation provides directions and access markers, not a continuous walkable route.
Report feedback with `/tw debug` and `/tw trace` at the GitHub issue tracker.
