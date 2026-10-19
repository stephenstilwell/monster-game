# Art direction — proposed

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

No antialiasing, smooth gradients or arbitrary palette additions. Variants swap named ramps and bounded markings while preserving contrast. Species remain distinguishable in monochrome; state uses icons/text as well as color.

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
