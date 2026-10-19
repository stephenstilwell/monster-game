# Roadmap

Sequential milestones; each requires generated art, meaningful tests, visual evidence, concise documentation and a reviewed Git checkpoint. No later milestone begins before its gate passes.

## M0: planning and baseline — complete

Create the six requested documents, inspect project/instructions, verify installed Godot, establish Git and checkpoint planning. Stop for roadmap review. No gameplay or art-generation implementation in this task.

## M1: visual proof of concept — implemented and validated

Authorized by the user after planning. Verify/pin engine and establish generator/import/resource-build workflow. Generate every M1 asset specified in ART_DIRECTION.md and save reusable outputs and manifests.

Build a composed town-edge/forest vignette, animated character, creature/variant viewer, dialogue, sample party summary and sample battle layout. Label sample data. Interactive scope is only showcase navigation, animation playback and variant selection.

Acceptance: two clean generation runs match pixel/metadata digests; frame bounds, palette, anchors, glyph coverage and atlas references pass; clean imports and showcase launch pass. Inspect native/scaled screenshots, contact sheets, walk cycles, creature animation and effects. No unresolved seams, clipping or unreadable labels. Complete a Git checkpoint and review visual direction before M2.

Excludes movement simulation, encounters, battle/capture rules, inventory, quests and saves.

Observed result: Godot 4.7.2; eight raster assets, 15 animations, 32 tiles, three SpriteFrames resources, TileSet and Theme. 494 asset/control assertions pass in both current and fresh-cache source copies; 18 screenshot checks pass; all five assembled resources repeat byte-identically. Native/scaled views, atlas sheets and rendered animation samples were inspected. See PROGRESS.md and artifacts/visual/. The subsequent user implementation instruction authorized M2 using this visual baseline.

## M2: exploration slice — complete

Grid movement, collision, camera, town/forest maps, travel, NPC interaction and dialogue. Generate NPC sprites, route objects and transitions. Acceptance: traverse both maps with keyboard/gamepad, block invalid cells, lock movement in dialogue, validate spawn/exits and required connectivity; inspect movement and map visuals.

Observed result: two baked maps (32x24 town, 36x28 forest), four-direction movement, collision, clamped scrolling camera, two facing NPCs, signs/door dialogue and safe two-way gate travel. Four new raster assets and 16 NPC animation records were generated. 2,733 exploration assertions and 33 screenshot assertions pass; clean-cache tests/startup and M1 regression pass. Input/action-driven walking and virtual gamepad traversal/dialogue were exercised. Screenshots, full-map overviews and NPC/prop sheets were inspected. Physical controller feel and interactive pacing remain manual review items in PROGRESS.md. The subsequent user instruction authorized M3.

## M3: battles and capture — complete

Definitions, individual creatures, three initial species, encounters, turn resolution, moves, items, capture and results. Generate creature sprites, icons, reactions and effects. Acceptance: deterministic tests cover commands, ordering, invalid actions, flee, defeat, capture success/failure, full party and exactly-once rewards; complete exploration-to-battle-to-world flow.

Observed result: grass encounters, three species, five moves, two consumables, battle command/presentation UI, switching/forced replacement, fleeing, capture, overflow storage, XP and exactly-once outcomes are integrated with exploration. Generated six rasters, 18 animation records, four SpriteFrames resources and ten content definitions. 113 battle/integration assertions, 280 art/data assertions and 52 screenshot assertions pass; M1/M2 regressions and all four suites in a fresh-cache copy pass. Rendered battle/result/world views and original art were inspected. M3 originally used memory-only state. The subsequent user instruction authorized M4 below.

## M4: party, inventory and persistence — complete

Party/storage UI, inventory, healing, settings and versioned save/load. Generate item icons, portraits and menu states. Acceptance: round trips, corruption, unsupported schema and interrupted-write recovery; full-party storage behavior; keyboard/gamepad focus without traps.
Observed result: scene-owned field menu provides party ordering/deposit, paginated storage/withdraw/full-party exchange, balm targets, town rest/refill, battle pace and explicit save/load. Three deterministic raster atlases provide portraits, items and menu states. Schema v2 validates before applying; v1 migrates settings. Checksummed pending/primary/backup writes recover interrupted arrangements and protect unsupported versions. 168 management/save/input assertions, 33 art assertions and 51 screenshot assertions pass; M1-M3 regressions and all six suites in an isolated fresh-cache source copy pass. Native/3x captures were inspected. See PROGRESS.md for limits. Stop here; M5 is not started.

## M5: complete first playable

One multi-stage restoration quest, two NPCs, waystation unlock, progression and defeat recovery. Generate changed-world art, quest UI and original procedural audio. Acceptance: fresh town-to-forest-to-capture-to-restoration playthrough; mid-quest reload; defeat recovery; clear ending without softlocks, duplicate rewards or missing art. Balance through full playthroughs before expanding.

## M6: content and release polish

Expand to six species including three growth forms; size further habitats/quests after M5. Add remapping, accessibility, audio mix and desktop export. Generate all required assets. Acceptance: complete regression, clean export smoke test, licenses/credits, supported-scale UI inspection and documented finished content boundary.
