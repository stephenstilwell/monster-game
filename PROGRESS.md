# Progress

Updated: 2026-10-19 (America/New_York).

## Status

M0-M4 complete. The latest user instruction authorized the next milestone after M3: M4 party/inventory/persistence. Stop before M5. Main scene: scenes/app/game.tscn.

## Delivered M4

- Scene-owned field journal: party order/deposit, four-row paginated storage, vacancy withdrawal/full-party exchanges, consumable counts/targeted balm, town rest/refill, normal/quick battle pacing and explicit save/load with replacement confirmation.
- Menu opens only at an idle exploration cell and locks movement/encounters/input. Keyboard and virtual gamepad navigate all pages/submenus, including scrolling storage and safe load cancellation. Back restores parent focus; closing restores neutral-input protection. World HUD advertises Tab/M.
- Field service rejects invalid operations without spending items or losing individuals. At least one healthy party member remains. Balm heals living injured members by 24 HP. Free town care heals/revives party/storage and restores at least 12 charms/six balms without deleting surplus.
- Explicit schema v2 maps stable IDs, monster progression/health/moves/cosmetics, party/storage/items, battle serial/claim ledger, settings, safe location/facing and exact encounter RNG/counters. Canonical decimal strings preserve signed 64-bit RNG/cosmetic values. v1 migrates default settings. Decode validates a complete candidate before any live-state replacement.
- SHA-256 envelope, verified/flushed pending writes, known-good backup rotation and guarded replacement. Valid primary wins; missing/corrupt primary recovers pending then backup. Unsupported versions prevent fallback/overwrite. A recovered candidate is preserved before another save reuses pending. Failure leaves the live run intact.
- Generated three reusable PNG atlases, eight named regions and sorted manifest: original 48px species portrait cards, 24px charm/flask icons and three menu states. Shared palette/font/panels preserved. Recipes and outputs committed together.
- All six planning documents and README updated; validation runner composes previous milestone regressions. Earlier standalone scenes remain usable. No M5 quest/world-change/audio implementation.

## Observed validation

Executed tools/validate_m4.ps1 with Godot 4.7.2.stable.official.ed1daf0bf, -Capture and -CleanImport. Final run passes without Godot warnings/errors:

- M4 management/save/input: 168 assertions PASS. Includes malformed data/types/IDs/HP/XP/moves/settings/location/RNG, JSON round trips, exact 64-bit values, v1 migration, future-version protection, corrupt/checksum/missing saves, pending/backup interrupted arrangements, resave after recovery, I/O failure, no partial live-state mutation, preserved reward ledger, full-party exchanges, balm/healing/refills, keyboard/gamepad pages/submenus/scrolling, safe modal gates and loaded battle pace/serial.
- M4 art: 33 assertions PASS. Two clean generation runs match PNG bytes/manifest; baked pixels/digests, shared palette/hard alpha, dimensions, region bounds and populated art agree.
- M4 rendered screenshots: 51 assertions PASS across 17 native/3x views. Actual NVIDIA RTX 3070/OpenGL 3.3 capture produced 34 interface/world PNGs plus a contact sheet. Inspected native/enlarged menus, portraits/items, storage pages, field healing, settings, confirmations and world return.
- M1 regression: 494 art/control assertions and 18 screenshot checks PASS. M2: 2,733 exploration assertions and 33 screenshot checks PASS. M3: 280 art/data assertions, 113 battle/integration assertions and 52 screenshot checks PASS. Prior assembled resources remain byte-identical across repeat invocations.
- Isolated source copy without import cache: import/startup and all six suites (494, 2,733, 280, 113, 33 and 168 assertions) PASS. Test/capture saves stay under ignored .godot/m4_validation/; the player's user:// slot is untouched. Logs remain in ignored validation folders.

Review fixes: typed dynamic boolean, quiet malformed-JSON parsing, preserve recovered pending before resave, distinguish malformed versus unsupported versions, correct balm-target portrait, restore parent focus and derive exchange target from highlighted party slot. Test corrections distinguished legal custom IDs and the neutral guard before an idle frame clears it. Reviewed staged changes and Git whitespace checks before checkpoint.

## Limits and manual playtest

- Follow README.md: capture enough for a full party/storage, reorder/deposit/withdraw/exchange, scroll beyond four stored partners, use/refuse balm, rest in town/refuse in forest, toggle battle pace, save/restart/load and inspect restored state. Check back/cancel and held-direction/focus behavior with physical keyboard/controller.
- One explicit slot; startup begins fresh until LOAD. Saving is restricted to idle field menus; active battles/dialogue/transitions are not resumable. Settings currently cover battle event pace only. Town rest is available through the menu anywhere in town; no interior/shop/currency/quest gate yet.
- Crash recovery tests create actual interrupted file arrangements, not real process kills, power failures or disk faults. File flushing/recovery does not guarantee hardware durability. Saves assume one running game instance; no concurrent-writer coordination or cloud sync.
- Collection fixtures drive some captures; field/save commands are real. Physical controller mapping/analog feel, other GPUs/platforms, exports, balance and interactive pacing remain manual/later checks.
- No quests, audio, growth forms, PP, status conditions or trainer battles. Cosmetic seeds persist; battle art uses base species colors. No remaining observed code/asset validation errors.

## Next milestone

M5 complete-first-playable quest/progression/audio work is not started. A subsequent user instruction may authorize it. This checkpoint includes the report; identify it with git log -1. Remote: origin at github.com/stephenstilwell/monster-game.
