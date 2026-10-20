# Roadmap

Sequential milestones; each requires generated art, meaningful tests, visual evidence, concise documentation and a reviewed Git checkpoint. No later milestone begins before its gate passes. M0-M4 remain completed foundation work. The user requested a roguelite documentation pivot after M4; M5 onward below supersedes the former linear quest/release plan. The subsequent user implementation request authorized M5. M5 and M6 are implemented and validated below. The latest user implementation request authorized M6 after META_PROGRESSION.md; stop before M7.

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

Observed result: scene-owned field menu provides party ordering/deposit, paginated storage/withdraw/full-party exchange, balm targets, town rest/refill, battle pace and explicit save/load. Three deterministic raster atlases provide portraits, items and menu states. Schema v2 validates before applying; v1 migrates settings. Checksummed pending/primary/backup writes recover interrupted arrangements and protect unsupported versions. 168 management/save/input assertions, 33 art assertions and 51 screenshot assertions pass; M1-M3 regressions and all six suites in an isolated fresh-cache source copy pass. Native/3x captures were inspected. See PROGRESS.md for limits. This remains the historical foundation; the default executable now uses M5.

## M5: first complete roguelite expedition — complete

Replace the session-wide RPG loop with the sanctuary/expedition contract in GAME_DESIGN.md. Complete this entire loop before adding more species or a campaign.

Deliverables:

- Separate permanent profile/sanctuary/journal/settings from temporary expedition party/reserve/items/XP/relics/routes. Start with one chosen companion normalized to level 5 and fixed limited supplies. Sanctuary originals survive every outcome.
- Generate three traversable forest stages from validated authored templates and seeded route choices. Provide a camp after stage two and a final guardian. Stage encounters/rewards are finite and cannot be farmed by revisiting. Reuse the three existing species; no expansion to six yet.
- Three original temporary relic modifiers, selection UI, visible run depth/health/supply information, camp recovery budget and camp-only reserve exchanges. Party four, reserve four; reject capture when both are full without spending resources.
- Victory, camp retreat, defeat and confirmed abandonment all settle once and return to a usable hub. Victory/retreat can bank at most one living expedition-caught recruit; defeat/abandon cannot. Committed capture discoveries persist through every outcome. Record completed expeditions; no hub-upgrade economy in this milestone.
- Schema v3 with profile plus optional active expedition, stable run/settlement IDs, all RNG streams and safe checkpoints. Migrate v1 through v2, preserving collection identity/species/cosmetics and settings; normalize combat state for new rules. Preserve a recoverable legacy backup and never silently discard an old collection. Continue restores the same run; no mid-turn resume or intentional rollback UI.
- Programmatically generate all needed sanctuary, route/camp/guardian, relic, journal, checkpoint and outcome artwork using ART_DIRECTION.md. Update guidance from both existing NPCs. Audio and wider content are deferred to M6.

Acceptance:

- Complete hub -> starter choice -> generated exploration -> capture/build choice -> camp -> guardian victory -> recruit selection -> hub -> second expedition. Separately exercise camp retreat, defeat and abandonment; no softlocks or lost sanctuary originals.
- Fixed seeds reproduce route options, walkable maps, encounter/reward outcomes and RNG continuation. A documented multi-seed set demonstrates variation; connectivity/spawns/exits/camp/guardian access always pass. No repeat-stage farming or bypass of recovery limits.
- Tests verify normalization/reset boundaries, full party/reserve refusal, camp exchange limits, discovery retention, eligible/ineligible recruits, every settlement outcome and duplicate/stale settlement rejection. No duplicated recruits, completion credit or rewards on retry/reload.
- Test schema migrations, profile/active-run round trips, unsupported versions, corruption and every checkpoint/settlement interrupted-write boundary. Persist profile and expedition together. Recovery never grants an outcome twice or silently rerolls an in-progress encounter. Actual player saves remain untouched by diagnostics.
- Keyboard/virtual gamepad reach and leave every run/setup/reward/camp/result screen. All earlier unaffected mechanics regressions pass; update tests for deliberately replaced RPG rules. Run clean-import validation and inspect native/3x art and full-loop captures.
- Record measured run duration, resource pressure and known balance limitations. Inspect victory and failure loops interactively before marking complete; 20-30 minutes is a tuning target, not a required unmeasured claim. Stop before M6.

Observed M5 result: permanent profile plus optional expedition; starter normalization; three seeded traversable stages with two route choices and two finite wild lights each; camp after stage two; three relics; guardian; victory/retreat/defeat/abandonment; one eligible recruit or none; camp-only reserve exchanges/confirmed releases; schema v3 checkpoints and v1/v2 migration with preserved source backup. Six generated atlases, thirteen regions, three animations and three baked templates are saved. State tests pass 1,402 assertions over 64 seeds/384 routes; default-app flow passes 98; art passes 111; screenshots pass 175. Ten suites and startup pass in a fresh-cache copy, with earlier regressions preserved. A scripted real-time GPU victory/admission run took 55.28 seconds; the slice is much shorter than the eventual 20-30 minute target. See PROGRESS.md for measured bot outcomes, evidence and remaining limits. Stop before M6.

## M6: roguelite variety, progression and balance - complete

After M5 passes, expand to six creature entries total including three growth forms. Add route/event variants, broader relic synergies and permanent sanctuary/waystation improvements that unlock choices rather than mandatory stat grinding. Growth is expedition-local; returning recruits normalize to their base-form starter definition. Add original procedural music/SFX and settings for their mix. No mandatory linear restoration campaign.

Acceptance: repeated complete expeditions show multiple viable team/build plans, meaningful route choices, discoverable recruitment and lasting hub progression. Failed runs still allow immediate re-entry. No dominant mandatory unlock/grind path; migration/checkpoint/settlement regression passes for added content. Generate and inspect all creature/form/environment/relic/hub/audio assets. Document measured balance and content limits before release work.

## M7: accessibility and desktop release — planned

Input remapping, physical controller/accessibility review, text/motion/flash settings, supported-scale UI polish, save compatibility and desktop export. Generate missing presentation assets rather than use placeholders.

Acceptance: complete expedition regression; keyboard/physical gamepad/focus/reconnect checks; clean desktop export/import/launch/continue/settlement smoke tests; licenses/credits; supported-scale inspection and documented finished-content boundary. Verify existing profiles remain usable or offer a safe, explicit migration path. Release only after complete victory and defeat-to-next-run playthroughs.

## M6 progression specification and scope gate

The progression contract is [META_PROGRESSION.md](META_PROGRESSION.md). Its bounded initial scope supplements M6 above: three base-species research tracks and three growth forms (six entries total), Research Marks, three one-tier sanctuary projects, six temporary relics total, starter medals and two optional challenge tiers. Keep the previously planned route/event variety, procedural audio and measured balance work. No added biome/base-species expansion, equipment or permanent combat-stat grind.

M6 acceptance also includes the specification's outcome reward table, versioned backfill, exactly-once mark/research/purchase grants, departure snapshots, readable goals/results and measured reward pacing. Full normal victories without projects must remain viable; currency cannot gate another departure. All numbers are initial tuning targets. The subsequent user implementation request authorized M6. M6 is now implemented; stop before M7. Tuning targets remain hypotheses where not established by the observed samples.

Observed M6 result: nine species research objectives, Research Marks, three one-tier sanctuary projects, frozen preparation/growth/XP rules, three level-7 forms (six total entries), six relics, three finite trail-stop variants, normal starter medals and two optional challenge tiers. Original art/audio sources produce eight atlases, 31 regions, 12 animations, three SpriteFrames and nine PCM tracks/effects. v4 migration preserves older collections/active descriptors and original backups. Six new suites plus earlier regressions and fresh-import validation pass; detailed counts, 432 fixed-policy runs and real-time victory/retreat/defeat measurements are in PROGRESS.md. Human pacing/mix/input remain review items; the compact slice does not meet the 20-30 minute target. M7 is unstarted.

## User-requested post-M6 scenery polish

Authorized separately on 2026-10-20: replace repeated background presentation with six tree silhouettes, four reusable house designs (distinct existing town facades), four flower varieties, sparse ground dressing and subtle baked animation. Acceptance: repeatable art/selection, fixed trunks/roots and collision, native-size review, actual rendered motion, current exploration/save/expedition regression and clean-import validation. This visual refinement does not begin M7 or add gameplay/content milestones. Evidence and observed results are in PROGRESS.md and artifacts/visual/environment/.

## Separately authorized music polish after M6

Scope: replace the short mono soundtrack with five sixteen-bar original stereo context themes, improved synthesized SFX, crossfades/resume, independent effect voices and outcome ducking. Acceptance: reproducible baked assets, lossless import/valid loop frames, signal and mixer tests, real audio playback/loop/mute checks, actual app context checks, saved-settings regressions and cache-free validation. See AUDIO_DIRECTION.md and PROGRESS.md for evidence and human listening limits. This pass does not start M7 or change expedition/progression scope.