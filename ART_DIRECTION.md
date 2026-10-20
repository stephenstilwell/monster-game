# Art direction

## Implementation boundary

The visual baseline is a sanctuary-based woodland roguelite. M1-M6 assets and the user-requested environment polish below are generated and reusable. M7 accessibility/export work remains planned. Keep the established resolution, palette, original creature designs and reproducible pipeline.

## Identity

Lantern-lit woodland storybook pixel art: rounded foliage, weathered timber, mossy stone, warm cloth and small luminous details. Strong silhouettes, intentional clusters, upper-left light, dark colored outlines and two or three shade steps. Avoid noisy texture and generic geometric stand-ins.

## Resolution

320x180 logical viewport; integer scaling and letterboxing; nearest filtering and pixel-aligned world rendering. Terrain 16x16. Actors 16x24, foot anchor (8,23). Battle creatures 48x48, baseline y=43. Trees 32x48 or 48x64 with base-only collision. UI spacing 8 px. Generate a 5x7 bitmap glyph set on an 8 px line height, covering game English text, punctuation and fallback glyphs. Check readability at native size.

## Shared palette

16 opaque sRGB colors plus transparency:

| Role | Hex colors |
|---|---|
| Ink and deep shade | #20283D, #344052 |
| Neutral shade and paper | #647577, #EDF0D5 |
| Forest | #294F46, #47785A, #80A568 |
| Earth and wood | #6B493F, #A16C4D, #CCA878 |
| Brook | #365C83, #66A6B4 |
| Lantern | #D99145, #F4D47E |
| Cloth and bloom | #975779, #D58C93 |

The font atlas is a white/transparent coverage mask; text is tinted to this palette at draw time. All six rendered views pass exact 16-color membership tests. No antialiasing, smooth gradients or arbitrary palette additions. Variants swap named ramps and bounded markings while preserving contrast. Species remain distinguishable in monochrome; state uses icons/text as well as color.

## Deterministic construction

GDScript Image RGBA8 generators use integer masks, scanline fills, cluster stamps, outline extraction and highlight masks. Build original layered recipes at final resolution. Local seeded RNG chooses bounded decorative details; explicit silhouettes and materials provide intentional art direction. No external image service or user artwork is required.

Render shared skeleton/anchor frames; pack deterministic atlases; save PNGs and a sorted manifest under assets/generated/. After import, assemble SpriteFrames, TileSet, bitmap font and UI resources. Exclude timestamps and machine paths from reproducibility hashes. Compare two clean staging builds. Commit outputs with recipes and seeds.

## M1 required assets

- Player: short-coated trail keeper, satchel, amber lantern clasp. Four facings, four walk frames each at 8 fps, one idle per facing. Explicitly draw asymmetric details rather than blindly mirror them.
- Brindlewick: original squat six-footed creature with layered bark mantle, fan-shaped fern feelers and warm throat light. 48x48 normal and cool-moss variants; four idle frames at 4 fps and four reaction frames at 10 fps. Review silhouette originality before accepting.
- Terrain: grass, dirt path, tall grass, shallow water, banks and all edges/corners used by the vignette. At least two variants for broad surfaces. Tree, rock, flowers, fence and small waystation facade with readable door.
- UI: panel borders, cursor, health bars, affinity/status icons, dialogue indicator and bitmap font. Representative dialogue, four-choice battle command panel and party summary share one theme, shown separately if needed to prevent crowding.
- Sample effects: lantern pulse, leaf impact and charm ring with reduced-flashing preview. These are animation samples, not battle/capture implementation.

## Acceptance

Inspect native and 3x nearest-scaled screenshots, atlas contact sheets and actual animation playback. Check readable silhouettes, consistent shading, terrain seams, stable foot anchors, frame bounds, transparency, long-label clipping and visible traversal affordances. Hashes cannot establish art quality. Revise until these pass; temporary geometry does not qualify as complete artwork.

## M1 evidence

Recipes and all outputs are saved under tools/art/ and assets/generated/. The default application icon is replaced by an original generated lantern emblem. artifacts/visual/ contains six native/3x views, atlas contact sheets and animation_playback sheets. Playback-sheet left rows show south/north/west/east walk samples; right rows show amber/moss idle and amber/moss reactions. Bottom rows show lantern, leaf and charm effects sampled from rendered views. Native and enlarged evidence was inspected; no unresolved frame clipping, terrain seams or text overflow was observed. The subsequent M2 instruction authorized using this visual baseline for exploration.

## M2 artwork and composition

assets/generated/m2/ contains Mara and Ivo at 80x96 each (four facings, one idle plus four walk frames per facing), a 96x48 prop atlas and a 32x16 bridge atlas. Mara has a fern hood/green coat and satchel; Ivo has silver hair/beard and a timber apron. Both retain the shared actor anchor and 8 fps walks. NPCs stand and turn for conversation; walking art is saved for reuse.

New props: carved trail sign, hanging lantern post, ringed mossy stump and shore reeds. Two bridge lanes connect the forest banks. Existing houses, trees, flowers and fences compose the maps. Tall objects sort by their bases; their collision footprints preserve required routes. Foliage bounds the maps; lanterns frame the town gate.

artifacts/visual/m2/ contains eight native/3x views, two native/2x full-map overviews and a native/3x NPC/prop sheet (22 PNGs). All 11 stable images pass exact palette and integer-scale checks. Inspected views cover both maps/NPC dialogues, mid-step presentation, bridge, old waystation and town return. A river-overlapping border tree was removed during review.

## M3 battle art

Three 384x96 atlases contain 48x48 front/back poses, each with four idle frames at 4 fps and four reaction frames at 10 fps. Brindlewick retains its original front recipe and gains a bark-plate back. Cindrel is a ceramic lantern moth with rose wings and ember-tipped antennae; Rillume is a low brook creature with reed gills and a pebble sail. Battle uses base species colors; M1's moss variant remains in its showcase.

An 80x16 icon strip provides three creature portraits, a lantern charm and balm jar. A 192x96 sheet holds four-frame impact, leaf, ember, brook, charm and healing effects at 8 fps. The 320x106 arena reuses the established detailed trees and adds grass and worn ground platforms. All assets use the shared palette and integer pixels, with no downloaded artwork.

Battle menus use the existing panel/font, solid-backed hints, two-column commands and event-synchronized health bars. Player backs and enemy fronts stay clear of status panels. artifacts/visual/m3/ contains 16 native/3x interface/result/world views and native/3x art sheets (34 PNGs). All 17 stable images pass exact palette/dimension/scaling checks; front/back cycles, menus, effects, capture, storage overflow and return scenes were inspected.

## M4 management artwork

management_recipes.gd (m4.1, shared baseline seed 842031) constructs three deterministic atlases: portraits 144x48 (three framed 48x48 species cards), items 48x24 (24x24 braided amber charm and stoppered herbal flask), menu_states 144x20 (48x20 normal/focused/unavailable tabs). Layered woodland portraits reuse original creature recipes, adding timber frames, fern-green backgrounds and amber corner fittings. Item material highlights and leaf labels remain readable at native size. All eight named regions carry rectangles/anchors in the sorted digest manifest; PNGs are reusable and baked.

The full-screen field journal uses the shared panel/font, amber/green focus, four-row paginated lists and persistent controls. Balm target selection displays the selected partner portrait. Town-only rest has an unavailable tab outside town. Generated state art supports focus; error/confirmation text also communicates state without relying solely on color.

artifacts/visual/m4/ contains 17 native/3x interface/world views and a contact sheet (35 PNGs). Views cover all species portraits, party actions, second-page storage/exchange, both items, balm target/use, rest, settings, save, confirmed load and world return. Exact palette/dimension/nearest-scale tests pass. Native/enlarged render inspection found and corrected the target screen's misleading charm icon; no unresolved clipping was observed.

## Implemented M5 roguelite presentation

Preserve warm sanctuary scenes and readable top-down expedition maps. Reuse original terrain/actors/creatures; build deliberate authored room templates with seeded prop clusters and route assembly. Variation must retain readable paths, object footprints, anchors and material shading. Recolored squares or generic random noise are not finished room artwork.

Generated additions follow these requirements, with recipes, seed/version metadata, named regions and palette/anchor tests:

- Sanctuary identity: lantern gate/departure marker, creature resting enclosure and journal/roster accents. Reuse the existing town/NPC composition, adding original fittings rather than a second unrelated art style.
- Forest stage/template variants, branching route markers, a distinct camp lantern/rest fixture and guardian landmark. Route signs must communicate depth, risk and camp/guardian destinations through symbols and labels as well as color.
- Guardian treatment for an existing species: original crest/markings, battle entrance/reaction effect and readable guardian icon. It is an encounter variant, not an unplanned additional species. Distinguish it from a catchable wild creature without relying on a large geometric overlay.
- Three lantern relic icons at 16x16 or 24x24, reward-selection states, a once-used camp indicator and bounded reserve/party labels. Distinguish supplies, temporary relics, journal discoveries and permanent sanctuary membership.
- Starter selection, compact expedition depth/supply/relic HUD, route choice, journal, camp, checkpoint status and victory/retreat/defeat/abandonment settlement interfaces. Show eligible recruit portraits, the no-recruit option and what persists/resets before confirming return or abandonment.

All screens use the existing bitmap font/nine-slice Theme and stay within 320x180. Do not stack route, journal and battle details into one crowded view. Retain keyboard/gamepad focus/back hints and support empty/full reserve, no eligible recruit, spent camp budget and checkpoint-write failure states.

M5 outputs under assets/generated/m5/: props 240x48; relics 72x24; guardian 384x48; entry effects 192x32; four outcome emblems 128x32; journal border 320x180. Thirteen named regions and three animation records use recipe/content version m5.1 and art seed 842031. A reusable SpriteFrames resource contains four idle frames at 4 fps, four reactions at 10 fps and four entry-effect frames at 8 fps. Three baked .tres template maps demonstrate the runtime layouts. Generation/assembly remain reproducible; all artwork is original integer-pixel construction using the established palette.

artifacts/visual/m5/ contains 31 native/3x interface/world views, three native/2x map overviews, native/3x art sheets and an interface contact sheet (71 PNGs, plus views.json). Inspected sanctuary, route choices, river/ridge/road composition, cleared fern markers, camp fresh/spent, party/reserve/exchange, companion-specific release confirmation, crowned guardian/reactions, recruit portraits, all outcomes and resumed expedition. Border ornaments were moved away from text; tree clusters/stumps/reeds reduce empty terrain while preserving paths. Screenshot tests pass 175 assertions; deterministic art tests pass 111. Prior milestone screenshots remain historical evidence.

## M6 scope and future M7 presentation

M6 adds creature growth forms, more authored habitat/event variants, relic/hub upgrade art and original procedural audio with retained generation sources. Permanent unlock presentation emphasizes new options; expedition growth forms do not imply permanent starting power. M7 checks accessibility, motion/flash/text options, physical input prompts and exported presentation at supported scales. M6 delivery is recorded below; do not begin M7 during M6.

## Implemented M6 progression presentation

[META_PROGRESSION.md](META_PROGRESSION.md) adds generated art requirements for three visible one-tier sanctuary projects (Trail Desk, Packing Bench, Lantern Workshop), Research Mark and project icons, research stamps, starter medals/challenge pennants and three additional relics. Growth art remains the three forms already assigned to M6; no additional base species or biome is implied. Use the established 16-color palette, 320x180 layouts and reusable baked resources. Inspect unpaid/available/completed project states, goals and result summaries at native size. The subsequent authorized M6 implementation generated these assets; all sources and reusable outputs are in-project.

M6 outputs: eight raster atlases (three 384x96 growth sheets, 432x48 fixture states, 240x32 research/mastery tokens, 192x32 trail stops, 144x24 relics, 72x24 resting companions), 31 named regions and 12 animation records, three SpriteFrames resources, plus nine original 22,050-Hz mono 16-bit WAVs. Growth silhouettes add a moss mantle/branch crown, scalloped ember wings, and brook-ray ribbons; all have four front/back idle frames at 4 fps and four reactions at 10 fps. One seed/versioned recipe (842031 / m6.1) reproduces pixels and PCM. Three eight-second musical phrases accompany sanctuary, trail and battle; six envelope-shaped effects cover input, hits, capture, growth, victory and defeat.

Fixtures distinguish unavailable, affordable and built states with shape/lighting/check marks; three affinity medals and two numbered pennants are distinct. World companions use 24x24 resting art to fit the enclosure. Project benches occupy cleared ground with collision rather than overlapping border trees. Existing bitmap panels retain four-row pagination; results show recruit, total earned marks, stage/bonus breakdown and research separately. Native/3x UI and native/2x full maps are captured under artifacts/visual/m6/. Human audio mix and physical-device feel remain manual review items.

## Post-M6 scenery polish (2026-10-20)

The user requested more varied houses/trees and subtle ground/foliage animation. tools/art/environment_recipes.gd (environment.1, seed 20261020) generates four reusable atlases under assets/generated/environment/: trees 192x384, houses 256x64, flowers 96x64 and ground cover 64x16. Eighteen named regions preserve the original anchors: trees (24,60), houses (32,61), flowers (12,14); ground uses (8,15). No new colors or filtered transforms.

Six tree silhouettes: rounded broadleaf, pale birch, layered fir, hanging willow, copper-leaf crown and branching sapling. Four original facades vary roof shape/material, dormers/chimneys, shutters, ivy, window boxes and stored timber; the two existing town buildings use distinct lodge/hip-roof designs. Four flower varieties and sparse fern/clover/mushroom/leaf-litter clumps break up grass. Ground dressing excludes paths, water, landmarks, NPCs and existing prop bounds.

Trees and flowers have four baked poses. Wind moves only selected upper foliage or flower tips by one pixel, with fixed roots/trunks and unchanged footprints. A twelve-step resting cycle uses 0.6-second tree steps (7.2-second loop) and 0.8-second flower steps (9.6-second loop); coordinate-derived phases avoid synchronized movement. Hidden worlds pause local animation. No flickering light, screen distortion, global random state or runtime raster generation.

artifacts/visual/environment/ contains before/after town overviews, three route overviews, the actual game viewport, complete asset/animation contact sheets and eight rendered wind samples (24 PNGs). Native/enlarged views and distinct rendered poses were inspected. validate_environment.ps1 checks reproducible pixels/metadata, palette/alpha, frame bounds, pinned roots, stable selection, collision/data isolation, actual idle processing, exact scaling and a clean import. M7 has not started.

## Post-M6 audio replacement

The current executable supersedes the historical eight-second mono score described above with five original sixteen-bar stereo compositions and eight effects. [AUDIO_DIRECTION.md](AUDIO_DIRECTION.md) defines instruments, arrangements, mixing and reproduction. Audio recipes live separately under tools/audio/; the old M6 art/audio fixtures remain reproducible. No visual palette, save/content version or milestone scope changes.