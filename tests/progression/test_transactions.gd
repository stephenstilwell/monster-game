extends SceneTree
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Codec = preload("res://scripts/progression/save_codec.gd")
const Saves = preload("res://scripts/save/save_service.gd")
const Previous = preload("res://scripts/expedition/expedition_service.gd")
const Sim = preload("res://tests/progression/simulator.gd")
var checks := 0
var failures := 0
var root_path := "res://.godot/m6_validation/transactions_" + str(Time.get_ticks_usec())
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func valid(d: Dictionary, label: String) -> void:
	var result := Codec.decode(JSON.parse_string(JSON.stringify(d)), {})
	check(not result.has("error"), label + " " + str(result.get("error", "")))
func envelope(path: String, d: Dictionary) -> void:
	var payload := JSON.stringify(d, "", true)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"payload": payload, "digest": payload.sha256_text()}))
	f.close()
func boundary(before: Dictionary, after: Dictionary, name: String) -> void:
	valid(before, name + " before")
	valid(after, name + " after")
	var arrangements := [ {"slot": before}, {"slot": before, "pending": after}, {"backup": before, "pending": after}, {"backup": before, "slot": after}, {"slot": before, "backup": after} ]
	for index in range(arrangements.size()):
		var saves := Saves.new()
		saves.codec = Codec
		saves.directory = root_path + "/" + name + "_%s" % index
		DirAccess.make_dir_recursive_absolute(saves.directory)
		for id: String in arrangements[index]: envelope(saves.directory + "/" + id + ".json", arrangements[index][id])
		var expected: Dictionary = before if index in [0, 1, 4] else after
		var loaded := saves.load_game({})
		check(not loaded.has("error") and loaded.data == expected, name + " recovery %s" % index)
		check(saves.save_game(expected, {}) == "SAVED.", name + " recovery writable")
		check(saves.load_game({}).data == expected, name + " recovery no duplicate")
func _initialize() -> void:
	var d := Model.fresh()
	Model.depart(d, 1, 0)
	Model.choose_route(d, 0)
	Model.prepare(d, 0)
	var before := d.duplicate(true)
	var sim := Sim.new()
	sim.battle(d)
	boundary(before, d, "battle_research")
	Model.prepare(d, 1)
	sim.battle(d)
	before = d.duplicate(true)
	Model.exit_stage(d)
	boundary(before, d, "stage_mark")
	check(Meta.buy(d, "trail") != "", "no midrun purchase")
	check(Model.exit_stage(d) != "", "reward phase cannot grant another mark")
	check(Model.relic(d, "skip") == "" and d.run.rewards == [0] and d.run.relics.is_empty(), "declining still progresses")
	valid(d, "declined reward saved")
	Model.request_end(d, "abandon")
	before = d.duplicate(true)
	Model.settle(d, "")
	boundary(before, d, "abandon_settlement")
	# Accrue an actual played profile for project and mastery boundaries.
	for index in range(6):
		Model.depart(d, 1, index)
		sim = Sim.new()
		sim.run(d)
		before = d.duplicate(true)
		Model.settle(d, "")
		if index == 0: boundary(before, d, "victory_settlement")
	check(d.profile.meta.marks >= 15, "projects reachable through play")
	for id: String in Meta.PROJECTS:
		before = d.duplicate(true)
		var balance: int = d.profile.meta.marks
		check(Meta.buy(d, id) == "", "purchase " + id)
		boundary(before, d, "purchase_" + id)
		check(Meta.buy(d, id) != "" and d.profile.meta.marks == balance - Meta.PROJECTS[id].cost, "purchase cannot repeat")
	check(Meta.prepare(d.profile, "loadout", "catcher") == "", "catcher unlocked")
	check(Meta.prepare(d.profile, "survey", "rillume") == "", "survey unlocked")
	check(Meta.prepare(d.profile, "pool", "focus") == "", "focus unlocked")
	check(Meta.prepare(d.profile, "tier", 1) == "", "normal victory unlocks tier1")
	Model.depart(d, 1, 1)
	var snapshot: Dictionary = d.run.rules.duplicate(true)
	check(d.run.inventory == {"charm": 5, "balm": 1} and snapshot.guardian_bonus == 4, "loadout and challenge copied")
	sim = Sim.new()
	sim.run(d)
	valid(d, "unlocked challenge run")
	Model.settle(d, "")
	for tier in [1, 2]:
		var won := false
		for seed_value in range(16):
			check(Meta.prepare(d.profile, "tier", tier) == "", "tier prerequisite satisfied")
			Model.depart(d, 1, seed_value)
			sim = Sim.new()
			sim.run(d)
			valid(d, "challenge terminal")
			won = d.run.outcome == "victory"
			Model.settle(d, "")
			valid(d, "challenge settlement")
			if won: break
		check(won and tier in d.profile.meta.tiers, "real challenge victory grants pennant")
		if not won: break
	# An actual focused expedition reaches a researched form before guardian combat.
	var natural := Model.fresh()
	Model.depart(natural, 1, 0)
	for index in range(1, 4): Meta.battle(natural, "victory", "cindrel", false, index)
	Model.request_end(natural, "abandon")
	Model.settle(natural, "")
	Model.depart(natural, 1, 0)
	sim = Sim.new()
	var saw_growth := false
	for stage in range(3):
		Model.choose_route(natural, 0)
		for slot in range(2):
			Model.prepare(natural, slot)
			sim.battle(natural, false)
			if natural.run.party[0].species == "pyrelace": saw_growth = true
			if natural.run.phase == "settle": break
		if natural.run.phase == "settle": break
		Model.exit_stage(natural)
		var offers: Array = natural.run.offers
		Model.relic(natural, "hearth" if "hearth" in offers else "shell" if "shell" in offers else offers[0])
		if stage == 1: Model.camp(natural, "rest"); Model.camp(natural, "continue")
	check(saw_growth, "natural XP reaches growth before guardian")
	# A controlled healthy candidate checks exact growth checkpoint serialization.
	var grow := Model.fresh()
	Model.depart(grow, 0, 0)
	grow.profile.meta.study.brindlewick = ["run_1/battle_1", "run_1/battle_2", "run_1/battle_3"]
	Meta.sync_research(grow.profile)
	grow.run.rules.growth = ["brindlewick"]
	Model.choose_route(grow, 0)
	grow.run.party[0].level = 7
	grow.run.party[0].hp = 52
	Model.prepare(grow, 0)
	var session := preload("res://scripts/progression/expedition_session.gd").new()
	session.configure(grow)
	var battle := session.begin(grow.run.pending.species, int(grow.run.pending.level))
	battle.outcome = "victory"
	battle.enemy.hp = 0
	session.claim(battle)
	check(session.party[0].species_id == "briarwarden", "level7 researched grows")
	check(session.apply_to(grow, battle), "growth checkpoint")
	valid(grow, "growth saves")
	check(not session.apply_to(grow, battle), "stale result blocked")
	# Tier2 heals to half, never lowers current HP, and cannot refill items.
	var camp := Model.fresh()
	Model.depart(camp, 0, 0)
	camp.run.phase = "camp"
	camp.run.rules.camp_fraction = 0.5
	camp.run.party[0].hp = 0
	var bag: Dictionary = camp.run.inventory.duplicate()
	check(Model.camp(camp, "rest") == "" and camp.run.party[0].hp == 22 and camp.run.inventory == bag, "half rest revives without refill")
	check(Model.camp(camp, "rest") != "", "half rest once")
	# Old active saves preserve independent original envelope through later rotations.
	var old := Previous.fresh()
	Previous.depart(old, 0, 5)
	var saves := Saves.new()
	saves.codec = Codec
	saves.directory = root_path + "/migration"
	DirAccess.make_dir_recursive_absolute(saves.directory)
	envelope(saves.directory + "/slot.json", old)
	var original := FileAccess.get_file_as_bytes(saves.directory + "/slot.json")
	var migrated := saves.load_game({})
	check(saves.save_game(migrated.data, {}) == "SAVED.", "migrate v3")
	check(FileAccess.get_file_as_bytes(saves.directory + "/legacy_v3.json") == original, "original source preserved")
	check(saves.save_game(migrated.data, {}) == "SAVED." and FileAccess.get_file_as_bytes(saves.directory + "/legacy_v3.json") == original, "source survives rotation")
	var bad: Dictionary = migrated.data.duplicate(true)
	bad.version = 100
	envelope(saves.directory + "/slot.json", bad)
	check(saves.load_game({}).error == "UNSUPPORTED SAVE VERSION." and saves.save_game(migrated.data, {}) == "NEWER SAVE PROTECTED.", "unsupported primary blocks overwrite")
	print("M6 TRANSACTION %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
