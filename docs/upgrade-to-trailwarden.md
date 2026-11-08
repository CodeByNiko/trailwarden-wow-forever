# Upgrade from Wayfinder to Trailwarden

Trailwarden 1.7.2 is the renamed continuation of this project's Wayfinder 1.7.1.
The new addon has its own folder, global namespace, saved-variable name, UI frames,
map registrations and `/tw` or `/trailwarden` commands. It does not register the
old `/wf` or `/wayfinder` commands, so it can coexist with unrelated addons.

## Preserve your settings

1. Exit WoW completely. Back up your `WTF` folder.
2. Before launching Trailwarden for the first time, open
   `WTF/Account/<account>/SavedVariables/Wayfinder.lua` in a text editor.
3. Confirm it belongs to this project's addon: it begins with `WayfinderDB = {`
   and contains a `["profiles"]` table. Save a **copy** as `Trailwarden.lua` in
   the same directory, changing only the first `WayfinderDB` to `TrailwardenDB`.
   Keep the original file. Repeat for each account you use.
4. Remove this project's old `Interface/AddOns/Wayfinder` folder and extract the
   release's `Trailwarden` folder into `Interface/AddOns`. Do not remove an
   unrelated addon that happens to use the old name.
5. Start WoW with QuestieDB enabled. Use `/tw` to open the guide. Check your
   display preferences and character progress before deleting any backups.

If you have Python installed, steps 2–3 can instead be performed from the source
checkout with `python tools/migrate_settings.py "C:/path/to/WoW/WTF"`. The utility
copies recognized account settings, leaves original files untouched and refuses
to overwrite an existing `Trailwarden.lua`.

If you have already launched Trailwarden, back up its settings too before deciding
which file to keep. The utility deliberately does not merge or replace them.

WoW will not automatically load a different addon's settings file after a folder
rename. Without this one-time copy, Trailwarden starts with default preferences.
Quest completion reported by the server is still read normally.

Historical release notes retain the Wayfinder name because their archives were
published under that name. Install the latest Trailwarden release for new use.
