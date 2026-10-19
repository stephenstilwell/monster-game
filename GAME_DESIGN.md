# Game design — proposed

Working title: Lanternwild. An original woodland monster-collecting RPG about restoring waystations alongside creatures shaped by local habitats. Names and scope await review.

## Experience and loop

Readable top-down exploration, expressive creatures, warm woodland art, and short dialogue. Leave town, explore a forest, encounter and capture creatures, help residents restore a habitat, then return to heal and unlock the next route. No copied creature designs, names, maps, or interfaces.

## Systems

- Four-direction movement on a 16 px grid, interpolated between cells. Interact with the facing cell; encounters check only completed eligible steps.
- Species definitions are immutable; individual monsters hold level, experience, health, moves, and appearance seed. Party capacity four; overflow captures enter storage.
- Single-active turn-based battles: move, item, switch, flee. Priority then speed determines order; seeded ties. Initial affinities Grove, Ember, Brook; numerical balance and matchup table belong to M3.
- Capture uses lantern charms; health and habitat affect chances. Valid failed attempts consume an item and turn. Invalid actions consume neither. Clear feedback for both outcomes.
- Experience and move unlocks support progression; habitat quest flags unlock routes. Avoid mandatory grinding in the first slice.
- Inventory separates stackable consumables and quest items. Town healing and forgiving defeat recovery; no permadeath.
- Explicit quest stages and stable IDs prevent duplicate rewards and preserve progress across travel and saves.
- Keyboard/gamepad focus navigation; remapping, text readability, reduced flashing, and volume controls before release.
- Later audio uses original procedural SFX and synthesized loops, with generation sources retained.

## Scope

First playable: one town, one forest route, three initial species, two NPCs, one restoration quest, healing, battles, capture, party/inventory, and saves. Later target six species including three growth forms. Single-player desktop only initially; no multiplayer or open-world scope.

M1 is an animated visual showcase with sample interface data. No gameplay systems are implemented until the visual direction is reviewed.

## Implemented visual baseline

M1 now provides field, creature, sample battle and party views with baked original artwork, shared UI, variant selection and animation preview. All displayed health, level and party values are fixtures; the systems above remain planned. Press 1-4 or Tab to review the views; README.md lists all controls. Review this visual direction before M2.
