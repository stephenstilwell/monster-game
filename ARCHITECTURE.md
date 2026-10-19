# Architecture — proposed

## Baseline

Existing project: MonsterGame; project.godot declares Godot 4.7, Forward Plus, D3D12 and canvas_items stretch with expand aspect. No gameplay scripts/scenes were present in the root inspection. Preserve configuration during planning. Verify executable before using version-specific APIs. Proposed M1 renderer: Compatibility for lightweight 2D, subject to launch verification on the installed engine.

## Structure

- tools/art/: GDScript raster generators, palette, recipes, deterministic packer, resource assembler.
- assets/generated/: reusable PNG atlases, bitmap font, SpriteFrames, TileSet, UI resources, sorted manifest.
- data/{species,moves,items,maps,quests}/: typed read-only Resource definitions with stable IDs.
- scenes/{app,showcase,world,actors,battle,ui}/: composed presentation scenes.
- scripts/{core,world,monsters,battle,inventory,quests,save}/: simulation and services.
- tests/{art,world,battle,save}/: dependency-free SceneTree runners.
- artifacts/visual/: curated screenshots/contact sheets for milestone evidence.

## Ownership and dependencies

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

Record exact executable/commands after discovery. Expected shapes: <godot> --headless --path . --editor --quit for imports and <godot> --headless --path . --script <runner.gd> for tools/tests. Capture rendered viewport screenshots in a graphical session; headless parsing does not establish visual quality.
