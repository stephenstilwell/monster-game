# Lanternwild battle and capture slice

Open project.godot in Godot 4.7.2 and press F5. Art/content are baked; no generation is required to play. Each run begins with Brindlewick, Cindrel, 12 charms and six balms. All progress is in memory and resets when you restart.

## Playtest route and controls

- Arrows/WASD or gamepad D-pad/left stick move. E/Z/Enter/Space or gamepad A interact/confirm; Esc/X or gamepad B closes dialogue/goes back.
- Talk to Mara, head east through the lantern gate, then explore the tall fern patch south of Ivo (or the patch beyond the bridge). Walk inside the ferns: an encounter occurs within five eligible steps.
- In battles, use arrows/WASD or D-pad to choose. MOVES attacks, BAG offers charms/balms, PARTY switches, LEAVE attempts escape. E/A confirms and can advance event messages; Esc/B backs out of submenus. A fainted active companion requires a healthy replacement.
- Use Nudge to weaken a wild companion, then BAG > CHARM. Capture can fail and gives the enemy a turn. BALM heals the active companion; full-health use should be refused without spending anything. Grove beats Brook, Brook beats Ember, Ember beats Grove. Quickstep acts before normal moves.
- Try switching, failed/empty item use, fleeing, victory, capture and defeat. At four party members, further catches report field storage. Storage viewing/reordering is M4 work. Total defeat returns to town with a rested team; the spent items remain spent. Restart F5 to reset supplies.
- Confirm battle return restores movement/HUD at the same grass cell (town after defeat), with a short encounter cooldown. Release held movement after dialogue, gate travel or battle before continuing. Check pacing, readability, camera, resizing, focus recovery and physical controller feel.

No full party/inventory screens, town healing service, save/load, quests, growth forms or audio yet. UI prompts currently use keyboard labels for both input devices. Use D-pad for battle menus. Physical hardware and other GPUs/platforms need hands-on checking.

Standalone earlier scenes: scenes/showcase/showcase.tscn (F6 M1 art viewer) and scenes/world/exploration.tscn (F6 M2 exploration without app-owned encounters). F5 launches the complete M3 loop through scenes/app/game.tscn.

## Rebuild and validate

```powershell
.\tools\validate_m3.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Capture -CleanImport
```

Runs M1/M2 regressions, deterministic M3 art/data generation/import/assembly, repeat-resource byte checks, rules/UI/world tests, main-scene smoke test, optional real GPU captures and fresh-cache source-copy tests. Failures, missing success markers or Godot warnings/errors stop the runner. Logs/copies stay in ignored .godot/m3_validation/ (and prior milestone folders).

M3 phases: Godot --headless --path . --script tools/art/generate_m3.gd; then --headless --path . --editor --quit; then --headless --path . --script tools/art/assemble_m3.gd. tests/battle/test_battle.gd and test_art.gd run headless. Run tools/art/capture_m3.gd without --headless for rendered evidence. Prefix commands with your executable.

Evidence: artifacts/visual/m3/ (34 PNGs), with prior milestones preserved. Capture tools use documented wounded-team/foe fixtures for selected visual states, while resolving actual commands/outcomes. They target a writable source checkout, not exports. artifacts/.gdignore excludes evidence from game imports. Stable views are verified against the shared 16-color palette and exact integer scaling.
