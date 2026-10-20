# Lanternwild - monster-collecting roguelite

Open project.godot in Godot 4.7.2 and press F5. M6 adds permanent research, sanctuary projects, growth forms, new relics, optional challenges and original procedural audio to the expedition loop. All art/audio is baked with reproducible sources; playing requires no generation or supplied assets. M7 release/accessibility work is unstarted.

## Controls and first expedition

Arrows/WASD or D-pad/left stick walk. E/Z/Enter/Space or gamepad A confirms/interacts; Esc/X or B backs out. Tab/M or Start opens the journal while idle. Menus use up/down and four-row pagination. Physical controller feel still needs hands-on review.

At Lantern Rest, talk to Mara/Ivo and open the journal. START EXPEDITION chooses one sanctuary companion, then shows the departure briefing. Review your goal, kit, survey, relic pool, challenge and growth permissions before DEPART. You start with a healthy level-5 copy; the original remains safe. The default kit is four charms/two balms, and departure is always free.

Pick one of two themed routes per stage. Clear both marked fern lights, then follow the large gate. Each encounter is finite, including fleeing; cleared lights cannot be farmed. Face a trail stop and interact: road springs heal the first living ally by 8, ridge herbs heal living party members by 4, river shrines trade one balm for two charms. Every stop also offers one charm for one balm. One choice per stage, no revives, maximum five of each supply; leave without spending if neither choice helps.

MOVES attacks, BAG uses charms/balms, PARTY switches, LEAVE attempts escape. Grove beats Brook, Brook beats Ember, Ember beats Grove. Weaken before capture; invalid actions cost nothing. The guardian rejects capture/flee. Choose or decline one relic at each stage reward. After stage two, camp offers one team/reserve heal/revive without refills; exchanges, deposits, withdrawals and confirmed capture releases are camp-only. Protect the starter and last healthy party member.

Victory or camp retreat may bring home one living expedition-caught individual, or none. Defeat/abandonment admit none. All outcomes preserve sanctuary originals and committed research/stage marks. Levels, XP, temporary forms, items, other captures and relics reset. Returning forms become their base starter species.

## Permanent goals and unlocks

- RESEARCH: Discover by capture; Shelter by bringing a species home; Study by winning three distinct non-guardian battles with that species active. Each objective grants one mark once. Initial Brindlewick/Cindrel Shelter gives two starting marks. Shelter plus Study permits expedition-local growth at level 7: Briarwarden, Pyrelace or Tideveil. Unlocks earned mid-run apply at the next departure.
- PROJECTS: Trail Desk costs 4 marks and surveys the first stage-two encounter for a selected species. Packing Bench costs 5 and unlocks catcher (5 charms/1 balm) and care (2/3) kits alongside standard (4/2). Lantern Workshop costs 6 and expands the relic pool to six, with an optional three-relic focus. Pin a project to guide your next run. Walk south to see projects/companions; face a bench to open its project page.
- REWARDS: stages one/two award one mark each when cleared/exited. Guardian victory awards the third-stage mark; returning commits a one-mark victory bonus. Results separate recruit, earned marks, secured stage marks, bonus and research. Committed marks survive failure; quitting alone grants nothing. Purchases never grant permanent attack/health.
- RELICS: Thorn +3 damage; Shell -3 incoming damage (minimum 1); Hearth heals living party by 6 after victory/capture. Workshop adds Ember Glass (+7 damage at half HP or lower), Dawn Feather (+6 first-turn damage), Charm Leaf (+15 percentage points capture chance, capped 95%). Two unowned offers per reward, or the remaining one; at most three selections per run. Mixed uses all available relics, focus uses the three Workshop relics.
- MASTERY: normal clears give a medal for the base starter. A normal victory unlocks tier 1 (+4 guardian damage); beating tier 1 unlocks tier 2 (also camp recovery to 50% maximum HP, without lowering higher HP). Optional tiers grant pennants rather than extra currency/power. Normal mode remains free.
- NEXT GOALS shows up to three relevant objectives. PREPARATION changes next-run choices; SETTINGS controls battle pace and independent music/SFX mute or three mix levels. The complete reward contract is [META_PROGRESSION.md](META_PROGRESSION.md).

## Saves and Continue

Schema v4/content m6.1 stores permanent profile and active expedition together under user://saves/ (normally %APPDATA%/Godot/app_userdata/Lanternwild/saves/ on Windows). Departure, route/reward choices, completed battles, camp/field actions, purchases, preparation and settlement write verified checkpoints. Startup offers CONTINUE for an active run. Ordinary walking resumes from the latest checkpoint; an interrupted battle restarts its saved pre-battle encounter, without rerolling. There is no mid-turn resume or rollback picker.

v1/v2 collections migrate with identity/species/cosmetics/settings intact and preserve legacy_v2.json. v3 profiles backfill explicit Discover/Shelter once, with no invented battle studies, stage rewards or medals; active encounters/RNG and prior growth rules stay intact. The original v3 envelope is preserved as legacy_v3.json before replacement. slot.json, pending.json and backup.json support recovery. Unsupported/unrecoverable slots block fresh overwrites. Failed writes leave the live candidate unapplied and remain retryable. One game instance is assumed; no hardware power-loss or concurrent-writer guarantee. Diagnostics use isolated ignored save directories.

## Manual playtest and known limits

Try each starter and all four outcomes. Capture a new species, secure it by camp retreat, finish its research, then start a new expedition and reach level 7. Buy projects in different orders; check supplies/surveys/relic pools, duplicate purchase refusal, next goals and visible hub fixtures. Compare normal/tier 1/tier 2, including spent/half camp rest. Restart during exploration and battle; Continue should preserve choices/opponent. Check cancellation, held directions, focus loss, controller feel, native-size readability and music/SFX mix/mute.

This remains a small forest with three base species, three forms, three templates, six wild lights, three trail-stop variants and one guardian. Projects/research/mastery have finite completion; spare marks have no further sink. A scripted real-clock GPU victory/retreat/deliberate defeat took about 55/31/15 seconds, excluding human decisions. This is far shorter than the eventual 20-30 minute target. Fixed-policy seed results and reward/resource limits are in [PROGRESS.md](PROGRESS.md); they are not human difficulty or duration estimates. No new biome, equipment, breeding, remapping or desktop export is included.

## Validate and inspect

```powershell
.\tools\validate_m6.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Capture -CleanImport
```

Runs M1-M5 regression plus six M6 art/audio, state, transaction, rules/connectivity, default-app flow and balance suites. Capture renders native/scaled GPU views and checks exact palette/scaling; CleanImport runs all sixteen suites and startup in a source copy without import cache. Nonzero exit, missing success marker or Godot warning/error fails validation. Logs/saves/copies are under ignored .godot/m6_validation/ and earlier folders.

M6 generation phases: --headless --path . --script tools/art/generate_m6.gd; --headless --path . --editor --quit; --headless --path . --script tools/art/assemble_m6.gd. Prefix each with your Godot executable. tools/art/capture_m6.gd renders isolated visual evidence; tools/art/play_m6.gd measures real-clock victory/retreat/defeat. Captures identify controlled completed-profile/growth presentation fixtures and never write player saves. Runtime loads baked art/audio and generates only route data.

Evidence: artifacts/visual/m6/. Historical apps: tests/fixtures/legacy_game.tscn (M3/M4), tests/fixtures/m5_game.tscn (M5); tests/progression/ exercises the actual default M6 app. Earlier captures preserve their historical rules.

Design and boundaries: [GAME_DESIGN.md](GAME_DESIGN.md), [ROADMAP.md](ROADMAP.md), [ARCHITECTURE.md](ARCHITECTURE.md), [ART_DIRECTION.md](ART_DIRECTION.md), [PROGRESS.md](PROGRESS.md).

Scenery polish: the current app uses varied tree silhouettes and house facades, sparse ground plants and slow ambient foliage/flower animation. Stand still for several seconds in town or on a route to see the breeze. Source/evidence: tools/art/environment_recipes.gd and artifacts/visual/environment/. Validate with tools/validate_environment.ps1 -Godot <your Godot executable> -Capture -CleanImport; this checks the art, renderer isolation, world/current expedition/save flow and clean imports. M7 remains unstarted.

## Music rework

Five original stereo themes now cover sanctuary, forest, camp, wild battles and guardians; sixteen-bar arrangements replace the early eight-second loops. Crossfades resume exploration music, and reward jingles have their own voice and temporarily soften music. SETTINGS retains independent music/SFX mute and three levels. Sources and mix contract: [AUDIO_DIRECTION.md](AUDIO_DIRECTION.md).

```powershell
& tools/validate_audio.ps1 -Godot 'D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' -Playback -CleanImport
```

This regenerates/reimports the score, validates repeatable PCM/mixing and app flow/settings, records real playback, then runs checks in a cache-free copy. -Playback needs a graphical/audio session. Logs and a short recorded transition/loop preview are under .godot/audio_validation/; individual full tracks are assets/generated/audio/*.wav. Listen to a whole loop in each location, compare wild/guardian energy, return from battles, trigger capture/growth/victory, and test all music/SFX levels. Subjective mix and melody review still needs human listening.