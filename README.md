# Lanternwild visual study

Open project.godot with Godot 4.7.2 and press F6 on scenes/showcase/showcase.tscn, or F5 for the main scene. All art is already baked; generation is a developer step, never a startup requirement.

Keyboard: 1-4 or Tab/Shift-Tab change views; arrows preview character facing; I toggles idle/walk; Space pauses/resumes; V swaps amber/moss; A plays a reaction; R holds effects at a low-stimulation sample frame; Esc quits. There is no player movement or functional battle menu in M1.

Gamepad: LB/RB change views, D-pad changes facing, A swaps variant, B toggles idle/walk, X reacts, Y toggles calm effects, Start pauses. Button names follow Godot's standard layout; physical hardware still needs manual checking.

Check all four views, sprite animation/anchors, long labels, palette contrast, and pixel scaling when resizing the window. Check both variants and calm mode. The field and battle data are visual samples.

## Rebuild and validate

From this directory in PowerShell (substitute your local executable):

```powershell
.\tools\validate_m1.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Capture -CleanImport
```

The runner verifies the engine, generates PNGs/manifest/font, imports, assembles SpriteFrames/TileSet/Theme, runs automated checks, launches the scene, optionally captures real rendered views, and optionally imports/tests a fresh source copy with no cache. Failures or Godot error/warning output stop the runner. Logs and clean test copies remain under ignored .godot/m1_validation/.

Individual phases can be run with --headless --path . --script tools/art/generate.gd, then --headless --path . --editor --quit, then --headless --path . --script tools/art/assemble.gd. Tests live under tests/art/. Godot --path . -- --capture writes native and 3x screenshot/contact-sheet evidence under artifacts/visual/. Capture tooling targets a writable source checkout, not exported builds.

The monochrome font PNG is a white/transparent coverage mask, embedded by Godot's BMFont importer. Its descriptor contains the pixel digest so mask changes force font reimport. Rendered art and text use only the shared 16-color palette; screenshot tests enforce this. artifacts/.gdignore keeps evidence out of game imports.
