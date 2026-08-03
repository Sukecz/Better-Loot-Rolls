# Changelog

All notable changes to Better Loot Rolls will be documented in this file.

## [Unreleased]

## [0.1.3] - 2026-08-03

### Changed

- Reduced the minimum roll-window width to 140 pixels. Below 180 pixels, only
  item names are hidden; roll results, choice icons, and player details remain.
- Replace the addon-specific Windows deployer with one shared launcher that
  validates and updates Better Loot Rolls, Simple Scrolling Loot, and Simple
  Arsenal Swap in a single run.
- Close the Windows deployment window automatically on success and keep it open
  when an error needs to be read.

## [0.1.2] - 2026-07-31

### Added

- Added a small one-click clear-history icon beside the settings gear in the
  main roll window. It clears completed history without a confirmation prompt.

## [0.1.1] - 2026-07-29

### Changed

- Reduced the minimum window width to 180 pixels and made item headers use
  their available space dynamically instead of leaving a fixed center gap.

## [0.1.0] - 2026-07-29

### Changed

- Reworked the main roll window into a compact modern panel with a minimal
  header and denser item and player rows.
- Added a subtle Better Loot Rolls label to the existing compact title bar.
- Reduced the minimum window width and tightened the player, choice, and
  three-digit roll columns for narrow layouts.
- Removed nested item-card borders and replaced the standard Blizzard scrollbar
  with a minimal right-side scroll indicator.
- Corrected the scrollbar direction and enlarged its thumb and clickable area
  for easier dragging.
- Loot entries now start collapsed and can be expanded individually to show
  player choices and roll details.
- Collapsed entries now summarize roll progress, the winning player and roll,
  or an all-passed result.
- Item headers now show the player's own Need, Greed, Disenchant, or Pass icon
  even while the entry is collapsed.
- Expanded entries remain open when an active roll becomes completed.
- Added configurable window opacity with a live preview in the options panel.
- Reorganized options into clear history and appearance sections with visible
  scale and opacity values.
- Made the options window movable by dragging its header.
- Added a concise login message pointing users to `/blr options`.

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
