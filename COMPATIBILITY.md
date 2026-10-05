# Compatibility

## v0.2.0-beta.1

- Era/Hardcore: interface `11509`; TBC Anniversary: `20506`.
- Forever beta: interface `16001`, game type `camelot`, `WOW_PROJECT_CAMELOT`.
- Forever API reviewed from Blizzard's generated documentation and FrameXML
  mirrored in Gethe/wow-ui-source, branch `forever`, commit
  `e3ecc27b64d30fdc735a3f6579b866858f9f9df1` on 2026-10-05:
  https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootHistoryDocumentation.lua
- Forever uses encounter/drop keys, `rollInfos`, `winner`/`allPassed`, and the
  `LOOT_HISTORY_UPDATE_*`, `GO_TO_ENCOUNTER`, `CLEAR_HISTORY`, and
  `ONE_HUNDRED_ROLL` events. Era/TBC keep their legacy API and events.
- No polling, loot automation, or changes to Blizzard frames/events.
- Offline validation covers active/completed transitions, choice enum mapping,
  encounter-key collisions, ordering, repeated refreshes, clearing, automatic
  opening, and three TOCs. Live Forever testing is pending.

Manual Forever checks: `/blr api`, active group rolls, each available choice,
winner/all-pass results, expansion across completion, automatic opening enabled
and disabled, history limit, then `/reload` and relog for settings/history.

## Historical v0.1.0-alpha.2

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
