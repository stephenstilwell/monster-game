# Lanternwild exploration slice

Open project.godot in Godot 4.7.2 and press F5. M2 now launches a playable town/forest exploration slice. Art and maps are already baked; no generation is needed to play. Close the game window to exit.

## Controls and manual playtest

- Move with arrows/WASD or gamepad D-pad/left stick.
- Face someone or a sign/door and press E, Z, Enter, Space or gamepad A to interact/advance.
- Esc/X or gamepad B closes dialogue. Release movement after dialogue or gate travel before walking again.
- Talk to Mara just northeast of the start. Walk east between the lanterns to enter Fernglass Wood. Talk to Ivo, follow the trail north, cross the bridge east, then go south to the old waystation and read its door/sign. Return along the trail and leave the forest west to reach town.
- Try water, NPCs, walls and tree trunks. Hold movement during dialogue and confirm the character stays still. Check camera scrolling, text, resize/letterboxing, animation pacing, controller feel and focus loss/recovery.

NPCs stand and face the player. Doors provide notes; there are no interiors, encounters, battles, capture, quests, inventory, audio or saves yet. Physical controllers still need hands-on verification; virtual controller events are tested automatically.

The M1 showcase remains at scenes/showcase/showcase.tscn: open it and press F6. Its controls: 1-4/Tab views, arrows facing, I idle/walk, Space pause, V variant, A reaction, R calm effects and Esc quit.

## Rebuild and validate

From this directory in PowerShell (substitute your executable):

```powershell
.\tools\validate_m2.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Capture -CleanImport
```

Runs M1 regression, M2 deterministic generation/import/assembly, repeated-resource byte comparisons, world/input/dialogue/travel tests, main-scene startup, optional real screenshots and optional fresh-cache source-copy tests. Failures, missing success markers or Godot warnings/errors stop the runner. Logs/copies remain in ignored .godot/m1_validation/ and .godot/m2_validation/.

M2 phases: Godot --headless --path . --script tools/art/generate_m2.gd; then --headless --path . --editor --quit; then --headless --path . --script tools/art/assemble_m2.gd. tests/world/test_exploration.gd runs headless tests. Run tools/art/capture_m2.gd without --headless for screenshots. Prefix commands with the installed Godot executable.

Evidence: artifacts/visual/m2/ (22 PNGs), plus artifacts/visual/ (M1). Diagnostics target a writable source checkout, not exports. artifacts/.gdignore excludes evidence from game imports. The font PNG is an embedded white/transparent mask; rendered text uses the shared 16-color palette, checked by screenshot tests.
