# Trailwarden 1.7.4

A focused readability and layout update for the route guide and navigator.

- Larger objective and instruction text with clearer contrast. Long quest names keep their font size, with full details on hover.
- One current-step card combines the quest, target, progress and navigation distance. Card height follows the actual content; long instructions and safety warnings grow instead of being cut off.
- A slim progress bar and count show how much of the current objective is complete.
- Planned steps separate the quest name from its action and target. Preferences align labels and values for easier scanning.
- The collapsed guide keeps the current quest and fresh distance visible.
- The transparent compass navigator has larger distance and two-line captions. "IN AREA" means you reached the objective area; it does not mark the quest complete.

The route planner, quest priorities and XP calculations are unchanged. Automated frame-layout tests and synthetic previews cover the display changes; final appearance still needs a check in the WoW client.

Extract `Trailwarden-1.7.4-Forever.zip` into `Interface/AddOns` so the path is
`Interface/AddOns/Trailwarden/Trailwarden.toc`. Keep QuestieDB for Forever enabled.
Targets Forever 1.60.1 (Interface 16001).
