# Agent workflow

- Scope: this project. Read these instructions and inspect Git before editing. Preserve unrelated work.
- Current authorization is documentation and planning only. Stop for roadmap review before M1 implementation.
- Use typed GDScript, snake_case files/functions, PascalCase classes, explicit signals, and composed scenes. Keep definitions separate from mutable state.
- Verify Godot with --version before implementation; project.godot currently declares 4.7. Do not silently upgrade or change the renderer.
- Complete one milestone at a time, including its artwork, validation, documentation, and Git checkpoint. Do not begin later milestones early.
- Generate all visual assets reproducibly in-project. No user artwork, borrowed franchise designs, or asset packs. Geometric primitives are construction tools, never finished-art acceptance criteria.
- Follow ART_DIRECTION.md. Commit recipes, seeds, manifests, reusable PNGs and resources together. Exclude .godot/ and saves.
- Use independent seeded RNG streams for art, maps, encounters, and battle. Avoid global random state.
- Use dependency-free headless GDScript tests for meaningful behavior, clean import checks, and rendered screenshot/animation inspection where supported. Never claim unrun checks.
- Update the five companion planning documents as decisions change. Record actual evidence and blockers in PROGRESS.md.
- Review staged diffs and checkpoint only intended changes. Never reset user work or commit secrets/caches. No sub-agent delegation without user authorization.
