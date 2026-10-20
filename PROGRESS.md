# Progress

Updated: 2026-10-20 (America/New_York).

## Status

M0-M6 complete. The user's latest implementation request authorized M6 after the meta-progression design review. F5 runs scenes/app/game.tscn / scripts/core/progression_game.gd. M7 accessibility/export/release is unstarted; no additional biome/base species, equipment, economy tiers or campaign were added.

## Delivered M6

- Permanent Discover/Shelter/three-distinct-active-wins Study tracks for each base species; one mark per objective, with two initial Shelter marks. Finite stage-one/two marks survive every outcome; guardian victory commits stage three and settlement commits its bonus exactly once. The one-living-recruit victory/retreat contract and safe sanctuary originals remain intact. No permanent combat XP/items/relics/stat purchases.
- Trail Desk (4 marks), Packing Bench (5), Lantern Workshop (6): stage-two species surveys, three supply kits and mixed/focus relic pools. Candidate-based hub purchases, project pinning and actionable next goals. Visible unavailable/affordable/built fixtures, direct bench interaction/collision, resting species displays and mastery decorations. Spare marks have no later sink.
- Six creature definitions: three existing bases plus researched level-7 Briarwarden/Pyrelace/Tideveil forms. Forms grow after XP claims within an expedition and normalize to bases on recruitment. New-run XP is 16 + 8 times wild level; a tested focused partner grows before guardian combat. Already-active v3 runs retain their old XP rate and no retroactive growth unlock.
- Six temporary relics, two seeded unowned offers per reward, decline/fallback behavior and at most three selections. New niches: injured Ember Glass +7 damage, first-turn Dawn Feather +6, Charm Leaf +15 percentage points capture chance (95% cap). Three template-linked finite trail stops: first-living-ally spring, living-party herbs, balm-for-charms shrine; all also offer charm-for-balm trade. No encounter/reward farming.
- Normal starter medals and two optional challenge tiers. Tier 1 adds four guardian damage; tier 2 also limits camp healing/revival to half maximum, without reducing healthier HP. Normal remains free and available. Challenges award recognition rather than currency multipliers or mandatory power.
- Schema v4/content m6.1 stores research, marks/grant ledger, projects, preparation, medals and immutable departure rules with the run. v1/v2 and v3 backfill explicit Discover/Shelter once, never infer prior studies/stage earnings/medals. Preserve collection IDs/cosmetics/settings, active pending descriptors/RNG and independent legacy_v2.json/legacy_v3.json originals. Exactly-once candidate publication and failed-purchase/result/admission retry remain transactional.
- Eight original atlases, 31 named regions, 12 animation records, three baked SpriteFrames, nine original 22,050-Hz mono PCM music/effect files. Reproducible integer-pixel/form/fixture/token/relic recipes and envelope-based audio generation. Scene-local hub/forest/battle music, input/hit/capture/growth/victory/defeat cues, independent retained music/SFX mute and three mix levels. Headless tests inspect audio but skip inaudible playback.
- Journal/setup/research/project/preparation/pool/survey/challenge/mastery/goals/trail/result screens retain bitmap styling and four-row pagination. Results explicitly separate recruit, earned marks, stages, victory bonus and research. Existing M5 app now lives at tests/fixtures/m5_game.tscn; its flow/capture tests remain historical regressions. tests/progression/ validates the actual default app. All planning documents and README were aligned with the current rules.

## Observed validation

Godot 4.7.2.stable.official.ed1daf0bf, Compatibility/OpenGL 3.3 on NVIDIA RTX 3070. Ran tools/validate_m6.ps1 -Capture -CleanImport including the full M1-M5 chain; after XP tuning, reran M6 validation with fresh-source checks and focused final snapshot tests. All final suites/import/startup/captures pass without Godot warnings/errors.

| M6 check | Observed result |
|---|---|
| State/save/migration | 831 assertions PASS; seeds 0-15 x three starters with checkpoint/terminal/settled round trips, originals, outcomes, finite events, research/backfill and malformed meta state |
| Transactions/progression | 167 assertions PASS; interrupted battle/research, stage, three project purchases and settlement file arrangements; duplicate grants/charges, v3 source preservation, natural pre-guardian growth, form checkpoint, both actual challenge-tier wins and half rest |
| Rules/routes | 1,585 assertions PASS; relic niches/capture cap, guardian cost/RNG guards, three event variants, stage-two surveys, missing snapshot fields, 384 generated maps with event/lights/exit connectivity |
| Actual default-app flow | 88 assertions PASS; keyboard/gamepad screen entry/back, real walking/resolver capture/victory, project unlock/visible fixture, failed purchase/admission I/O and retry, second departure, pending-battle restart/Continue with same descriptor/rules, confirmed abandonment; 108 steps/26 commands with accelerated test clocks |
| Art/audio | 107 assertions PASS; two clean PNG/PCM/metadata generations match, palette/hard alpha/dimensions/regions, four front/back idle/reaction animations per form, imported non-silent bounded audio; three assembled resources repeat byte-identically |
| GPU screenshots | 46 native/3x interface/world views, four native/2x full maps, native/3x art sheets and contact sheet: 103 PNGs. 196 palette/dimension/exact-nearest checks PASS. Inspected fixtures/scale/collision composition, research/results, relics, form fronts/backs and full maps |
| Multi-seed sample | 27 configurations x 16 seeds = 432 actual-resolver expeditions; 8,975 commands, zero invalid-command/timeouts. All outcomes preserve originals and allow another departure. Fixtures expose third starter/unlocked content without touching player saves |
| Fresh source | Import/startup plus all sixteen suites PASS in a copy without .godot/import cache; final root snapshot-focused state/transaction/rules/flow tests also PASS; the last resting-companion placement and added failure views passed focused flow/GPU/screenshot checks |

Earlier regressions also PASS: M1 494 asset/control +18 screenshot; M2 2,733 world +33 screenshot; M3 280 art +119 battle (catalog now includes forms) +52 screenshot; M4 33 art +168 system +51 screenshot; M5 111 art +1,402 state +98 flow +32 seeded simulations +175 screenshot. Historical app-specific assertions use explicit fixtures.

## Measured balance and pacing

[Curated observations](artifacts/validation/m6/observations.json) records the fixed-policy sample and real-clock GPU runs. Ignored .godot/m6_validation/ contains detailed logs, independent save directories and source copies. No diagnostic wrote the player's slot.

| Starter | Fresh/no-project normal wins | Unlocked standard/mixed normal | Tier 1 | Tier 2 |
|---|---|---|---|---|
| Brindlewick | 15/16 | 15/16 | 15/16 | 13/16 |
| Cindrel | 13/16 | 12/16 | 12/16 | 12/16 |
| Rillume | 12/16 | 13/16 | 11/16 | 7/16 |

Unlocked normal kit/pool samples ranged from 6/16 to 16/16 wins. Mixed pools produced 14-16 distinct ordered builds per sixteen seeds versus 5-8 for focus and three for fresh profiles. Care usually improved survival; Rillume catcher secured 15 captures versus 13 with care, at lower win rates. The bot caps its party target at two, undervaluing extra capture supplies; these are diagnostic comparisons, not proof of equal options or human win rates. No project is required for sampled wins. Growth, affinity switching and supply tradeoffs matter; further human review may identify dominant strategies.

Real movement/battle clocks, no combat-stat fixtures, minimal decision delays:

| Outcome | Time | Commands / steps | Marks earned | Supplies left |
|---|---|---|---|---|
| Victory/admission | 54.882 s | 21 / 96 | 6 (3 stages +1 victory +2 research) | 2 charms /1 balm |
| Camp retreat/admission | 30.701 s | 10 /64 | 4 (2 stages +2 research) | 2 charms /2 balms |
| Deliberate defeat | 14.451 s | 5 /26 | 0 | 4 charms /2 balms |

The defeat script deliberately uses weak attacks and no recovery; it is not a normal loss-rate sample. First project affordability occurred about 15.47 seconds into the victory script; buys remain hub-only. Removing one-time research yields approximately 4.37 repeatable marks/minute for victory versus 3.91 for retreat at those measured durations. One-time research can make an early retreat efficient while safely securing a recruit. Fifteen marks buy all projects; the initial arc is intentionally short, not an endless progression grind.

Review fixes included correct JSON/snapshot validation, unchanged migrated XP/RNG rules, source-backup preservation, finite shrine capacity guards, natural pre-guardian growth timing, growth HP presentation, result/back navigation and separate reward accounting, distinct medals/pennants, smaller resting companions, fixture placement/collision and isolated overview viewports. No remaining observed code/import/asset errors.

## Remaining limitations and manual playtest

- The slice remains much shorter than the eventual 20-30 minute target. Three templates/base species, three forms/stops/projects and one guardian provide a finite replay arc. No additional biome, boss roster, equipment or post-project currency sink. All six effects are simple modifiers; focus lacks recovery relics and can punish some teams.
- Human timing, resource/build balance, research/project pacing, challenge difficulty and how satisfying it feels to return home need playtest feedback. Physical controllers/analog menu feel, accessibility/remapping, other GPUs/platforms and desktop exports remain M7 work. Graphical playback was exercised; human listening/mix review remains necessary. The initial eight-second music has been superseded by the separately authorized score rework recorded below.
- Normal supplies rarely fill all eight party/reserve slots; capacity/edge UI use controlled fixtures. Some completed-profile/growth screenshots and unlocked balance samples are explicit presentation/content fixtures; ordinary victory/retreat/defeat timing uses actual app rules without combat-stat fixtures.
- Ordinary walking is not saved every tile; interrupted battles replay from their saved start, not mid-turn. Saves assume a single writer; file-arrangement tests do not establish physical power-loss/concurrent-write durability. No cloud sync or tamper-proof promise. Cosmetics retain seeds but still use base species colors.

Manual review: follow README controls; capture/admit Rillume, complete a species' three study wins, then depart again and focus XP until level-7 growth before the guardian. Buy projects in different orders and inspect the southern hub; test standard/catcher/care kits, stage-two surveys, mixed/focus relics, all trail choices and declined rewards. Compare normal/tier 1/tier 2 including half/spent camp rest. Try victory, retreat, defeat and abandonment; check mark/recruit/reset behavior and another free departure. Restart with an active run/pending battle and Continue. Check gamepad cancel/focus, held directions, native-size text and music/SFX mute/mix. M7 has not begun.

## User-requested scenery polish - 2026-10-20

Added six distinct original tree silhouettes, four reusable house facades (the town's two buildings now differ), four flower varieties and sparse fern/clover/mushroom/leaf-litter dressing. Slow, desynchronized baked poses move upper leaves and flower tips by one pixel while trunks/roots stay pinned. Hidden worlds pause animation. Selection/scattering is deterministic and renderer-only: no map/collision/save/RNG or progression changes, and no M7 expansion. Recipes, four PNG atlases, eighteen named regions and before/after/animation evidence are saved in-project.

Validation with Godot 4.7.2: environment suite 1,226 assertions PASS; world 2,733 PASS; current M6 expedition flow 88 PASS; M6 state/save 831 PASS. GPU capture on NVIDIA RTX 3070 produced the actual viewport, before/after town, three route overviews, variant/animation sheets and eight wind samples (24 PNGs); screenshot checks pass 34 assertions for dimensions, palette, exact scaling and actual changing rendered poses. Inspected native/scaled composition and animation. A preview capture initially froze nodes before scene entry, allowing automatic processing to override sampled poses; corrected the capture order and verified distinct rendered frames. Static scenery disables processing after scene entry.

Run tools/validate_environment.ps1 -Capture -CleanImport with the documented Godot argument to repeat the checks; the same four suites, startup and import pass in a cache-free source copy. Detailed logs and isolated saves are under .godot/environment_validation/. The user's pre-existing project.godot editor/settings change is preserved and excluded from this checkpoint.

Manual review: F5, compare the lodge and blue-roof house, walk around the southern sanctuary and river/ridge/road routes, then stand still for 7-10 seconds to watch gentle crown and flower-tip movement. Check character/tree occlusion and doorway/trunk collision. The scenery retains the 320x180 woodland palette; this is a small visual refinement, not a new biome or gameplay milestone. Palette, movement amplitude and sparse dressing are intentional; physical-display comfort and whether the backdrop feels varied enough still benefit from human review.

## User-requested music rework - 2026-10-20

Replaced the default app's short mono score with five original sixteen-bar stereo arrangements: sanctuary (40s), forest (35.56s), camp/settlement (48s), wild battle (29.09s) and guardian (26.67s). Layered rounded leads, plucked accompaniment, bass, bridge harmony, seeded percussion and quiet stereo echoes are generated from retained GDScript sources. Eight new effects distinguish navigation/back/confirm, hit, capture, growth, victory and defeat. Thirteen committed WAVs total 16,398,556 bytes; the versioned manifest records frame counts, tempo, duration, RMS and PCM digests. No samples, external audio assets or game-RNG use.

The scene-local director crossfades over 0.8 seconds, resumes interrupted themes and keeps UI/action/outcome voices separate. Outcome jingles duck music; UI cues cannot steal them. Music/SFX retain independent saved mute/three-level controls. Music mute pauses and unmute resumes. Explicit camp/guardian selection and pending-battle restoration avoid an intermediate forest request. Hit presentation keys now distinguish both combatants within one turn. Gameplay, saves/content versions and M7 scope remain unchanged. The historical M6 mono assets/generator remain regression fixtures; runtime loads assets/generated/audio/.

Observed validation on Godot 4.7.2 / Compatibility:

- tools/validate_audio.ps1 -Playback -CleanImport PASS: audio suite 101 assertions (byte-identical regeneration and manifest, PCM/stereo/duration/peak/RMS/seams/gaps, fades/resume/mute/ducking/rapid changes); current actual-app expedition flow 105 assertions / 108 steps / 26 commands; state/save/settings 831 assertions; app startup/import clean.
- Graphical-session audio playback PASS, 15 assertions: each of five real players crosses its loop boundary, concurrent UI/jingle, actual pause/resume and non-silent unclipped output recording. Evidence: .godot/audio_validation/mix_preview.wav; logs under .godot/audio_validation/logs/. This records the real mixer, not a claimed human listening review.
- Cache-free source copy imports the committed assets and passes the same 101 audio, 105 flow and 831 state assertions plus startup. Source copy: .godot/audio_validation/clean_25397b2ef8de49d29633726455f72653/.
- tools/validate_m6.ps1 -SkipFoundation PASS: art 107, state 831, transaction 167, rules 1,585, original flow 88 (run before the 17 audio-context assertions were added), balance 27 configurations x 16 seeds = 432 runs, startup and generation/assembly. Earlier M1-M5 foundation suites were not rerun for this audio-only pass; final expanded flow passes separately above.

Validation found and fixed default QOA WAV imports: stereo PCM loop frames must use byte count / 4 and lossless compress/mode=0. Initial hash API and playback-test typing issues were corrected before passing checks. No remaining observed import, script, mixer or regression errors. The pre-existing project.godot editor/settings edit is preserved and excluded from this checkpoint.

Manual listening: F5, hear a whole loop at home and in the forest, enter/leave several wild encounters, rest at camp, reach the guardian and return home. Trigger capture/growth/victory/defeat and move through menus while the jingle plays. Check music/SFX independently at all levels, mute/unmute mid-track, and Continue a saved battle. Full individual tracks are in assets/generated/audio/; the recorded preview deliberately samples transitions/loop boundaries rather than full compositions.

Remaining limits: signal/playback checks cannot judge melody, fatigue or perceived loudness on headphones/speakers. Crossfades are time-based rather than beat-synchronized; positions reset when the application restarts. No adaptive stems, environmental ambience/spatial audio or export/physical-device certification. M7 has not begun. AUDIO_DIRECTION.md documents the score and reproduction contract.