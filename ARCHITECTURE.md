# Architecture

## Baseline

Verified Godot 4.7.2.stable.official.ed1daf0bf. M1 uses Compatibility/OpenGL, a 320x180 viewport, nearest filtering, integer scaling and aspect-preserving letterboxing. Real graphical launch passed on NVIDIA RTX 3070. project.godot now runs scenes/app/game.tscn. The M1 showcase and standalone M2 world remain independently runnable.

## Implemented M1

- tools/art/art_recipes.gd: pure integer-pixel recipes, shared palette, font glyphs and local seeded variation (seed 842031, recipe m1.3).
- tools/art/asset_pipeline.gd and generate.gd: export eight raster assets, BMFont descriptor and sorted manifest; SHA-256 pixel digests, named regions, 15 animation records and 32 tile records.
- tools/art/assemble.gd: after import, save three SpriteFrames resources, TileSetAtlasSource-based TileSet with terrain/encounter/edge metadata and collision polygons, and a bitmap-font/nine-slice Theme. Canonical serialized IDs make repeat assemblies byte-identical.
- scripts/showcase/showcase.gd: four visual fixtures, preview input and developer-only screenshot/animation sampling. Loads baked assets; no runtime generator dependency. Custom Node2D drawing deliberately avoids implementing gameplay controllers or interactive battle menus.
- tests/art/: deterministic generation/resource/preview-control tests and real-render screenshot palette/scaling checks. tools/validate_m1.ps1 orchestrates phases and optional fresh-cache/source-copy checks; logs stay under .godot/m1_validation/.
- artifacts/visual/: native/3x screenshots and atlas/rendered animation sheets. artifacts/.gdignore keeps evidence out of game imports. Capture diagnostics require a writable source checkout.

The font PNG is a white/transparent coverage mask embedded by Godot's BMFont importer, which marks the PNG as skipped. Runtime/assembler load the FontFile, not that PNG. The descriptor includes the mask digest to invalidate stale font imports.

## Implemented M2

- scenes/world/exploration.tscn composes TileMapLayer, y-sorted props/actors, Camera2D and a CanvasLayer HUD. scripts/world/exploration.gd owns exploration/dialogue/transition modes and mounts baked maps. No Session autoload or encounter system is needed yet.
- scripts/world/map_definition.gd is a typed Resource for tiles, blocked cells, props/NPCs, dialogue, landmarks and portals. data/maps/town.tres and forest.tres are baked from tools/art/map_recipes.gd with independent local seeds. Runtime neither invokes generators nor mutates definitions.
- grid_movement.gd reserves one cardinal destination, commits the cell after 0.16 seconds and provides rounded foot positions. Map.can_enter combines bounds, terrain, prop footprints and stationary NPC occupancy. TileMap physics is disabled; tests compare terrain collision against the TileSet so a competing solver cannot disagree with grid movement.
- scenes/actors/field_actor.tscn wraps AnimatedSprite2D with the shared (8,23) anchor. Player animation follows movement; stationary NPCs face the player for conversation. Their generated walk/idle atlases remain reusable.
- exploration_input.gd installs idempotent keyboard/D-pad/left-stick bindings. One 35-percent deadzone and dominant-axis selection avoid diagonal movement. Focus loss clears action state. Dialogue close and travel require a neutral direction before another step.
- dialogue_state.gd owns speaker/pages. scripts/ui/pixel_ui.gd provides bitmap text, wrapping and panels; exploration_hud.gd uses the existing generated Theme/font. Facing-based interaction is rejected mid-step; doors accept both visibly occupied cells.
- Travel validates the destination and finds a safe non-portal spawn before locking input for a 0.28-second fade. Missing/unusable maps are rejected. Duplicate requests and stale dialogue closes cannot unlock a transition. Map mounts dispose old actors and refresh camera limits.
- exploration_recipes.gd, exploration_pipeline.gd, generate_m2.gd and assemble_m2.gd under tools/art/ generate four rasters, 16 NPC animations, two SpriteFrames resources and a 34-tile TileSet under assets/generated/m2/. stable_resource.gd canonicalizes newly generated resource IDs.
- tools/validate_m2.ps1 runs M1 regression, M2 generation/import/assembly/tests, real capture and optional fresh-cache checks. tests/world/ covers connectivity, collision, spawn/input/movement/dialogue/travel. tools/art/capture_m2.gd saves evidence under artifacts/visual/m2/.

## Implemented M3

- scenes/app/game.tscn / scripts/core/game.gd compose the world and a single battle scene. Completed non-portal steps emit a signal; the app-owned encounter_controller.gd checks eligible grass with an independent seeded stream. Encounters occur within five eligible steps and have a six-step return cooldown. Idle frames never roll encounters.
- ContentCatalog resolves three SpeciesDefinition, five MoveDefinition and two ItemDefinition Resources under data/. MonsterState separates unique ID, species ID, level, XP, health, moves and appearance seed from immutable definitions; instances clone their mutable arrays.
- RunSession is scene-owned RefCounted state, not an autoload. It owns the in-memory party, overflow storage, consumable counts, battle serial and claimed-outcome ledger. M4 adds the schema and field service described below.
- BattleState holds cloned participants/items, current active index, RNG, turn/flee counters, habitat and outcome. BattleResolver validates before changing state or RNG, resolves priority/speed/seeded ties and returns ordered events. Forced replacement does not grant an enemy attack. KO/capture/flee stop further actions as appropriate.
- BattleController owns entry, command, presentation, result and closed phases. It blocks duplicate submissions while presenting. battle_canvas.gd consumes event health/switch snapshots rather than showing final-turn damage early; effects start from their event clock. All menus use the established bitmap UI and generated party/item icons.
- Finishing an outcome claims health/items, capture transfer and XP once. A party of four sends captures to storage. The app only unlocks the matching claimed battle; defeat has a minimal return-to-town/team-rest recovery so this slice remains playable. Other outcomes return to the same world cell. Input is neutralized and world HUD/camera restored.
- tools/art/battle_recipes.gd and battle_pipeline.gd generate six M3 rasters, front/back idle/reaction metadata, six effects and ten typed content Resources. generate_m3.gd, import, then assemble_m3.gd save four reusable SpriteFrames under assets/generated/m3/.
- tools/validate_m3.ps1 runs prior regressions, deterministic art/data tests, pure battle cases, viewport input/world-loop tests, repeat assembly, rendered capture and optional fresh-source import. Evidence: artifacts/visual/m3/. Details and limitations: PROGRESS.md.

## Structure

- tools/art/: GDScript raster generators, palette, recipes, deterministic packer, resource assembler.
- assets/generated/: reusable PNG atlases, bitmap font, SpriteFrames, TileSet, UI resources, sorted manifest.
- data/{species,moves,items,maps,quests}/: typed read-only Resource definitions with stable IDs.
- scenes/{app,showcase,world,actors,battle,ui}/: composed presentation scenes.
- scripts/{core,world,monsters,battle,inventory,quests,save}/: simulation and services.
- tests/{art,world,battle,save}/: dependency-free SceneTree runners.
- artifacts/visual/: curated screenshots/contact sheets for milestone evidence.

## Implemented M4

- scripts/ui/field_menu.gd is a scene-owned CanvasLayer child composed by game.gd. Party, storage, bag, rest, settings and save pages share generated bitmap UI. Four-row scrolling preserves access to all stored individuals. Keyboard/virtual gamepad events use the existing action map plus Tab/M/Start. Submenu back restores parent focus; closing requires neutral movement. Opening rejects movement, dialogue, travel and battle; simulation/input remain locked during load.
- scripts/core/field_service.gd validates deposits, withdrawal/exchange, field balm and town healing before mutation. A healthy party member must remain. Full parties exchange with the highlighted party slot. Balm heals living members by 24; town rest revives/heals party and storage, restoring supply baselines without deleting surplus. RunSession owns these collections and a persisted normal/quick battle-event setting.
- scripts/save/save_codec.gd maps explicit state to JSON schema v2: individual IDs/species/level/XP/HP/moves/cosmetic seeds, party/storage, consumables, battle serial/claim ledger, settings, safe map/cell/facing and encounter RNG/counters. Signed 64-bit values use canonical decimal strings. Fully validate types, bounds, references, identities, health/progression, safe non-portal cells and a healthy party before creating a candidate session. v1 migrates missing settings to normal pace. No scene/resource graphs or active battles are serialized.
- save_service.gd uses user://saves/{slot,pending,backup}.json. Envelope contains payload text and SHA-256 digest. Write/flush/close and re-read pending before rotating a valid primary to backup and installing pending. A recovery candidate is copied to primary before a later save reuses pending. Load prefers valid primary, then valid pending, then backup; unsupported versions stop fallback and prevent overwriting. Failures return messages without replacing live state. This is recovery across file operations, not a claim of hardware power-loss durability.
- game.gd applies only a fully decoded candidate, mounts its validated location and restores the independent encounter stream/ledger. Saves and loads are explicit field-menu commands; startup remains a fresh run. Loading asks before replacing unsaved progress. Tests/captures override the save directory under ignored .godot/m4_validation/ and never touch the player's slot.
- management_recipes.gd / generate_m4.gd save three PNG atlases and a sorted region/digest manifest under assets/generated/m4/. Runtime loads baked textures; no generator dependency. Existing font/Theme remain shared.
- tools/validate_m4.ps1 runs M1-M3 regressions, M4 generation/import, two-build art tests, field/save/input integration, main startup, optional real screenshots and all six suites in a cache-free source copy. tests/save/ contains the three M4 runners. Evidence: artifacts/visual/m4/.

## Planned after M4

Quest stages, world changes and rewards belong to M5; no quest state is introduced speculatively. Keep services scene-owned, definitions immutable and mutations validated. Any schema extension needs a migration and round-trip/failure tests. No global event bus or autoload is necessary for this slice.
## Art contract and pipeline

Generators depend only on shared palette, integer drawing primitives and versioned recipes. Manifest records ID, seed, generator version, palette ID, output digest, dimensions, frame rectangles/timing and anchors. Tiles additionally name collision, terrain adjacency and encounter eligibility. Runtime references named IDs rather than hardcoded atlas positions.

Generation phases: render PNGs/manifest, run Godot import, assemble reusable resources, validate, create contact sheets. Runtime loads outputs without invoking generators. Prove the phased workflow in M1 before expanding it.

## Validation

Headless runners assert behavior and return nonzero on failure. Art: two clean generations have matching pixels/metadata; palette, dimensions, anchors, glyphs and references are valid. World: collision, connectivity, spawns and exits. Battles: deterministic order, invalid actions, capture limits, defeat and exactly-once rewards. Saves: round trips, corruption, schema versions and interrupted writes.

The verified executable is D:/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe. README.md documents the executable-parameterized validation runner. Individual command shapes: <godot> --headless --path . --editor --quit for imports and <godot> --headless --path . --script <runner.gd> for tools/tests. Capture rendered viewport screenshots in a graphical session; headless parsing does not establish visual quality.
