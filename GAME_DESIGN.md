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

M1 established the animated visual showcase. Subsequent user instructions authorized the M2 exploration and M3 battle implementations.

## Implemented visual baseline

M1 now provides field, creature, sample battle and party views with baked original artwork, shared UI, variant selection and animation preview. All displayed health, level and party values are fixtures; the systems above remain planned. Press 1-4 or Tab to review the views; README.md lists all controls. This visual baseline was carried into M2.

## Implemented exploration slice

M2 opens in Lantern Rest, a town linked by its east lantern gate to Fernglass Wood. Speak to Mara in town and Ivo in the forest; follow the trail north, cross the bridge east, and read the old waystation door/sign before returning west to town. Buildings provide exterior notes only. Dialogue freezes exploration. Release movement after conversations/gate travel before walking again.

Arrows/WASD and gamepad D-pad/left stick move; E/Z/Enter/Space or gamepad A interact/advance; Esc/X or gamepad B closes dialogue. NPCs are stationary. Battle/encounter/capture are implemented in M3 below; management and saves follow in M4 below; quests remain a later milestone.

## Implemented M3 rules

Start each run with Brindlewick (Grove, level 5), Cindrel (Ember, level 4), 12 charms and six balms. Rillume (Brook) completes the three-species set. Wild levels are 3-5. Step through either forest fern patch for encounters; normal terrain/town never rolls them. A five-eligible-step guarantee and six-step post-battle cooldown bound encounter pacing.

Priority: flee 7, items 6, switch 5, Quickstep 1, other moves 0; speed breaks equal priority and seeded randomness breaks ties. A forced healthy replacement after fainting is free. Invalid commands consume no item, turn or randomness. Enemy AI chooses one of its two moves. There are no PP, status conditions or trainer battles yet.

| Attacking affinity | Grove target | Ember target | Brook target |
|---|---|---|---|
| Grove | 1.0 | 0.75 | 1.5 |
| Ember | 1.5 | 1.0 | 0.75 |
| Brook | 0.75 | 1.5 | 1.0 |

Plain moves are neutral. Same-affinity attacks gain 1.15x; damage uses power/attack/defense, 0.9-1.05 seeded variation, floors to integers and deals at least one. Nudge/Quickstep always hit; affinity moves have 95-percent accuracy. Move menus show affinity and power.

Charm chance is species base (0.18/0.20/0.22) plus 0.6 times missing-health fraction, plus 0.1 for Grove/Brook in the forest, clamped to 0.1-0.95. A valid attempt spends one charm and turn; failure lets the enemy act, success ends the battle. Party capacity four; overflow enters storage. Balm restores up to 24 HP to the active companion; full-health use is invalid.

Victory/capture awards 8 + 4 times wild level XP to the healthy active companion exactly once. Level thresholds are 12 times current level, capped at 20; level gains add their max-health increase. Switching, fleeing and defeat do not award XP. Total defeat returns to town and rests the team as minimal M3 recovery; general healing and storage/party management are implemented in M4. Captures retain their remaining HP. M4 adds explicit persistence below.

## Implemented M4 management

Tab/M or gamepad Start opens the field menu at an idle exploration cell. Left/right changes pages; up/down selects; E/A confirms; Esc/B backs out. Party actions make a lead member or deposit to field storage. Highlight a party slot, then visit STORE: withdrawal fills vacancies or exchanges that slot when full. At least one healthy partner must remain; no individual is released/deleted. Storage shows four rows per page and scrolls through the collection.

BAG shows charm/balm counts. Charms remain battle-only; field balm targets a living injured party member and heals up to 24 HP. Invalid requests spend nothing. REST works anywhere in town, healing/reviving party and storage and restoring at least 12 charms/six balms; surplus remains. This free care keeps the slice playable without adding shops, currency, interiors or quests. SET toggles normal (0.55 seconds) or quick (0.25 seconds) battle-event delays; confirmation still advances events.

SAVE provides one explicit slot and confirmed LOAD. Save from idle field menus only; no autosave or suspended battle. Restart starts fresh, then LOAD restores your run. Persist collection/health/items/XP/settings, world position/facing, encounter stream and exactly-once reward ledger. Corrupt or interrupted saves can recover a validated pending/backup copy; unsupported schemas remain protected. Loading failure leaves the live run intact. Schema v1 migrates default settings to v2. Quest progression, audio and release accessibility remain later milestones.
