# Architecture

## Direction and implementation boundary

Implemented: the sanctuary-based monster-collecting roguelite in GAME_DESIGN.md. scenes/app/game.tscn now uses scripts/core/expedition_game.gd. M0-M4 below describe the reusable foundation; tests/fixtures/legacy_game.tscn retains the former game.gd app for historical regression/captures. M5 tests exercise the actual default scene. No M6 implementation has started.

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

## Implemented M5 profile and expedition architecture

Components remain scene-owned. Profile and expedition are explicit dictionaries in one data envelope; pure services operate on deep-copied candidates. Immutable species/move/item Resources and versioned relic constants are shared read-only. No global event bus/autoload is needed. The responsibilities below are composed rather than one class per table row.

| Component | Responsibility |
|---|---|
| data.profile | Sanctuary individuals (stable ID/species/cosmetic seed), discovered species, completion/settlement ledger, later unlock IDs and settings; no accumulating expedition XP/items |
| data.run | Unique run ID, generation version/seed, source starter ID, copied party, four-slot reserve, supplies, relic IDs, stages/choices/cleared encounters, camp budget, battle serial/claims and RNG states |
| expedition_service.gd | Validate departure; copy/normalize one starter; advance routes; apply limited camp actions; create immutable settlement intent; enforce one active run |
| route_generator.gd | Pure seeded selection/assembly of authored room templates; validate connectivity and mandatory cells; produce map data compatible with the existing world renderer |
| expedition_service.gd relic/exit functions | Validate finite encounter/relic rewards and apply immutable modifier definitions; no repeated grants on revisits |
| expedition_service.gd settlement functions | Validate recruit origin/health/outcome; admit at most one eligible individual; preserve original starter; commit settlement exactly once |
| expedition_codec.gd / save_service.gd | Explicit schema v3 encoding/validation/migration and verified recovery writes for profile plus optional active expedition in one transaction |
| expedition_game.gd / expedition_menu.gd | Hub/setup/explore/battle/reward/camp/settlement modes, input locks, checkpoints and readable journal/route/result views |

Reuse MonsterState for mutable expedition combatants; sanctuary records do not share mutable objects/arrays with them. Clone source identity/cosmetics into a run-scoped starter ID and reset level/XP/HP/moves. Run-scoped capture IDs include run ID and battle serial so restarting the battle counter cannot collide with older sanctuary admissions. A recruit retains its capture identity/cosmetics; normalize combat state and later growth forms to its starter/base definition. Do not train or damage the sanctuary original.

expedition_session.gd adapts the existing RunSession battle API to data.profile/data.run, reusing the resolver and cloning discipline. Battle results return to the expedition controller: total defeat requests settlement rather than having RunSession heal and continue the same run. Sanctuary access and free care are hub-only; expedition reserve exchange/recovery is camp-only. Guardian encounter metadata prevents capture/flee. Full party plus reserve rejects capture before cost/RNG mutation.

Routes have stable stage/encounter/reward IDs and completion flags. Re-entry cannot regenerate a cleared stage's encounters or rewards. Separate seeded streams for layout, encounter selection, battle resolution and reward choices; store canonical 64-bit state strings. Derive streams from the run seed and stable IDs without language-dependent hashes. Persist generator/content version plus chosen layout/route state so Continue does not silently regenerate a different map after a recipe change. Unsupported content versions need a supported migration or a protected, clear failure.

## Implemented checkpoint and migration contract

Schema v3 stores profile and optional active expedition in one envelope. Keep v1 -> v2 migration, then migrate v2 party/storage into sanctuary records preserving IDs/species/cosmetics and settings. Existing combat levels/XP/items are not permanent power under the new rules; preserve the legacy backup before writing the migrated profile. A migrated session starts safely at the hub with no active expedition; never infer completed runs or award migration rewards.

Safe checkpoints include departure, completed battle/reward, camp operation and settlement. Before a battle, persist its encounter ID/descriptor and deterministic initial state; resume after interruption replays that encounter, not its opponent selection. M5 does not serialize an active animation or mid-turn scene. Continue uses the latest validated checkpoint; no player-facing previous-run-state picker. Confirm abandonment before clearing an active run.

For settlement, validate a candidate containing the terminal outcome, selected recruit (or none), profile updates, processed run ID and cleared active expedition. Write/verify it through SaveService before presenting the settled hub; failed writes retain a retryable locked settlement. Profile/discovery/expedition updates commit together, never to independently replaceable files. Retrying or recovering an already settled run must not duplicate admissions or completion credit. Preserve the current pending/primary/backup strategy, checksum validation, unsupported-schema protection and transactional live-state replacement; extend interrupted-boundary tests rather than promise hardware durability or tamper resistance.

Future hub upgrades and restoration objectives belong to M6 and reference stable unlock IDs. They must not become required raw-stat grinding. Every schema/content extension needs migration, round-trip and failure tests.
M5 files: scripts/expedition/{expedition_service,expedition_session,route_generator}.gd, scripts/core/expedition_game.gd, scripts/ui/expedition_menu.gd and scripts/save/expedition_codec.gd. The world renderer emits optional action_requested events for app-owned gates/lights; standalone M2 behavior is preserved. Routes use shared pure construction helpers from tools/art/map_recipes.gd and baked terrain/props, not runtime image generation. Three template layouts combine paths, grove clusters, river crossings and authored landmarks; seed-specific plan/decoration is stored or reproducible under content version m5.1.

SaveService accepts an explicit codec (legacy codec remains its diagnostic default). The main app loads the v3 profile read-only on startup and offers Continue for an active run. Malformed/unsupported existing slots block fresh overwrites. Integral JSON numbers normalize before strict ID comparisons; validation checks types, bounds, source identities, route-plan/seed consistency, finite reward chronology, claim counts and safe positions. The original v1/v2 envelope is copied to legacy_v2.json and verified before migration writes. A failed result checkpoint leaves the battle in a retryable result phase; a failed admission leaves settlement open with the original profile. No mid-turn serialization, independent profile/run files or rollback picker.

Relic effects feed neutral-default BattleState modifiers; guardian flags reject capture/flee before costs/RNG. The session adapter preserves defeat HP, issues run-scoped capture IDs, applies Hearth only to living party members, and guards stale/duplicate result publication. Camp rest is one full team/reserve recovery without item refill. Confirmed capture release is camp-only, preserves discoveries and protects the starter/last healthy partner.

## Art contract and pipeline

Generators depend only on shared palette, integer drawing primitives and versioned recipes. Manifest records ID, seed, generator version, palette ID, output digest, dimensions, frame rectangles/timing and anchors. Tiles additionally name collision, terrain adjacency and encounter eligibility. Runtime references named IDs rather than hardcoded atlas positions.

Generation phases: render PNGs/manifest, run Godot import, assemble reusable resources, validate, create contact sheets. Runtime loads outputs without invoking generators. Prove the phased workflow in M1 before expanding it.

## Validation

Headless runners assert behavior and return nonzero on failure. Art: two clean generations have matching pixels/metadata; palette, dimensions, anchors, glyphs and references are valid. World: collision, connectivity, spawns and exits. Battles: deterministic order, invalid actions, capture limits, defeat and exactly-once rewards. Saves: round trips, corruption, schema versions and interrupted writes. M5 additionally needs multi-seed route/connectivity tests, profile/expedition isolation, finite rewards/camp budgets, every settlement outcome, exactly-once admissions and deterministic checkpoint recovery. PROGRESS.md separates legacy fixture results from the current M5 state/flow/art/balance/screenshot results.

The verified executable is D:/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe. README.md documents the executable-parameterized validation runner. Individual command shapes: <godot> --headless --path . --editor --quit for imports and <godot> --headless --path . --script <runner.gd> for tools/tests. Capture rendered viewport screenshots in a graphical session; headless parsing does not establish visual quality.
