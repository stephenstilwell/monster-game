# Agent workflow

- Scope: this project. Read these instructions and inspect Git before editing. Preserve unrelated work.
- The user authorized M4 after M3. M4 is complete; this task stops before M5. A subsequent user instruction may authorize the next milestone. Never expand milestones implicitly.
- Use typed GDScript, snake_case files/functions, PascalCase classes, explicit signals, and composed scenes. Keep definitions separate from mutable state.
- Verified baseline: Godot 4.7.2 stable, Compatibility renderer. Recheck --version before implementation; do not silently upgrade or change rendering settings.
- Complete one milestone at a time, including its artwork, validation, documentation, and Git checkpoint. Do not begin later milestones early.
- Generate all visual assets reproducibly in-project. No user artwork, borrowed franchise designs, or asset packs. Geometric primitives are construction tools, never finished-art acceptance criteria.
- Follow ART_DIRECTION.md. Commit recipes, seeds, manifests, reusable PNGs and resources together. Exclude .godot/ and saves.
- Use independent seeded RNG streams for art, maps, encounters, and battle. Avoid global random state.
- Run tools/validate_m4.ps1 for the current M1-M4 regression; see README.md for the exact command. Use dependency-free headless GDScript tests for meaningful behavior, clean import checks, and rendered screenshot/animation inspection where supported. Never claim unrun checks.
- Update the five companion planning documents as decisions change. Record actual evidence and blockers in PROGRESS.md.
- Review staged diffs and checkpoint only intended changes. Never reset user work or commit secrets/caches. No sub-agent delegation without user authorization.
