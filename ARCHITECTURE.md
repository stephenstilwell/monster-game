# Architecture

## Baseline

Verified Godot 4.7.2.stable.official.ed1daf0bf. M1 uses Compatibility/OpenGL, a 320x180 viewport, nearest filtering, integer scaling and aspect-preserving letterboxing. Real graphical launch passed on NVIDIA RTX 3070. project.godot runs scenes/showcase/showcase.tscn.

## Implemented M1

- tools/art/art_recipes.gd: pure integer-pixel recipes, shared palette, font glyphs and local seeded variation (seed 842031, recipe m1.3).
- tools/art/asset_pipeline.gd and generate.gd: export eight raster assets, BMFont descriptor and sorted manifest; SHA-256 pixel digests, named regions, 15 animation records and 32 tile records.
- tools/art/assemble.gd: after import, save three SpriteFrames resources, TileSetAtlasSource-based TileSet with terrain/encounter/edge metadata and collision polygons, and a bitmap-font/nine-slice Theme. Canonical serialized IDs make repeat assemblies byte-identical.
- scripts/showcase/showcase.gd: four visual fixtures, preview input and developer-only screenshot/animation sampling. Loads baked assets; no runtime generator dependency. Custom Node2D drawing deliberately avoids implementing gameplay controllers or interactive battle menus.
- tests/art/: deterministic generation/resource/preview-control tests and real-render screenshot palette/scaling checks. tools/validate_m1.ps1 orchestrates phases and optional fresh-cache/source-copy checks; logs stay under .godot/m1_validation/.
- artifacts/visual/: native/3x screenshots and atlas/rendered animation sheets. artifacts/.gdignore keeps evidence out of game imports. Capture diagnostics require a writable source checkout.

The font PNG is a white/transparent coverage mask embedded by Godot's BMFont importer, which marks the PNG as skipped. Runtime/assembler load the FontFile, not that PNG. The descriptor includes the mask digest to invalidate stale font imports.

## Structure

- tools/art/: GDScript raster generators, palette, recipes, deterministic packer, resource assembler.
- assets/generated/: reusable PNG atlases, bitmap font, SpriteFrames, TileSet, UI resources, sorted manifest.
- data/{species,moves,items,maps,quests}/: typed read-only Resource definitions with stable IDs.
- scenes/{app,showcase,world,actors,battle,ui}/: composed presentation scenes.
- scripts/{core,world,monsters,battle,inventory,quests,save}/: simulation and services.
- tests/{art,world,battle,save}/: dependency-free SceneTree runners.
- artifacts/visual/: curated screenshots/contact sheets for milestone evidence.

## Planned gameplay ownership and dependencies (M2 onward)

App composes WorldRoot or BattleRoot and a UI CanvasLayer. A coordinator owns transitions and input modes. Minimal Session autoload owns serializable GameState; ContentCatalog resolves stable IDs. Avoid a global event bus or unrelated autoloads.

GameState owns party, storage, inventory, quest flags, location and RNG state without Node references. MonsterState references SpeciesDefinition by ID; never mutate shared definition Resources in play.

WorldRoot composes terrain, decoration, collision, actors and encounter controller. Authored map recipes generate layout and seeded decoration. Validate mandatory paths/exits; defer unrestricted random maps. Select the installed engine's supported tile-layer API in M1.

GridMovement validates/reserves destination cells before interpolating presentation. Facing/movement state drives sprites. Dialogue/battle input modes pause exploration explicitly.

BattleController runs entry, command, resolution, presentation and result states. Scene-independent BattleResolver validates commands and produces ordered events from explicit state and RNG. UI presents outcomes and never computes rules. Rewards and capture transfers apply exactly once independently of animation completion.

Inventory, Party and Quest services validate changes to GameState. SaveService serializes explicit versioned JSON under user:// using stable IDs. Validate schema and references, write and validate a temporary save, retain the last known good backup, then replace primary. Support migrations and recover gracefully from malformed or newer schemas. Do not serialize scene/resource graphs.

## Art contract and pipeline

Generators depend only on shared palette, integer drawing primitives and versioned recipes. Manifest records ID, seed, generator version, palette ID, output digest, dimensions, frame rectangles/timing and anchors. Tiles additionally name collision, terrain adjacency and encounter eligibility. Runtime references named IDs rather than hardcoded atlas positions.

Generation phases: render PNGs/manifest, run Godot import, assemble reusable resources, validate, create contact sheets. Runtime loads outputs without invoking generators. Prove the phased workflow in M1 before expanding it.

## Validation

Headless runners assert behavior and return nonzero on failure. Art: two clean generations have matching pixels/metadata; palette, dimensions, anchors, glyphs and references are valid. World: collision, connectivity, spawns and exits. Battles: deterministic order, invalid actions, capture limits, defeat and exactly-once rewards. Saves: round trips, corruption, schema versions and interrupted writes.

The verified executable is D:/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe. README.md documents the executable-parameterized validation runner. Individual command shapes: <godot> --headless --path . --editor --quit for imports and <godot> --headless --path . --script <runner.gd> for tools/tests. Capture rendered viewport screenshots in a graphical session; headless parsing does not establish visual quality.
