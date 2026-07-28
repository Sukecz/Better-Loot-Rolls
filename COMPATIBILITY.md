# Compatibility

## v0.1.0-alpha.1

- Target: World of Warcraft Classic Era and Classic Hardcore
- Interface: `11509`
- API source reviewed: Classic Era 1.15.9 FrameXML and `C_LootHistory`
- Offline validation: Lua 5.1 syntax, TOC metadata, SavedVariables validation,
  bounded history, active/completed roll normalization, winner state, and
  duplicate suppression
- Live in-game validation: pending

The alpha must not be described as fully verified until it has been exercised
in the live client with active Need, Greed, Disenchant, Pass, all-pass, and
winner scenarios.
