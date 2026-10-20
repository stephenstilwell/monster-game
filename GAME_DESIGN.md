# Lanternwild — monster-collecting roguelite

An original woodland monster-collecting roguelite with top-down exploration, turn-based battles and a permanent sanctuary. Short expeditions build temporary teams; returning home grows the collection and future choices. This direction supersedes the linear restoration-quest campaign. M5 now implements this first expedition loop. Earlier M0-M4 behavior is retained as historical foundation documentation and diagnostic fixtures below. M6 content/progression/audio remains planned.

## Core loop

1. At Lantern Rest, choose one sanctuary companion and depart with a standardized level and limited supplies.
2. Explore a seeded sequence of forest stages. Choose routes, battle/capture creatures, manage health and select temporary relics.
3. At a camp, decide whether to recover and continue or return safely with one new recruit.
4. Defeat the expedition guardian to complete the run, or lose the expedition when no party member can fight.
5. Resolve the outcome once, return to the sanctuary and start a new expedition with a different seed and team plan.

Keep classic handheld field exploration inside each stage. Route choices connect playable tile maps; the game is not exclusively a menu of battles. The eventual first-expedition target is 20-30 minutes. The compact M5 slice measured 55.28 seconds in a scripted GPU playthrough at real movement/message clocks; this excludes human decisions/exploration and is not a human playtime estimate. More variety and pacing work belongs to M6. No copied creature designs, names, maps or interfaces.

## What persists and what resets

| State | Between expeditions |
|---|---|
| Sanctuary individuals and their stable identities/species/cosmetics | Permanent; the chosen starter is never deleted or modified by expedition damage |
| Discovery journal | Records species successfully captured, including on failed expeditions; discovery alone does not grant a sanctuary starter |
| Town services, route/relic pool unlocks and completion records | Permanent as introduced by later milestones; favor more choices over stacking raw stats |
| Settings | Permanent and independent of expedition success |
| Expedition party/reserve, levels, XP, health and evolved forms | Temporary; start again from the expedition baseline |
| Expedition consumables, relics, route state and run rewards | Temporary; no supplies or relics accumulate in the sanctuary |
| Selected returning recruit | One eligible individual is admitted to the sanctuary after victory or camp retreat; preserve identity/cosmetics, not expedition combat growth |

The sanctuary is a collection of individuals, not a team whose levels can be ground indefinitely between runs. Bring exactly one companion, initially at level 5 with zero expedition XP, healthy and using its species' starting moves. Initial supply target: four capture charms and two balms. These are the implemented M5 defaults; broader balance remains M6 work. Start a fresh profile with Brindlewick and Cindrel available to choose from; Rillume is first obtained through expeditions.

## Captures, storage and outcomes

Party capacity remains four. Captures fill the party, then a temporary expedition reserve of four. When both are full, refuse capture before spending items, turns or RNG; the player may explicitly release a captured companion at camp to make room. Release asks for confirmation, preserves discoveries, protects the starter copy and retains one healthy party member. No silent replacement or deletion. Reserve companions cannot fight or exchange with the party outside a camp. Sanctuary storage is separate and inaccessible during an expedition. Invalid management operations must leave at least one healthy party member.

A successful capture updates the discovery journal when its battle result is committed. It does not immediately add that individual to the sanctuary. On victory or voluntary camp retreat, choose at most one living expedition-caught individual from party/reserve to bring home; the starter copy is ineligible. Show an explicit no-recruit option. Others remain in the wild. Defeat or confirmed abandonment admits no recruits, but keeps committed discoveries and earlier permanent unlocks. Fainting ends participation until recovery; there is no permanent death of sanctuary companions.

| Outcome | Settlement |
|---|---|
| Guardian victory | Record completion, optionally admit one eligible recruit, clear the active expedition and return home |
| Retreat at a camp | Optionally admit one eligible recruit; no victory credit; clear the expedition |
| Total party defeat | No recruits/victory credit; retain discoveries, clear the expedition and return home |
| Confirmed abandonment | Same collection consequences as defeat; available to prevent trapping the player in a bad run |

All outcomes, discovery writes and recruit admissions use durable IDs and exactly-once settlement. Every outcome permits another expedition without paid supplies or grinding.

## Encounters, recovery and builds

Retain four-direction grid movement, completed-step encounters, immutable species definitions, single-active turn-based combat, affinities, capture weakening, and invalid-action guards. XP, move growth and evolution happen within the expedition. Stage difficulty and bounded encounters replace unlimited grass grinding; leaving/re-entering a completed stage cannot regenerate rewards or free encounters. Guardian battles cannot be captured or fled; ordinary encounters retain flee.

Use small authored map templates with seeded arrangements, encounter tables and route choices. Validate exits, camp/guardian access and walkable spawns. Independent RNG streams isolate map layout, encounters, battle and rewards. No unrestricted random terrain generation.

Temporary lantern relics offer run-specific build choices. M5 provides Thorn Lantern (+3 attack damage), River Shell (3 less damage taken, minimum 1) and Hearth Seed (6 HP to each living party member after victory/capture), with visible reward selection; do not add a large loot system before the expedition loop is tested. Camp recovery has a visible once-per-camp budget that persists across re-entry; no free full healing or item refill on every menu open. Town care is free, but reaching town settles the expedition, so it cannot refill an active run. Balm remains a limited 24-HP field/battle heal for living partners.

## Persistence and progression

Separate a permanent profile from an optional active expedition. Continue resumes the active expedition's latest safe checkpoint with its existing seed, route and RNG states; starting another requires settling/abandoning it. Autosave departure, completed battles/rewards, camp actions and settlement at safe boundaries. No mid-turn battle resume in M5: interruption restores the saved pre-battle encounter, not a rerolled opponent. Manual save becomes checkpointing, not a selector for older expedition states. Keep backups for corruption recovery; do not promise tamper-proof or power-loss-proof saves.

M5 provides discovery, sanctuary recruitment and completion records. M6 introduces town improvements and additional route/relic choices. Permanent progression should expand strategies without requiring repeated failures to obtain enough stats to win. Restoration becomes repeatable expedition goals and lasting hub improvements, replacing the mandatory linear quest chain. Use brief NPC guidance; keep the first run understandable without a long tutorial.

## Scope and presentation

Implemented M5 first roguelite playable: one sanctuary hub, three existing base species, three connected forest stages with route choices, one camp, three temporary relics, one guardian, recruitment/settlement and resumable checkpoints. Later target six creature entries total, including three growth forms, with broader route/build variety after the core loop works. Single-player desktop; no multiplayer, breeding, gacha, open-world scope or real-time combat.

Preserve the 320x180 viewport, 16px tiles, original 16-color woodland palette and procedural asset pipeline. Generate sanctuary fixtures, route/camp/guardian markers, relic icons, expedition status and outcome screens. Keyboard/gamepad navigation remains required; release remapping/accessibility and procedural audio follow the roadmap.

## Historical M0-M4 foundation

The following describes the earlier RPG slice, available through tests/fixtures/legacy_game.tscn for regression diagnostics. The default app now uses isolated profile/expedition state, finite marked encounters, camp care, terminal defeats and Continue checkpoints. Foundation rules/tests remain useful; old integration fixtures are not claims about the current lifecycle.

## Implemented visual baseline

M1 now provides field, creature, sample battle and party views with baked original artwork, shared UI, variant selection and animation preview. In the M1 viewer, displayed health, level and party values are fixtures; M2-M4 subsequently implemented gameplay. Press 1-4 or Tab to review the views; README.md lists all controls. This visual baseline was carried into M2.

## Implemented exploration slice

M2 opens in Lantern Rest, a town linked by its east lantern gate to Fernglass Wood. Speak to Mara in town and Ivo in the forest; follow the trail north, cross the bridge east, and read the old waystation door/sign before returning west to town. Buildings provide exterior notes only. Dialogue freezes exploration. Release movement after conversations/gate travel before walking again.

Arrows/WASD and gamepad D-pad/left stick move; E/Z/Enter/Space or gamepad A interact/advance; Esc/X or gamepad B closes dialogue. NPCs are stationary. Battle/encounter/capture are implemented in M3 below; management and saves follow in M4 below; quests remain a later milestone.

## Implemented M3 rules

The legacy M4 fixture starts each session with Brindlewick (Grove, level 5), Cindrel (Ember, level 4), 12 charms and six balms. Rillume (Brook) completes the three-species set. Wild levels are 3-5. Step through either forest fern patch for encounters; normal terrain/town never rolls them. A five-eligible-step guarantee and six-step post-battle cooldown bound encounter pacing.

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

SAVE provides one explicit slot and confirmed LOAD. Save from idle field menus only; no autosave or suspended battle. Restart starts fresh, then LOAD restores your run. Persist collection/health/items/XP/settings, world position/facing, encounter stream and exactly-once reward ledger. Corrupt or interrupted saves can recover a validated pending/backup copy; unsupported schemas remain protected. Loading failure leaves the live run intact. Schema v1 migrates default settings to v2. This paragraph describes legacy M4 saving. The default M5 app uses v3 profile/expedition checkpoints above; audio and release accessibility remain planned.

## Planned meta-progression contract

[META_PROGRESSION.md](META_PROGRESSION.md) specifies M6's reward loop: permanent research objectives, Research Marks from finite stage clears and victory, three sanctuary projects that unlock preparation choices, growth-form research, starter medals and optional challenge tiers. Defeat/abandonment retain committed research and stage marks; victory/retreat retain the existing one-recruit rule. No permanent attack/health upgrades or supply stockpiles. These systems are planned, not part of M5. M6 remains unimplemented; this documentation update does not authorize gameplay work.
