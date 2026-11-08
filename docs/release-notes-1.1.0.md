Wayfinder 1.1.0 polishes the first full version before live gameplay testing.

- Clearer item instructions: buy from a vendor, defeat a creature or search an object.
- Better matching of similar objective names and reordered quest-log objectives.
- Stable arrival states near a target, explicit missing-direction status and safer map markers.
- Fewer full route computations while stationary, with movement/event updates retained.
- Visible Undo skip, empty-plan guidance, adjustable long titles and locked window positions.
- Fixed Resume route behavior and improved local recovery diagnostics.
- 93 automated scenario checks, including the 59 checks from 1.0.

Download **Wayfinder-1.1.0-Forever.zip**. Exit WoW and replace `Interface/AddOns/Wayfinder` with the ZIP's `Wayfinder` folder. Keep QuestieDB for Forever and Questie enabled. Your existing character progress and preferences are retained.

Live-client testing is still outstanding. The direction arrow is not a terrain pathfinder, and some Forever quest/phase data may remain incomplete. `/wf settings` opens preferences; `/wf lock` locks window positions; `/wf debug` opens copyable local diagnostics.

