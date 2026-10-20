extends SceneTree
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Sim = preload("res://tests/progression/simulator.gd")
var failures := 0
var results: Array = []
func sample(unlocked: bool, starter: int, kit: String, pool: String, tier: int = 0) -> void:
	var wins := 0
	var turns := 0
	var catches := 0
	var balms_left := 0
	var builds: Dictionary = {}
	var marks := 0
	for seed_value in range(16):
		var d := Model.fresh()
		d.profile.roster.append(Model.record("sample_rillume", "rillume"))
		Meta.sync_research(d.profile)
		if unlocked:
			# Explicit balance fixture: unlocked content, never published as a player save.
			d.profile.meta.projects = Meta.PROJECTS.keys()
			for id: String in Meta.BASES: d.profile.meta.study[id] = ["sample_a", "sample_b", "sample_c"]
			d.profile.preparation.loadout = kit
			d.profile.preparation.pool = pool
			d.profile.preparation.tier = tier
			d.profile.completed = 1
			d.profile.meta.tiers = [1] if tier == 2 else []
		Model.depart(d, starter, seed_value)
		var before: int = d.profile.meta.marks
		var sim := Sim.new()
		sim.run(d)
		if not sim.error.is_empty(): failures += 1
		if d.run.outcome == "victory": wins += 1
		turns += sim.commands
		catches += sim.captures
		balms_left += int(d.run.inventory.balm)
		builds[str(d.run.relics)] = true
		Model.settle(d, "")
		marks += int(d.profile.meta.marks) - before
		if Model.depart(d, starter) != "": failures += 1
	results.append({"unlocked": unlocked, "starter": Meta.BASES[starter], "kit": kit, "pool": pool, "tier": tier, "wins": wins, "runs": 16, "commands": turns, "captures": catches, "balms_left": balms_left, "builds": builds.size(), "marks": marks})
	print("M6 SAMPLE: ", JSON.stringify(results.back()))
	if not unlocked and wins == 0: failures += 1
func _initialize() -> void:
	for starter in range(3):
		sample(false, starter, "standard", "mixed")
		for kit: String in Meta.LOADOUTS:
			for pool: String in ["mixed", "focus"]: sample(true, starter, kit, pool)
		for tier in [1, 2]: sample(true, starter, "standard", "mixed", tier)
	DirAccess.make_dir_recursive_absolute("res://.godot/m6_validation")
	var file := FileAccess.open("res://.godot/m6_validation/balance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	print("M6 BALANCE %s: %s configurations, 16 seeds each, %s failures; fixed policy, not human balance" % ["PASS" if failures == 0 else "FAIL", results.size(), failures])
	quit(1 if failures else 0)
