# Roadmap — awaiting review

Sequential milestones; each requires generated art, meaningful tests, visual evidence, concise documentation and a reviewed Git checkpoint. No later milestone begins before its gate passes.

## M0: planning and baseline — current

Create the six requested documents, inspect project/instructions, verify installed Godot, establish Git and checkpoint planning. Stop for roadmap review. No gameplay or art-generation implementation in this task.

## M1: visual proof of concept

After roadmap review, verify/pin engine and establish generator/import/resource-build workflow. Generate every M1 asset specified in ART_DIRECTION.md and save reusable outputs and manifests.

Build a composed town-edge/forest vignette, animated character, creature/variant viewer, dialogue, sample party summary and sample battle layout. Label sample data. Interactive scope is only showcase navigation, animation playback and variant selection.

Acceptance: two clean generation runs match pixel/metadata digests; frame bounds, palette, anchors, glyph coverage and atlas references pass; clean imports and showcase launch pass. Inspect native/scaled screenshots, contact sheets, walk cycles, creature animation and effects. No unresolved seams, clipping or unreadable labels. Complete a Git checkpoint and review visual direction before M2.

Excludes movement simulation, encounters, battle/capture rules, inventory, quests and saves.

## M2: exploration slice

Grid movement, collision, camera, town/forest maps, travel, NPC interaction and dialogue. Generate NPC sprites, route objects and transitions. Acceptance: traverse both maps with keyboard/gamepad, block invalid cells, lock movement in dialogue, validate spawn/exits and required connectivity; inspect movement and map visuals.

## M3: battles and capture

Definitions, individual creatures, three initial species, encounters, turn resolution, moves, items, capture and results. Generate creature sprites, icons, reactions and effects. Acceptance: deterministic tests cover commands, ordering, invalid actions, flee, defeat, capture success/failure, full party and exactly-once rewards; complete exploration-to-battle-to-world flow.

## M4: party, inventory and persistence

Party/storage UI, inventory, healing, settings and versioned save/load. Generate item icons, portraits and menu states. Acceptance: round trips, corruption, unsupported schema and interrupted-write recovery; full-party storage behavior; keyboard/gamepad focus without traps.

## M5: complete first playable

One multi-stage restoration quest, two NPCs, waystation unlock, progression and defeat recovery. Generate changed-world art, quest UI and original procedural audio. Acceptance: fresh town-to-forest-to-capture-to-restoration playthrough; mid-quest reload; defeat recovery; clear ending without softlocks, duplicate rewards or missing art. Balance through full playthroughs before expanding.

## M6: content and release polish

Expand to six species including three growth forms; size further habitats/quests after M5. Add remapping, accessibility, audio mix and desktop export. Generate all required assets. Acceptance: complete regression, clean export smoke test, licenses/credits, supported-scale UI inspection and documented finished content boundary.
