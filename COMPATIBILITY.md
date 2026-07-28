# Compatibility

## v0.1.0-alpha.2

- Targets: World of Warcraft Classic Era, Classic Hardcore, and Burning
  Crusade Classic Anniversary
- Interfaces: `11509` for Era/Hardcore and `20506` for TBC
- API source reviewed: Classic Era 1.15.9 and TBC 2.5.6 FrameXML and
  `C_LootHistory`
- Offline validation: Lua 5.1 syntax, TOC metadata, SavedVariables validation,
  bounded history, active/completed roll normalization, winner state, and
  duplicate suppression
- Live in-game validation: pending

The alpha must not be described as fully verified until it has been exercised
in both live clients with active Need, Greed, Disenchant, Pass, all-pass, and
winner scenarios.
