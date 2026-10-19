# Progress

Updated: 2026-10-19 (America/New_York).

## Status

M0 and M1 complete. The user's subsequent implementation instruction authorized M2. M2 exploration is implemented and validated; stop before M3. Main scene: scenes/world/exploration.tscn.

## Delivered M2

- Lantern Rest town (32x24 cells) and Fernglass Wood forest (36x28), baked typed MapDefinition resources from deterministic recipes. Retained Godot 4.7.2 Compatibility, 320x180 viewport and 16-pixel tiles.
- Cardinal movement with reserved 0.16-second steps, pixel-rounded interpolation, player animation, clamped scrolling camera and y-sorted props/actors. Bounds, water, walls, tree/stump footprints and NPC cells block movement.
- Arrows/WASD, gamepad D-pad/left stick, one 35-percent deadzone, focus-loss clearing and idempotent bindings.
- Generated Mara (fern hood/green coat) and Ivo (silver hair/beard/timber apron): four facings, idle plus four-frame walks each. NPCs stand and turn toward the player for dialogue.
- Generated sign, lantern post, mossy stump, reeds and two bridge lanes. Four new rasters, 16 NPC animation records, two SpriteFrames resources and a 34-tile exploration TileSet under assets/generated/m2/.
- Facing-based NPC/sign/door dialogue with wrapping, page advance/cancel and full visible-door interaction. Dialogue and transition modes lock movement; closing/travel require neutral input before another step.
- Safe two-way gate and short fade. Missing/unusable maps are rejected; invalid spawns recover to a walkable non-portal cell. Travel cannot interrupt a step or stack; stale dialogue closes cannot unlock transitions. Map mounts remove old actors.
- Preserved independent M1 showcase/F6 scene. README and all planning documents updated. No M3 systems introduced.

## Observed validation

Ran tools/validate_m2.ps1 using verified Godot 4.7.2 with -Capture -CleanImport. Final run passed without Godot warnings/errors:

- M1 regression: 494 asset/control assertions, 18 screenshot checks, deterministic generation and byte-identical repeated assembly of five resources PASS.
- M2: 2,733 assertions PASS. Covers two clean art/map builds versus persisted files; pixels/palette/alpha/digests/frames/anchors; required-route connectivity/boundaries/portal targets; grid versus TileSet collision; dialogue wrapping; step reservation/interpolation/locks; travel/spawn recovery; camera limits; binding idempotency; focus loss; keyboard input; analog deadzone and traversal/dialogue.
- Input/action-driven walking covered both maps, bridge and old waystation with three round trips. Virtual gamepad D-pad events traversed both exits; A/B events opened/closed NPC dialogue through the viewport. Physical hardware is not claimed tested.
- Three M2 resources matched byte-for-byte across separate assemblies; both baked maps matched two clean generation outputs.
- Default exploration and independent M1 scene startup PASS.
- Fresh source copy without import cache: import, main-scene startup, all 494 M1 assertions and all 2,733 M2 assertions PASS.
- Real OpenGL 3.3/NVIDIA RTX 3070 capture: eight 320x180 views with exact 3x copies, two full-map overviews with exact 2x copies and NPC/prop sheets. All 33 M2 dimension/palette/scaling assertions PASS; 22 PNGs under artifacts/visual/m2/.
- Inspected native/enlarged town, forest, movement, Mara/Ivo dialogue, bridge, old waystation, return view, full maps and NPC/prop art. No unresolved UI clipping or terrain seams observed. Reviewed changes and ran git diff --check before checkpointing.

Fixed: unsupported input-clearing API, wrap naming conflict, duplicate gamepad bindings, doubled stick deadzone, river-overlapping border tree, partial door interaction, and mid-step/duplicate-transition/stale-dialogue guards. Logs: ignored .godot/m2_validation/logs/.

## Remaining limits and manual playtest

- Follow the README route with F5. Assess movement/camera pacing, animation, text contrast, resize/letterboxing, dialogue locks, gate return and window focus recovery on your display.
- Virtual input routes pass; real keyboard focus and physical controller mappings/deadzone feel need hands-on checks. Prompts currently show keyboard labels for both devices.
- NPCs are stationary; walking art is saved for reuse. Doors show exterior notes. No interiors, quest/reward state, encounters, battles/capture, inventory, audio or save/load yet; each run resets.
- Capture tools need a writable source checkout. Exports, other platforms/GPUs and release accessibility remain later work.

## Next milestone

M3 battles/capture is not started. This turn remains scoped to M2. The Git checkpoint includes this report; use git log -1 to identify it. Remote: origin at github.com/stephenstilwell/monster-game.
