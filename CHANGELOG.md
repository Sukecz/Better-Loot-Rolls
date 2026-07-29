# Changelog

All notable changes to Better Loot Rolls will be documented in this file.

## [Unreleased]

### Changed

- Reworked the main roll window into a compact modern panel with a minimal
  icon-only header and denser item and player rows.
- Reduced the minimum window width and tightened the player, choice, and
  three-digit roll columns for narrow layouts.
- Removed nested item-card borders and replaced the standard Blizzard scrollbar
  with a minimal left-side scroll indicator.
- Corrected the left scrollbar direction and enlarged its thumb and clickable
  area for easier dragging.
- Loot entries now start collapsed and can be expanded individually to show
  player choices and roll details.
- Collapsed entries now summarize roll progress, the winning player and roll,
  or an all-passed result.
- Expanded entries remain open when an active roll becomes completed.
- Added configurable window opacity with a live preview in the options panel.
- Reorganized options into clear history and appearance sections with visible
  scale and opacity values.
- Added a one-time welcome hint pointing new users to `/blr options`.

## [0.1.0-alpha.2] - 2026-07-28

### Added

- Shared Classic Era/Hardcore and TBC Classic Anniversary support.
- CurseForge project metadata for automated alpha publication.

## [0.1.0-alpha.1] - 2026-07-28

### Added

- Initial Classic Era addon project structure.
- Movable and fully resizable recent-roll window.
- Live Need, Greed, Disenchant, Pass, roll value, and winner display.
- Account-wide bounded history with a configurable 5–100 item limit.
- Options for automatic opening, history size, and window scale.
- `/blr` commands for display, configuration, clearing, reset, and diagnostics.
- Lua 5.1 syntax, TOC, database, and roll-tracker tests.
- Better Loot Rolls artwork in the addon list and window title.
