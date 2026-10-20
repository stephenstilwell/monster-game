# Progress

Updated: 2026-10-19 (America/New_York).

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
- Human timing, resource/build balance, research/project pacing, challenge difficulty and how satisfying it feels to return home need playtest feedback. Physical controllers/analog menu feel, accessibility/remapping, other GPUs/platforms and desktop exports remain M7 work. Graphical playback was exercised; human listening/mix review remains necessary. Music currently uses short eight-second phrases without crossfades.
- Normal supplies rarely fill all eight party/reserve slots; capacity/edge UI use controlled fixtures. Some completed-profile/growth screenshots and unlocked balance samples are explicit presentation/content fixtures; ordinary victory/retreat/defeat timing uses actual app rules without combat-stat fixtures.
- Ordinary walking is not saved every tile; interrupted battles replay from their saved start, not mid-turn. Saves assume a single writer; file-arrangement tests do not establish physical power-loss/concurrent-write durability. No cloud sync or tamper-proof promise. Cosmetics retain seeds but still use base species colors.

Manual review: follow README controls; capture/admit Rillume, complete a species' three study wins, then depart again and focus XP until level-7 growth before the guardian. Buy projects in different orders and inspect the southern hub; test standard/catcher/care kits, stage-two surveys, mixed/focus relics, all trail choices and declined rewards. Compare normal/tier 1/tier 2 including half/spent camp rest. Try victory, retreat, defeat and abandonment; check mark/recruit/reset behavior and another free departure. Restart with an active run/pending battle and Continue. Check gamepad cancel/focus, held directions, native-size text and music/SFX mute/mix. M7 has not begun.
