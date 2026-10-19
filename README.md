# Lanternwild management and persistence slice

Open project.godot in Godot 4.7.2 and press F5. Baked original artwork requires no generation to play. A fresh run starts with Brindlewick, Cindrel, 12 charms and six balms. Use SAVE/LOAD explicitly to preserve a run; startup does not auto-load.

## Controls and manual playtest

- Arrows/WASD or D-pad/left stick walk. E/Z/Enter/Space or gamepad A confirms/interacts; Esc/X or gamepad B backs out. Tab/M or gamepad Start opens/closes the field menu while idle. Left/right changes menu pages; up/down selects rows. Use D-pad in menus.
- PARTY: choose MAKE LEAD or SEND TO STORAGE. Highlight the desired party slot before switching right to STORE. Withdrawal fills vacancies; with four members it exchanges the highlighted slot. Capture at least three additional companions to try overflow storage. Scroll beyond four stored companions, exchange, and verify identities/HP remain intact. The last healthy partner cannot be deposited/swapped for a fainted one.
- BAG: try balm on an injured, full-health and fainted target. Valid use heals 24 HP and spends one; invalid use spends nothing. Charms are battle-only. REST in town heals/revives party and storage and restores baseline supplies; try it in the forest to see refusal.
- SET: toggle normal/quick battle pacing, then judge message/animation timing in a battle. Both settings permit confirm to advance events.
- SAVE: save in town or forest, change party/items/position, then LOAD and confirm replacement. Check restored position/facing, health/XP, collection, supplies and pace. Restart F5 and use LOAD again. Saves live under Godot user://saves/ (normally %APPDATA%/Godot/app_userdata/Lanternwild/saves/ on Windows); primary, pending and backup files support recovery. Unsupported schemas are protected. Tests/captures use isolated .godot/ directories and never overwrite your slot.
- Back out of every submenu with Esc/B; close with Tab/Start. Confirm movement resumes after releasing held directions. Menus cannot open mid-step, dialogue, travel or battle. Check physical controller feel, focus loss, resizing/letterboxing and native-size readability.
- Existing battle route: talk to Mara, head east into Fernglass Wood, and walk the fern patch south of Ivo. Encounters occur within five eligible grass steps. MOVES attacks; BAG uses charms/balms; PARTY switches; LEAVE flees. Weaken before capturing. Grove beats Brook, Brook beats Ember, Ember beats Grove. Total defeat returns to town and rests the party. Check return location/HUD and the six-step encounter cooldown.

One slot, explicit saving, no save during battle. No quests, audio, growth forms, shops or interiors yet; M5 has not started. Physical controller/other GPUs/platforms/exports still need hands-on verification. Settings currently cover battle pace; remapping/audio/accessibility remain later work.

Earlier standalone scenes remain available: scenes/showcase/showcase.tscn (F6 art viewer) and scenes/world/exploration.tscn (F6 exploration without app services). F5 runs scenes/app/game.tscn.

## Rebuild and validate

```powershell
.\tools\validate_m4.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Capture -CleanImport
```

Runs M1-M3 regressions plus deterministic M4 artwork, import, field/save/input integration and startup. -Capture runs real GPU captures and exact palette/scaling checks; -CleanImport runs all six suites in a fresh source copy without imported caches. Missing success markers, nonzero exit or Godot warnings/errors fail validation. Logs/copies stay in ignored .godot/m4_validation/ and prior milestone folders.

M4 generation: Godot --headless --path . --script tools/art/generate_m4.gd; then --headless --path . --editor --quit. tests/save/test_art.gd and test_management.gd run headless. tools/art/capture_m4.gd runs graphically; test_screenshots.gd validates captures. Prefix each command with your executable. Diagnostics need a writable source checkout; runtime uses only baked assets.

Evidence: artifacts/visual/m4/ (35 PNGs including contact sheet), with earlier milestone evidence retained. M4 captures use a controlled expanded/wounded collection and an isolated save slot while invoking real management/save commands. Interrupted-write tests construct filesystem arrangements around pending/backup rotation; they do not simulate physical power loss. artifacts/.gdignore excludes evidence from game imports.
