# Progress

Updated: 2026-10-19 (America/New_York).

## Status

M0-M5 complete. The user authorized M5 after the roguelite documentation pivot. F5 now launches the expedition app through scenes/app/game.tscn / scripts/core/expedition_game.gd. Stop before M6; no additional species/forms, hub upgrade economy or audio implemented.

## Delivered M5

- Explicit permanent profile/sanctuary/journal/settings and optional temporary expedition in one serializable envelope. Depart with one copied level-5 starter, zero XP, four charms/two balms. Sanctuary originals survive every outcome; captured individuals use run-scoped IDs. Discovery is permanent; combat growth/items/relics reset.
- Three seeded traversable forest stages, each offering two themed route choices and two finite marked wild encounters. Three authored templates provide fern road, ridge turn and river bridge, with deterministic grove/prop arrangements. Cleared lights dim; revisits cannot farm rewards. Camp follows stage two; a crowned Brindlewick guardian finishes stage three and rejects capture/flee before costs/RNG.
- Three distinct relics: +3 allied damage, -3 incoming damage (minimum 1), or 6 HP post-victory/capture to living party members. Camp heals/revives team/reserve once without refills. Four-member party/four-slot reserve; camp-only exchange/deposit/withdraw and explicit confirmed release. Protect the starter and at least one healthy member; reject capture when capacity is full without spending resources.
- Composed journal/input modes cover hub/start/Continue, starter, routes, relics, party/balm, reserve/exchange/release, discovery/settings, camp, return/abandonment and results. HUD shows depth, finite lights, health, supply/reserve counts and relic icons. Mara/Ivo explain the loop. Victory/retreat admit at most one living capture or none; defeat/abandon admit none. Settlement and completion/recruit grants are exactly once.
- Schema v3 checkpoints include profile plus active run, all four RNG streams, route/content version, safe position, claim/camp/reward state and saved pending encounter. Continue resumes the same run or pre-battle descriptor. Explicit type/reference/bounds/identity, plan/seed and cross-field chronology validation; canonical strings preserve 64-bit RNG values.
- Verified pending/primary/backup writes preserve transactional live state. v1/v2 migration retains collection identities/species/cosmetics/settings and separately verifies the original legacy_v2.json backup. Unsupported versions/content and unrecoverable existing saves cannot be overwritten. Failed battle-result/admission writes remain retryable; no partial grants.
- Six original raster atlases, thirteen named regions, three animation records, one reusable SpriteFrames resource and three baked template resources. Captured native/scaled maps, journal states, guardian poses, all outcomes and reusable artwork. Recipes, manifests and outputs remain in-project and reproducible.
- Historical M3/M4 integration/capture tests now explicitly use tests/fixtures/legacy_game.tscn; the default scene changed intentionally. Pure mechanics/world/art coverage remains preserved; new tests/expedition/ validates the actual app. All seven root Markdown files and README controls were updated.

## Observed validation

Executed tools/validate_m5.ps1 -Capture -CleanImport with Godot 4.7.2.stable.official.ed1daf0bf. Full run passed without Godot warnings/errors; final release-portrait UI change also passed focused flow/capture/screenshot checks:

- State/save/routes: 1,402 assertions PASS. Seeds 0-63 reproduce 384 generated route variants with connected start/lights/exit. Checks normalization/reset isolation, finite encounters/rewards, source/capture IDs, all outcomes, camp budget, capacity/exchanges/releases, exactly-once battle/settlement, relic effects/RNG, malformed/inconsistent data, v1/v2 migration, preserved legacy source and every safe-checkpoint interrupted-file arrangement including both sides of settlement.
- Actual default-app flow: 98 assertions PASS. Real grid walking and resolver commands reach capture, relics, camp, guardian victory, admission and a second run; also actual wounded-team defeat, camp retreat and confirmed abandonment. Includes pre-battle Continue, failed result/admission I/O and retry, no rollback API during active play, keyboard/gamepad setup/back/cancel, reserve/exchange/release focus and optional journal screens. Automated combined flow: 172 walked steps, 11 driver-counted battles/33 commands plus a separate defeat turn; timing around 1.5 seconds with accelerated test clocks is not playtime.
- Art: 111 assertions PASS. Two clean generations match PNG bytes/metadata, baked template serialization, pixel digests, dimensions, palette/hard alpha, regions/anchors and animation rectangles/timing. Repeated guardian resource assembly is byte-identical.
- GPU capture: actual OpenGL 3.3 / NVIDIA RTX 3070. 31 interface/world views at native/3x, three full maps at native/2x, native/3x original-art sheets and interface contact sheet: 71 PNGs. All 175 screenshot assertions PASS. Inspected native/enlarged composition, portrait/release identification, camp spent state, map/bridge paths, crowned guardian/reactions, return outcomes and resume. No unresolved text clipping/palette drift observed.
- Fixed-policy simulation: seeds 0-15 x both starters, 646 resolver commands; Brindlewick won 10/16, Cindrel 12/16. All 32 outcomes preserve originals and allow another departure; no invalid commands/timeouts. This is diagnostic resource/difficulty sampling, not a human win-rate claim.
- Separate real-time graphical run (tools/art/play_m5.gd): complete victory/admission in 55.28 seconds and 21 commands at real movement/event clocks, with no combat-stat fixture. The script minimizes decisions/exploration, so this is not a human duration estimate. Six wild battles, four charms, two balms and one rest create meaningful supply/switch/capture tradeoffs; the compact loop is far shorter than the eventual 20-30 minute target.
- M1-M4 regression PASS: M1 494 asset/control +18 screenshot checks; M2 2,733 world +33 screenshot checks; M3 280 art/113 battle +52 screenshot checks; M4 33 art/168 management +51 screenshot checks. Historical app-specific behavior is checked through the legacy fixture.
- Fresh isolated source copy without import cache: import/startup and all ten suites PASS (six prior suites plus M5 art/state/flow/balance). Tests/captures use ignored .godot/m5_validation/ save paths; no player slot was written. Logs and timing JSON remain there.

Review fixes included JSON integer normalization/version dispatch, cross-field save chronology/source checks, interrupted legacy-backup protection, retryable result/admission writes, parent-focus/neutral guards, explicit release identification, spent-rest labeling, HUD health/relics, text-safe border ornaments, map grove placement and isolated 2D overview viewports. No remaining observed code/import/asset errors. The previous approval-review usage-limit interruption was resolved on resumption; no work remains blocked by it.

## Remaining limits and manual playtest

Follow README.md: choose each starter; walk both lights and gate on all stages; weaken/capture/switch/use balm; choose different early relics; spend camp rest once; exchange/release/cancel; defeat guardian; bring one living recruit (or none) home; depart again and verify resets. Separately retreat, lose and abandon. Restart during a run and battle, Continue, and check the saved location/encounter. Check keyboard/physical controller feel, held directions, focus loss and native-size text.

- Only three base species, three template layouts, two branch options per stage, six wild lights and one guardian. All three relics are acquired by the guardian, limiting end-build variety. More content, longer pacing, hub unlocks and audio are M6 work; M6 is not started.
- Ordinary walking is not checkpointed every tile. No mid-turn battle resume; interruption replays the saved encounter from its start. Saves assume one game instance; filesystem recovery tests are not physical power-loss or concurrent-writer tests. No cloud sync or tamper-proof guarantee.
- Base supplies usually cannot fill all eight team/reserve slots; full-capacity cases and some screenshots use controlled fixtures. One captured recruit per successful return; released/failed-run captures retain discovery only. Cosmetic seeds persist, but art currently uses base species colors.
- GPU playthrough and virtual input are automated. Human timing/balance, physical controllers/analog menu feel, other GPUs/platforms, exports, remapping and release accessibility need later hands-on work. No growth forms, audio, trainer battles, PP or status conditions.

## Next milestone

M6 roguelite variety/progression/balance/audio is unstarted. A later implementation request may authorize it. Identify the reviewed M5 checkpoint with git log -1; remote origin is github.com/stephenstilwell/monster-game.

## Meta-progression design update (documentation only)

Added [META_PROGRESSION.md](META_PROGRESSION.md) after the user requested concrete lasting goals and reasons to start another run. It defines collection/research/project/mastery rewards, all-outcome retention, three choice-oriented sanctuary projects with provisional costs, growth-form unlocks, six-relic build variety, optional challenge tiers, visible next goals, finite completion and migration/transaction tests. Related design, architecture, roadmap, art and README guidance now link to the same contract.

M5 executable and prior observed test results are unchanged. M6 remains unstarted; no game code/assets were changed or Godot tests rerun for this documentation task. Verified Markdown links, balanced fences and Git whitespace hygiene. Economy values, challenge strength and progression duration are design hypotheses requiring implementation and measured balance; no new gameplay results are claimed.
