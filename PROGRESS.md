# Progress

Updated: 2026-10-19 (America/New_York).

## Status

M0 complete. M1 visual proof of concept implemented and validated after the user's implementation instruction. Stop here for visual review; M2 has not started.

## Delivered M1

- Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer, 320x180 native viewport with nearest/integer scaling and aspect-preserving letterboxing.
- Deterministic GDScript asset pipeline: seed 842031, recipe m1.3; eight persisted raster assets, sorted manifest with pixel digests/frame/anchor/tile metadata, generated 5x7 bitmap font and original lantern app icon.
- Character: four facings, one idle and four walk frames each. Brindlewick: amber/moss variants with four idle and four reaction frames each. Grass/path/tall-grass/water variations, bank edges/corners, tree, rock, flowers, fence and waystation.
- Generated panels/cursor/bars/icons, lantern/leaf/charm effects; saved three SpriteFrames resources, a 32-tile TileSet with collision/custom data and a shared font/nine-slice Theme.
- Four sample views: field vignette/dialogue, creature study, battle layout and party summary. Keyboard/gamepad preview bindings, pause, facing/idle controls, variant switch, reaction and calm effects.
- Reproducible validation runner and launch/playtest instructions in README.md. Six native/3x screenshots, native/3x atlas sheets and rendered animation samples under artifacts/visual/ (16 PNGs total).

## Observed validation

Executed tools/validate_m1.ps1 with the verified console executable and both -Capture and -CleanImport. Final run completed with no Godot warnings/errors:

- Headless generation, import, resource assembly and scene startup: PASS.
- Two separate clean generation outputs: matching PNG bytes, font descriptor and manifest; persisted outputs match fresh recipes.
- Five saved Godot resources: byte-identical across separate assembly invocations.
- Asset/resource/showcase tests: 494 assertions PASS. Covers dimensions, palette/alpha (white font mask exception), digests, populated/bounded frames and anchors, facing/walk/variant differences, named regions, tile collision/metadata, bank masks, font coverage and preview input/state.
- Actual graphical rendering: PASS on OpenGL 3.3/NVIDIA RTX 3070; six views captured at 320x180 and exact 960x540 nearest scaling. Eighteen screenshot palette/dimension/scaling assertions PASS.
- Fresh isolated source copy with no import cache: import, scene startup and all 494 asset/control assertions PASS.
- Inspected native and enlarged field/creature/battle/party/variant/reaction views, atlas contact sheets and rendered walk/idle/reaction/effect samples. No unresolved clipping, terrain seams or label overflow observed.
- git diff --check passed before the milestone checkpoint. Full machine logs remain under ignored .godot/m1_validation/logs/; screenshots and this report are tracked evidence.

Fixed during validation: Godot scene BOM parsing, JSON float-to-tile-coordinate conversion, stale embedded font-mask imports, off-palette text tint, raw texture loading of BMFont's skipped mask, random serialized resource IDs, excessive grass texture and battle HUD obscuring the creature.

## Remaining limits and manual review

- This is a visual showcase. Movement, encounters, battle/capture rules, inventory, quests and saves are intentionally absent.
- Input handlers were exercised with synthetic keyboard/gamepad events; physical controller mappings and interactive focus still need manual testing.
- Pixel dimensions and captured scaling are verified; resize the actual window to assess letterboxing and font readability on your display.
- Rendered animation frames were inspected as contact sheets; judge animation pacing and visual preference during interactive preview. R freezes the effect samples; it does not freeze all creature motion (Space does).
- Capture/validation diagnostics target a writable source checkout. Export packaging, other GPUs/platforms and release accessibility remain later milestones.

## Next step

Open project.godot in Godot 4.7.2 and press F5. Review all four views and controls in README.md. Obtain visual-direction review before starting M2. The M1 Git checkpoint includes this report; identify it with git log -1.
