# Meta progression and reasons to return

Implemented M6 progression contract. M5 behavior below is the historical baseline. GAME_DESIGN.md owns the core expedition rules; this document specifies their permanent reward loop. Numbers below are initial tuning hypotheses, not measured balance. The subsequent user implementation request authorized M6; M7 remains outside scope.

## Player promise

Build a woodland sanctuary, understand its creatures, and unlock new ways to explore a dangerous forest. Each expedition should answer a personal goal and reveal a tempting next one: bring Rillume home, finish its research, try its growth form with a new relic, then defeat a harder guardian.

The repeating loop is: choose a visible goal -> choose starter/loadout/route -> make a temporary team and build -> secure discoveries and milestones -> settle rewards -> see what changed at home -> choose the next experiment. The player should leave the results screen knowing what they earned, how close their next unlock is, and what they can try now.

## Historical baseline and M6 contract

M5 retains sanctuary individuals, capture discoveries, completion records and settings. Victory/camp retreat can bring home one living capture. Defeat/abandonment bring none; originals always survive. Levels, XP, health, supplies, relics and route progress reset. There are three base species and three relics, all obtainable within a completed run. These rules provide a collection foundation, but little long-term replay variety.

M6 keeps those reset and recruitment rules. It adds research, one modest project currency, visible sanctuary improvements, broader temporary builds and optional mastery challenges. It does not add permanent combat levels, breeding, equipment rarity grinding, daily chores or random permanent stat rolls.

## Reward layers

| Layer | Player question | Permanent reward | Reason to depart again |
|---|---|---|---|
| Collection | Can I bring that creature home? | Individual with stable identity/species/cosmetics; new species becomes a starter option | Try a different starting affinity and team plan |
| Research | What can this species do? | Visible one-time species objectives and unlocks | Complete a different task rather than repeat the same encounter |
| Sanctuary | What can I build for everyone? | Project progress, visible fixtures and alternative preparation choices | Test a newly unlocked loadout or route feature |
| Mastery | Can I win another way? | Starter medals, optional challenge tiers and cosmetic recognition | Beat a guardian with a different plan or harder rules |
| Temporary build | What combination will work this time? | Knowledge and a run summary, not banked relics | Try a combination excluded by the previous run's choices |

Duplicates are optional individual/cosmetic collection. They do not grant stronger starter stats, currency on release or a required duplicate-fusion ladder. No rare cosmetic hunting is required for mechanical unlocks. Current art uses base colors; additional cosmetic variants are later content, not an M6 promise.

## Research: specific goals, not an XP bar

Use three visible, one-time objectives per base species:

1. Discover: successfully capture that species and commit its battle result. Unlock its journal entry; retained even if the run later fails. This does not grant a sanctuary starter.
2. Shelter: admit that species after victory or camp retreat. Unlock its expedition growth-form research and a small sanctuary display. Existing sanctuary species satisfy this automatically.
3. Field study: win three distinct non-guardian encounters with that species active when the battle ends, across any number of runs. Captures/flee do not count. A repeated/recovered encounter never counts twice. Unlock its growth form for future expeditions once Shelter is also complete.

Field study can progress using captured expedition teammates before Shelter is complete. Growth is expedition-local at level 7 after a victory/capture XP claim; the research unlock permits growth, it does not start the companion evolved. Returning recruits normalize to their base definition. Three base species plus their three growth forms make the six entries already planned for M6; adding more base species is later scope.

Capture/discovery and battle-study progress commit with their battle checkpoint and survive every outcome. Objectives award at most one Research Mark each, including Discover/Shelter/Field study: nine marks total from the initial roster. Tasks, counts, prerequisites and exact reward are visible before departure; no hidden checklist or random research drops.

## Research Marks and sanctuary projects

Research Marks are permanent, noncombat project currency. They never buy supplies during a run or convert to stats. Earn one mark for completing each of the three stages, plus one for guardian victory: at most four repeatable marks per full expedition. Stage completion is the first committed exit after its finite encounters are cleared, before choosing its reward. Guardian victory supplies the third-stage mark and victory bonus together. Merely entering a stage, fleeing, or opening a chest earns nothing.

Stage marks earned before defeat, retreat or abandonment remain. This deliberately gives failed expeditions a useful floor; early abandonment with no new stage/research completion earns nothing. Clearing the same stage again in another expedition can earn another mark. Within one expedition, stage IDs and research objective IDs prevent duplicate grants. Balancing should measure marks per minute as well as success rate so repeated early retreats do not outperform pursuing victory for project progression.

Three one-time projects form the complete M6 spending scope. Choose purchase order; no purchase is mandatory for departure or the first victory. Prices are provisional, and each project has one tier.

| Project | Cost | Visible sanctuary change | Unlocked choice |
|---|---|---|---|
| Trail Desk | 4 marks | Map table with lit trail markers | Before departure, choose ordinary mixed encounters or a survey that favors one disclosed base species in a designated stage; same finite encounters and rewards |
| Packing Bench | 5 marks | Workbench, charm rack and balm shelf | Choose standard 4 charms/2 balms, catcher 5/1, or care 2/3; supplies reset every run, no stockpile |
| Lantern Workshop | 6 marks | Lit display of discovered lanterns | Expand the relic pool from three to six; show new effects and offer one optional three-relic focus set with mixed default available |

The workshop adds sidegrades, not strict replacements for starter relics. Balance loadouts by capture/healing opportunity cost, not price paid per run. A focus set restricts the eligible pool but guarantees no specific relic; depleted offers use remaining eligible relics and never repeat a grant. Relics can be declined without trapping progression. Publish the pool and fallback rules before launch.

Fifteen marks buy every project. At four marks per complete victory, repeatable rewards alone cover this in four victories; one-time research reduces that requirement, and partial runs also contribute. This is a small initial progression arc, not a promise of dozens of hours. After purchases, marks may remain recorded but have no hidden sink or required currency grind. If collecting marks becomes the main motivation after projects finish, improve playable variety rather than add expensive tiers.

## Outcome guarantees

| Outcome | Retained rewards | Lost/reset | Intended feeling |
|---|---|---|---|
| Victory | Committed research/stage marks, victory bonus, completion/mastery credit, optionally one living recruit | Other captures, temporary combat growth, items and relics | Best broad reward; choose what to try next |
| Camp retreat | Committed research/stage marks, optionally one living recruit | No victory bonus/mastery win; remaining run | Secure a collection goal instead of risking it |
| Defeat | Previously committed research/stage marks | No recruit/victory credit; temporary team/build | A setback with a visible next objective |
| Confirmed abandonment | Previously committed research/stage marks | No recruit/victory credit; temporary team/build | Safe exit, no reward for quitting alone |

Research can unlock during a run, but new projects, loadouts, encounter surveys, relic pools and growth permissions apply to the next departure. Snapshot unlock rules on departure so a checkpoint reload or mid-run research unlock cannot silently change the current run. All settlement rewards and purchases are transactional and exactly once.

## Builds and mastery after the first victory

Increase the relic pool to six and retain only three reward selections per expedition. Present mutually exclusive offers so a completed run cannot collect every effect. Each new relic needs an explicit combat niche and interaction tests; no permanent relic ownership or upgrade leveling. Growth forms and encounter surveys help the player pursue a plan while uncertainty remains in encounters and reward offers.

Record one normal-clear medal per base starter species. The first normal victory unlocks optional challenge tier 1; completing tier 1 unlocks tier 2. Initial modifier candidates are stronger guardian attacks for tier 1 and a disclosed camp-recovery restriction for tier 2; exact values require simulation and human testing. Show the modifier before departure, retain normal mode forever, and do not place essential species/projects behind challenge wins. Challenge tiers award medals and sanctuary pennants, not a mark multiplier or mandatory power. No endless difficulty ladder in M6.

After every result, offer at most three relevant goals, for example: bring Rillume home; win one more field study battle for Cindrel's growth form; earn two more marks for the Packing Bench. Never suggest tasks already completed or unavailable under the selected rules. Challenge completion, all research, all projects and three starter medals are a finite completion goal; replay beyond that depends on enjoyable builds, not an infinitely filling meter.

## Example progression, not a forced sequence

- First run: learn captures, clear a stage and record Rillume. Even a defeat preserves that research and stage mark; show a specific affordable next project or research step.
- Next run: aim for camp retreat with Rillume alive. Its admission unlocks a new starter and completes Shelter, even without beating the guardian.
- Another run: choose the new starter, finish a field study, buy a project and try a different preparation option. A guardian win unlocks the first optional challenge tier.
- Later runs: pursue growth-form builds, select a different relic focus, earn the remaining starter medals and complete the sanctuary. No exact run count is promised: player skill and choices determine the order.

## Presentation and feedback

The hub should visibly develop as projects are bought. Use existing NPC roles: Mara explains companions/projects; Ivo presents trails/research. Generated art must include three fixture states, marks/project icons, research stamps, growth-form entries and mastery pennants. Keep the existing palette, bitmap typography and four-row menu conventions.

Before departure show one pinned goal, starter, loadout, survey, eligible relic pool and challenge modifier. The results screen separates research/stage rewards already secured from the settlement bonus and selected recruit, so it never appears to grant something twice. Show marks earned, total, progress toward the pinned project and any newly available choice. Follow with Return to Sanctuary and an easy route to the next departure; no forced shopping/tutorial tour after every run.

## Bounded M6 delivery and acceptance

Implement the existing M6 roadmap plus exactly this initial progression slice: three species research tracks, their three growth forms, three one-tier projects, three additional relics, three starter medals and two optional challenge tiers. Reuse the forest's template themes for surveys and route/event variety; do not add another biome, more base species, shops, equipment or a quest campaign. Preserve procedural audio and balance work already assigned to M6.

Acceptance requires:

- Every outcome demonstrates the retention table; all originals survive, no failed run admits a recruit, and a new run remains free with zero marks.
- Research/marks have stable event IDs; replayed battles, repeated exits, interrupted saves, migrations, purchases and settlement retries never double-grant or charge. No negative balances or partially installed projects.
- Existing M5 profiles preserve their collection/discoveries/completion count. Backfill Discover/Shelter once from explicit species records; start Field study at zero. Do not infer past stage marks, victories by starter or challenge medals from aggregate completion counts. Grant backfilled objective marks exactly once under versioned migration.
- Unlock snapshots reproduce Continue; mid-run unlocks affect only future departures. Field study requires the actual active winning species and distinct committed encounter IDs.
- All loadouts, surveys, relic pools/fallbacks, growth rules and challenge modifiers are visible, deterministic and tested. Fresh profiles can win without a project; no option is consistently superior across measured seed sets.
- Menus show current/next goal, prices, prerequisites and earned rewards without clipping at 320x180; keyboard/virtual gamepad reach every screen. Generate and inspect all fixtures/icons/forms/relics/medals.
- Measure complete/failed/retreated runs for duration, resource pressure, marks per minute, project-unlock timing, starter wins and build diversity. Compare at least 16 seeds per starter, then request human review of pacing. Record observations rather than claim the 20-30 minute target is met.

Optional later ideas: more base species/biomes, authored guardian variety, cosmetic sanctuary decorating and nonstat challenge objectives. They require a separately approved scope; no daily streaks, battle passes or paid progression.

## M6 implementation and observed limits

The initial slice above is implemented. Default profiles start with two Shelter marks. The Workshop mixed pool offers two unowned relics per reward (or the remaining one), while focus restricts the pool to Ember Glass, Dawn Feather and Charm Leaf; decline is always available. Surveys set the first stage-two light to the selected species and leave the other slot unchanged. Tier 1 adds four guardian damage; tier 2 also heals/revives at camp to 50% maximum HP without lowering healthier members. Normal remains available and free. New runs award 16 + 8 times wild level XP to the active recipient; a focused researched partner can grow before guardian combat. Already-active v3 runs keep their original rate. No project is needed for measured fresh-profile wins.

Three forest template themes now have finite spring, herb patch and shrine choices; rewards never add permanent combat power. Existing v3 profiles backfill research once and preserve active encounters/RNG with legacy growth permissions empty; no past stage marks, field studies or medals are invented. v1/v2 and v3 originals retain independent recovery copies.

Real-clock scripted GPU runs measured 54.882 seconds for victory (+6 marks including two research), 30.701 for retreat (+4 including two research), and 14.451 for deliberate defeat (+0). Removing one-time research gives approximately 4.37 repeatable marks/minute for victory versus 3.91 for retreat in these samples. This arithmetic is diagnostic, not a human efficiency or duration claim. The first project became affordable about 15.47 seconds into the victory script. The compact game remains far below the 20-30 minute target and has a deliberately finite fifteen-mark project arc; more expensive grind tiers were not added. See PROGRESS.md for the final seed sample, validation and manual review needs.
