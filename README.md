# Lanternwild — monster-collecting roguelite

Open project.godot in Godot 4.7.2 and press F5. M5 is playable: a permanent sanctuary, seeded forest expeditions, temporary teams/relics, one camp, a guardian and returning recruits. Artwork is original and baked; no generation is required to play. M6 content/hub upgrades/audio has not started.

## Play and manual checks

- Arrows/WASD or D-pad/left stick walk. E/Z/Enter/Space or gamepad A confirms/interacts; Esc/X or gamepad B backs out. Tab/M or gamepad Start opens/closes the journal while idle. Menus use up/down or D-pad to select; E/A confirms. Physical controller feel still needs hands-on review.
- In town, talk to Mara and Ivo, then use the east gate or journal > START EXPEDITION. Choose Brindlewick or Cindrel (or a returning recruit). One copy starts at level 5 with four charms/two balms; sanctuary originals stay safe. Pick one of two themed routes for each stage.
- Follow the dirt path and clear both marked fern lanterns in each of three stages. Step onto a marker, or face it and press E/A. Fight, capture or flee: each encounter is finite and its cleared lantern dims. Then step onto/interact with the large gate/camp marker. Check that revisiting a light gives no extra battle or reward.
- Battles: MOVES attacks; BAG uses charms/balms; PARTY switches; LEAVE attempts escape. Grove beats Brook, Brook beats Ember, Ember beats Grove. Weaken before capturing; manage limited supplies and switch for affinity advantages. Invalid actions spend no turn/items/RNG. The final guardian cannot be captured or fled.
- Pick a temporary relic after each cleared stage. Thorn Lantern adds 3 attack damage; River Shell reduces incoming damage by 3 (minimum 1); Hearth Seed heals living party members by 6 after victory/capture. Check party HP, supplies, reserve count and relic icons in the HUD/journal.
- After stage two, camp can heal/revive the entire team/reserve once, without item refills. Try REST again and reopen the camp: it stays spent. Camp is the only place to deposit/withdraw/exchange temporary reserve members. At a full party, withdrawal asks for a target slot. Confirmed release can free a captured companion; it protects the starter and last healthy member. The camp TRAIL JOURNAL exposes balm, relic, discovery, settings and checkpoint screens.
- Victory or camp retreat offers one living expedition-caught recruit, or no recruit. The starter copy cannot be admitted. Defeat/confirmed abandonment admits none; discoveries and sanctuary individuals survive. Check all four return paths, then depart again: levels/XP/items/relics reset, and the admitted individual is available at level 5.
- Check back/cancel from starter, route/reward, party, reserve/exchange/release, journal and result screens. Abandonment/release default to keeping the run/companion. Release held directions after returning to exploration. Menus reject mid-step, dialogue and battle entry.

This is a compact seven-battle loop (six wild lights plus guardian), not yet a 20-30 minute run. A scripted GPU run at real movement/event timing took 55.28 seconds, excluding human decisions/exploration. A fixed bot won 10/16 Brindlewick and 12/16 Cindrel seeded runs; this is diagnostic coverage, not a human difficulty estimate. Broader variety/pacing/balance belongs to M6. All three relics are acquired by the guardian; early ordering and team choices currently provide most build variation.

## Saves and Continue

Departure, route/reward choices, completed battles, field item/party actions, camp and return settlement write a verified checkpoint. The journal also offers CHECKPOINT. Startup loads the sanctuary and offers CONTINUE EXPEDITION if one is active; it does not start a different run. Ordinary walking resumes from the last checkpoint, not every tile. Interrupted battles restart their saved pre-battle encounter with the same identity and RNG; there is no mid-turn resume or old-state picker.

Schema v3 stores profile plus active expedition together under user://saves/ (normally %APPDATA%/Godot/app_userdata/Lanternwild/saves/ on Windows). slot.json, pending.json and backup.json support recovery. v1/v2 collections migrate into sanctuary identities/species/cosmetics/settings; old combat growth/items do not become permanent power. The original envelope is separately preserved as legacy_v2.json before migration writes. Unsupported/damaged unrecoverable existing slots block fresh overwrites. Diagnostics never touch the player's slot.

If a checkpoint write fails, the candidate is not applied. Battle results remain open for retry; recruit selection stays open until admission saves successfully. Recovery tests construct interrupted file arrangements, not hardware power failures. One game instance is assumed; cloud/concurrent-writer coordination is outside this slice.

## Validate and inspect

```powershell
.\tools\validate_m5.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Capture -CleanImport
```

Runs M1-M4 foundation regression and M5 deterministic art, state/save/connectivity, actual default-app input/gameplay, fixed-bot sample and startup. -Capture uses the GPU and checks palette/dimensions/exact integer scaling. -CleanImport runs all ten suites plus startup in a fresh source copy. Nonzero exit, missing success marker or Godot warnings/errors fail validation. Logs/saves/copies remain under ignored .godot/m5_validation/ and prior folders.

M5 phases: --headless --path . --script tools/art/generate_m5.gd; --headless --path . --editor --quit; --headless --path . --script tools/art/assemble_m5.gd. tests/expedition/ runners are headless. tools/art/capture_m5.gd runs graphically; tools/art/play_m5.gd runs the real-time scripted expedition and records its timing. Prefix commands with your executable. Diagnostics require a writable checkout; runtime loads baked art and generates only route layout/data.

Evidence: artifacts/visual/m5/ (71 PNGs and views.json). Captures use real commands for the expedition/victory, a documented expanded reserve for UI-only views, a saved camp copy for retreat and a wounded-team defeat fixture. All save paths are isolated. artifacts/.gdignore excludes evidence from game imports.

Earlier scenes remain available for diagnostics: scenes/showcase/showcase.tscn (M1 viewer), scenes/world/exploration.tscn (M2 standalone) and tests/fixtures/legacy_game.tscn (former M3/M4 app). Earlier integration/capture tests intentionally use the legacy fixture; M5 flow tests use the actual default scenes/app/game.tscn. These historical fixtures do not define current expedition rules.

Design and boundaries: [GAME_DESIGN.md](GAME_DESIGN.md), [ROADMAP.md](ROADMAP.md), [ARCHITECTURE.md](ARCHITECTURE.md), [PROGRESS.md](PROGRESS.md).
