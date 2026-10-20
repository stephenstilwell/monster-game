extends SceneTree
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Codec = preload("res://scripts/progression/save_codec.gd")
const Previous = preload("res://scripts/expedition/expedition_service.gd")
const Saves = preload("res://scripts/save/save_service.gd")
const Sim = preload("res://tests/progression/simulator.gd")
var checks := 0
var failures := 0
func check(value: bool, title: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: ", title)
func valid(d: Dictionary, title: String) -> void:
	var decoded := Codec.decode(JSON.parse_string(JSON.stringify(d)), {})
	check(not decoded.has("error"), title + " " + str(decoded.get("error", "")))
func _initialize() -> void:
	var d := Model.fresh()
	check(d.profile.meta.marks == 2, "two initial shelter objectives")
	valid(d, "fresh roundtrip")
	var original: Array = d.profile.roster.duplicate(true)
	check(Meta.buy(d, "trail") != "", "cannot overspend")
	check(Meta.prepare(d.profile, "loadout", "catcher") != "", "locked loadout")
	check(Meta.prepare(d.profile, "tier", 1) != "", "locked challenge")
	for seed_value in range(16):
		for starter in range(3):
			d = Model.fresh()
			d.profile.roster.append(Model.record("test_rillume", "rillume"))
			Meta.sync_research(d.profile)
			check(Model.depart(d, starter, seed_value) == "", "free departure")
			var snapshot: Dictionary = d.run.rules.duplicate(true)
			var sim := Sim.new()
			sim.run(d)
			check(sim.error.is_empty(), "valid resolver commands")
			for state: Dictionary in sim.stage_snapshots: valid(state, "checkpoint")
			valid(d, "terminal")
			var earned: int = d.profile.meta.marks
			var roster: Array = d.profile.roster.duplicate(true)
			check(Model.settle(d, "") == "", "settles")
			valid(d, "settled")
			check(d.profile.roster == roster, "originals untouched")
			check(Model.settle(d, "") != "" and d.profile.meta.marks >= earned, "exactly once")
			check(snapshot.growth.is_empty(), "growth initially locked")
	# Backfill uses explicit records, not completion guesses; active legacy continues unchanged.
	var old := Previous.fresh()
	Previous.depart(old, 0, 3)
	Previous.choose_route(old, 0)
	Previous.prepare(old, 0)
	var migration := Codec.decode(JSON.parse_string(JSON.stringify(old)), {})
	check(not migration.has("error"), "v3 active migrates")
	var migrated: Dictionary = migration.data
	check(migrated.run.pending == old.run.pending and migrated.run.streams == old.run.streams, "no reroll on migration")
	check(migrated.profile.meta.study.brindlewick.is_empty() and migrated.profile.meta.medals.is_empty(), "no inferred wins")
	valid(migrated, "migrated v4")
	check(Codec.decode(migrated, {}).data == migrated, "backfill once")
	# Distinct active winner research, capture/guardian excluded; unlock applies next departure only.
	d = Model.fresh()
	Model.depart(d, 0, 1)
	for serial in range(1, 4): Meta.battle(d, "victory", "brindlewick", false, serial)
	check(d.profile.meta.study.brindlewick.size() == 3 and "brindlewick" in Meta.growth(d.profile), "growth research")
	Meta.battle(d, "victory", "brindlewick", false, 1)
	Meta.battle(d, "capture", "cindrel", false, 4)
	Meta.battle(d, "victory", "cindrel", true, 7)
	check(d.profile.meta.study.brindlewick.size() == 3 and d.profile.meta.study.cindrel.is_empty(), "study uniqueness and outcome guards")
	check(d.run.rules.growth.is_empty(), "midrun unlock leaves snapshot unchanged")
	# Finite event is a sidegrade and camp-only recovery stays bounded.
	Model.choose_route(d, 0)
	check(Model.trail_event(d, "gather") == "" and d.run.inventory == {"charm": 3, "balm": 3}, "trade resources")
	check(Model.trail_event(d, "sip") != "", "event once")
	# All return outcomes retain committed progress but only successful returns admit a recruit.
	for outcome in ["abandon", "defeat", "retreat", "victory"]:
		d = Model.fresh()
		Model.depart(d, 0, 0)
		var sim := Sim.new()
		if outcome == "abandon": Model.request_end(d, "abandon")
		else:
			sim.run(d, outcome == "retreat")
			if outcome == "defeat" and d.run.outcome != "defeat":
				# Explicit all-KO terminal candidate for settlement boundary coverage.
				for m: Dictionary in d.run.party: m.hp = 0
				d.run.outcome = "defeat"
			if outcome == "victory": check(d.run.outcome == "victory", "known seed wins")
		var marks: int = d.profile.meta.marks
		check(Model.settle(d, "bad_id") != "", "reject ineligible recruit")
		check(Model.settle(d, "") == "", "all outcomes return")
		check(d.profile.roster == original and d.profile.meta.marks >= marks, "retain originals and marks")
	# Corruption is rejected without script errors.
	d = Model.fresh()
	for field: String in ["marks", "projects", "grants", "study", "medals", "tiers", "pin"]:
		var bad := d.duplicate(true)
		bad.profile.meta.erase(field)
		check(Codec.decode(bad, {}).has("error"), "missing meta " + field)
	var bad := d.duplicate(true)
	bad.profile.meta.marks += 1
	check(Codec.decode(bad, {}).has("error"), "unearned currency")
	var saves := Saves.new()
	saves.codec = Codec
	saves.directory = "res://.godot/m6_validation/state_" + str(Time.get_ticks_usec())
	check(saves.save_game(d, {}) == "SAVED.", "profile write")
	check(saves.load_game({}).data == d, "profile reload")
	print("M6 STATE %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
