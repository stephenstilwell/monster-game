# Progress

Updated: 2026-10-19 (America/New_York).

## Status

M0-M2 complete. The latest user instruction authorized M3 battles/capture. M3 is implemented and validated; stop before M4. Main scene: scenes/app/game.tscn.

## Delivered M3

- App-owned in-memory run state and encounter controller integrate completed eligible forest steps with battle entry. Independent seeded encounter/battle streams; no idle rolls, a five-grass-step guarantee and six-step return cooldown. Town/ordinary terrain do not encounter.
- Typed definitions for Brindlewick/Grove, Cindrel/Ember and Rillume/Brook; five moves and two consumables. Individual monsters own IDs, health, levels, XP, copied moves and cosmetic seeds. Definitions remain unmodified.
- Scene-independent resolver: priority/speed/seeded ties, affinity damage, accuracy, enemy moves, healthy/forced switches, balm, charm capture, flee, victory and defeat. Invalid actions preserve turn/items/HP/RNG. KO/successful capture/flee stop subsequent actions.
- Command/presentation/result controller and generated-art UI, with separate displayed health snapshots, front/back idle/reaction frames, icons and event-clock effects. Duplicate commands during presentation and premature/stale battle closes are guarded.
- RunSession claims outcomes once: health/items carry into the next battle; capture joins the party or storage at capacity four; victory/capture award bounded XP/level growth. Minimal defeat recovery returns to town and rests the team. General healing, management menus and persistence remain M4.
- Six saved raster assets, 18 animation records, four SpriteFrames resources and ten content Resources; original Cindrel/Rillume designs, Brindlewick back pose, six effects and forest arena. Mara now explains fern encounters and weakening targets.
- Documentation and validation runner updated. Earlier standalone scenes and M1/M2 regressions preserved. No M4 management or save system introduced.

## Observed validation

Executed tools/validate_m3.ps1 with verified Godot 4.7.2.stable.official.ed1daf0bf, -Capture and -CleanImport. Final run passed without Godot warnings/errors:

- M3 battle/integration: 113 assertions PASS. Covers valid/invalid commands and RNG preservation, priority/speed/ties, deterministic replay, balm cost/healing, normal/forced switches, capture/flee success and failure, KO/defeat, full-party storage, snapshot isolation, exactly-once XP/capture, bounded progression, encounters/cooldown, viewport keyboard/gamepad navigation and grass-to-battle-to-world/town loops.
- M3 art/data: 280 assertions PASS. Two clean builds match PNG bytes, pixel digests, sorted manifest and all ten persisted definitions. Palette/alpha, dimensions, populated frame bounds, anchors, front/back distinction and animation/resource rectangles pass.
- All four assembled M3 resources are byte-identical across separate invocations; main app startup PASS.
- M1 regression: 494 assertions and 18 screenshot checks PASS. M2 regression: 2,733 assertions and 33 screenshot checks PASS.
- Fresh isolated source copy without import cache: import/startup and all four suites (494 M1, 2,733 M2, 280 M3 art, 113 M3 battle assertions) PASS.
- Actual OpenGL 3.3/NVIDIA RTX 3070 rendering: 16 native/3x battle/interface/result/world views plus native/3x original-art sheets, 34 PNGs under artifacts/visual/m3/. All 52 M3 palette/dimension/scaling assertions PASS.
- Inspected native/enlarged art, fronts/backs/reactions, command/move/bag/party layouts, effects, capture, victory, defeat, overflow storage and return views. No unresolved text clipping/palette drift observed. Tiny level numeral checked against its bitmap glyph. Reviewed changes and ran git diff --check before checkpointing.

Fixed during validation/review: inferred integer recipe type, capture-fixture health/typed-array issues, fainted action continuation/duplicate messages, malformed command rejection, unclaimed-close/input leakage guards, low-contrast submenu hints, arena style mismatch and effect timing. Logs remain under ignored .godot/m3_validation/logs/.

## Limits and manual playtest

- F5 launches M3. Follow README.md: enter forest ferns, weaken/capture, switch, use balm, flee, win and lose; check return position/HUD/input and post-battle cooldown. Judge balance, encounter frequency and animation/message pacing interactively.
- Two starters and fixed consumable supplies support this slice. Captures retain remaining HP. Items are battle-only, and no general healing/refill/storage viewer exists yet; restart resets the run. Minimal defeat rest is the recovery path for this milestone.
- Virtual keyboard/gamepad events were tested; physical controller mappings, real input/focus feel, resizing/letterboxing, other GPUs/platforms and exports need manual/later verification. Prompts still display keyboard labels.
- No save/load, full party/inventory management, quests, audio, growth forms, PP, status conditions or trainer battles. Cosmetic seeds are retained; battle art currently uses base species colors.
- Captured visuals use controlled wounded-participant fixtures for some states; commands and outcome rules are real. Diagnostics require a writable source checkout.

## Next milestone

M4 party/inventory/persistence is not started. Keep this turn at M3. The checkpoint includes this report; identify it with git log -1. Remote: origin at github.com/stephenstilwell/monster-game.
