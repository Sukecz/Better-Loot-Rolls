# Better Loot Rolls

Better Loot Rolls is a lightweight group-loot history window for World of
Warcraft Classic Era, Classic Hardcore, and TBC Classic Anniversary. It
presents the same server-provided roll information as Blizzard's `/loot`
window in a movable, fully resizable view.

The included Better Loot Rolls artwork is used in the WoW addon list and in the
addon metadata. The in-game roll window uses a compact icon-only header to keep
the focus on loot information.

For each recent item it shows:

- the item icon and link;
- every participating player with class color;
- Need, Greed, Disenchant, Pass, or waiting state;
- each completed roll value;
- a clear winner marker.

The default history contains the last 20 completed items and can be set from 5
to 100. Active rolls are always shown above completed history. Better Loot
Rolls is deliberately not a long-term loot archive and does not collect
statistics.

The addon only observes `C_LootHistory`. It does not alter Blizzard's `/loot`
window and never automates a loot choice.

## Installation

Copy the addon as `BetterLootRolls` into the matching client:

```text
World of Warcraft/_classic_era_/Interface/AddOns/BetterLootRolls/
World of Warcraft/_classic_/Interface/AddOns/BetterLootRolls/
```

After logging in, use `/blr` to toggle the window.

## Commands

- `/blr` — toggle the roll window;
- `/blr options` — open options;
- `/blr history 20` — keep the chosen number of completed rolls (5–100);
- `/blr clear` — clear completed history;
- `/blr reset` — reset window position, size, and scale;
- `/blr api` — print a compact client/API compatibility report.

The window can be moved by dragging its title area and resized from its
bottom-right corner. Position, size, scale, history limit, and recent rolls are
stored account-wide.

## Current verification status

The source targets Classic Era interface `11509` and TBC interface `20506`,
using the shared `C_LootHistory` API shapes present in Era 1.15.9 and TBC
2.5.6. Offline Lua 5.1 and model tests are included. In-game verification in
both clients is still required before a stable release.

## Support

Source code and issue tracking:

https://github.com/Sukecz/Better-Loot-Rolls

## Development

Run the local checks with:

```bash
bash tests/run.sh
```
