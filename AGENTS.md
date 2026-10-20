# Agent workflow

- Scope: this project. Read these instructions and inspect Git before editing. Preserve unrelated work.
- Direction: Lanternwild is a sanctuary-based monster-collecting roguelite; GAME_DESIGN.md is the design contract. The user authorized M5 implementation after the documentation pivot. Finish and validate M5 only; stop before M6. A subsequent implementation request may authorize the next incomplete milestone in ROADMAP.md. Never expand milestones implicitly.
- Use typed GDScript, snake_case files/functions, PascalCase classes, explicit signals, and composed scenes. Keep definitions separate from mutable state.
- Verified baseline: Godot 4.7.2 stable, Compatibility renderer. Recheck --version before implementation; do not silently upgrade or change rendering settings.
- Complete one milestone at a time, including its artwork, validation, documentation, and Git checkpoint. Do not begin later milestones early.
- Generate all visual assets reproducibly in-project. No user artwork, borrowed franchise designs, or asset packs. Geometric primitives are construction tools, never finished-art acceptance criteria.
- Follow ART_DIRECTION.md. Commit recipes, seeds, manifests, reusable PNGs and resources together. Exclude .godot/ and saves.
- Use independent seeded RNG streams for art, maps, encounters, battle and rewards. Avoid global random state; preserve deterministic Continue behavior and generator/content versions.
- Keep permanent sanctuary/profile state separate from disposable expedition state. Never mutate sanctuary originals during combat, bank temporary levels/items, bypass camp limits or award a run outcome twice. Implement migration and interrupted-settlement tests before claiming roguelite persistence works.
- Mark target behavior separately from the current executable. Historical tests using tests/fixtures/legacy_game.tscn establish foundation behavior only; tests/expedition/ must validate the default app. For documentation-only work, check Markdown consistency/diffs; do not claim gameplay validation was rerun.
- Run tools/validate_m5.ps1 for current M1-M5 validation; see README.md for the exact command. Use dependency-free headless GDScript tests for meaningful behavior, clean import checks, and rendered screenshot/animation inspection where supported. Never claim unrun checks.
- Update the five companion planning documents as decisions change. Record actual evidence and blockers in PROGRESS.md.
- Review staged diffs and checkpoint only intended changes. Never reset user work or commit secrets/caches. No sub-agent delegation without user authorization.
