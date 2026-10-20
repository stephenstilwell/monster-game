extends SceneTree
const Model = preload("res://scripts/expedition/expedition_service.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")
const Session = preload("res://scripts/expedition/expedition_session.gd")
const Codec = preload("res://scripts/save/expedition_codec.gd")
const Saves = preload("res://scripts/save/save_service.gd")
const Legacy = preload("res://scripts/save/save_codec.gd")
const Resolver = preload("res://scripts/battle/battle_resolver.gd")
var checks: int = 0
var failures: int = 0
var snapshots: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func valid(d: Dictionary, label: String) -> void:
	var result := Codec.decode(JSON.parse_string(JSON.stringify(d)), {})
	check(not result.has("error"), label + " " + result.get("error", ""))
func finish(d: Dictionary, outcome: String = "victory") -> RefCounted:
	var session := Session.new()
	session.configure(d)
	var state: RefCounted = session.begin(d.run.pending.species, int(d.run.pending.level))
	state.outcome = outcome
	if outcome == "capture": state.enemy.hp = 1
	if outcome == "defeat":
		for m: RefCounted in state.party: m.hp = 0
	session.claim(state)
	check(session.apply_to(d, state), "claim applies matching battle")
	var unchanged := d.duplicate(true)
	check(not session.apply_to(d, state) and d == unchanged, "duplicate battle application ignored")
	return session
func write_raw(directory: String, name: String, raw: Dictionary) -> void:
	var payload := JSON.stringify(raw)
	var f := FileAccess.open(directory + "/" + name, FileAccess.WRITE)
	f.store_string(JSON.stringify({"payload": payload, "digest": payload.sha256_text()}))
	f.close()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var signatures: Dictionary = {}
	for seed_value in range(64):
		var plan := Routes.options(seed_value)
		check(plan == Routes.options(seed_value), "seed repeat " + str(seed_value))
		signatures[JSON.stringify(plan.stages)] = true
		for depth in range(3):
			for option: Dictionary in plan.stages[depth]:
				var map: Resource = Routes.build(option, depth)
				var reached := {map.start: true}
				var pending: Array[Vector2i] = [map.start]
				while not pending.is_empty():
					var cell: Vector2i = pending.pop_front()
					for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
						var next := cell + direction
						if not reached.has(next) and map.can_enter(next): reached[next] = true; pending.append(next)
				check(reached.has(map.landmarks.exit) and reached.has(map.landmarks.encounter_0) and reached.has(map.landmarks.encounter_1), "mandatory path connectivity")
				check(map.safe_spawn(map.start) == map.start and map.portal_at(map.landmarks.exit).action == "stage_exit", "spawn and exit")
	check(signatures.size() == 64, "documented 64 seeds vary")
	var d := Model.fresh()
	var home: Array = d.profile.roster.duplicate(true)
	check(Model.depart(d, 0, 91273) == "", "departure")
	check(d.run.party.size() == 1 and d.run.party[0].level == 5 and d.run.party[0].xp == 0 and d.run.inventory == {"charm": 4, "balm": 2}, "normalized starter and bounded supplies")
	check(d.profile.roster == home and d.run.party[0].id != home[0].id, "sanctuary copy isolation")
	valid(d, "departure snapshot")
	snapshots.append(d.duplicate(true))
	var unchanged := d.duplicate(true)
	check(Model.depart(d, 1) != "" and d == unchanged, "one active run")
	var abandoned := d.duplicate(true)
	check(Model.request_end(abandoned, "abandon") == "", "abandon route selection")
	valid(abandoned, "route abandonment snapshot")
	check(Model.settle(abandoned, "") == "" and abandoned.profile.roster == home and abandoned.run.is_empty(), "abandon safe reentry")
	for depth in range(3):
		check(Model.choose_route(d, depth % 2) == "", "choose stage " + str(depth))
		valid(d, "field snapshot")
		if depth == 0: snapshots.append(d.duplicate(true))
		unchanged = d.duplicate(true)
		check(Model.exit_stage(d) != "" and d == unchanged, "cannot skip finite encounters")
		for slot in range(2):
			check(Model.prepare(d, slot) == "", "prepare finite light")
			valid(d, "pre-battle checkpoint")
			if depth == 0 and slot == 0:
				snapshots.append(d.duplicate(true))
				var a := Session.new(); a.configure(d)
				var b := Session.new(); b.configure(Codec.decode(JSON.parse_string(JSON.stringify(d)), {}).data)
				var state_a: RefCounted = a.begin(d.run.pending.species, int(d.run.pending.level))
				var state_b: RefCounted = b.begin(d.run.pending.species, int(d.run.pending.level))
				var rules := Resolver.new(a.catalog)
				var command := {"kind": "move", "move": state_a.party[0].moves[0]}
				check(rules.resolve(state_a, command) == rules.resolve(state_b, command) and state_a.rng.state == state_b.rng.state, "pending encounter resumes deterministic turns")
			finish(d, "capture" if depth == 0 else "flee")
			valid(d, "completed battle checkpoint")
			unchanged = d.duplicate(true)
			check(Model.prepare(d, slot) != "" and d == unchanged, "no repeat encounter farming")
		if depth == 0:
			snapshots.append(d.duplicate(true))
			check(d.profile.roster == home and not d.profile.discovered.is_empty(), "discovery separate from admissions")
			var loss := d.duplicate(true)
			Model.prepare(loss, 0) # already cleared: no mutation
			Model.request_end(loss, "abandon")
			var journal: Array = loss.profile.discovered.duplicate()
			Model.settle(loss, "")
			check(loss.profile.discovered == journal and loss.profile.roster == home, "failure preserves committed discoveries only")
		check(Model.exit_stage(d) == "" and d.run.phase == "reward", "finite stage reward")
		valid(d, "reward checkpoint")
		snapshots.append(d.duplicate(true))
		var offered: String = d.run.offers[0]
		check(Model.relic(d, offered) == "", "choose a temporary relic")
		unchanged = d.duplicate(true)
		check(Model.relic(d, offered) != "" and d == unchanged, "no repeated reward")
		if depth == 1:
			valid(d, "camp snapshot")
			snapshots.append(d.duplicate(true))
			var supplies: Dictionary = d.run.inventory.duplicate()
			d.run.party[0].hp = 0
			check(Model.camp(d, "rest") == "" and d.run.party[0].hp > 0 and d.run.inventory == supplies, "camp revives once without refill")
			unchanged = d.duplicate(true)
			check(Model.camp(d, "rest") != "" and d == unchanged, "camp budget survives reentry")
			var retreat := d.duplicate(true)
			Model.request_end(retreat, "retreat")
			valid(retreat, "retreat checkpoint")
			var eligible := Model.eligible(retreat.run)
			check(eligible.size() == 2, "living captured recruits eligible")
			unchanged = retreat.duplicate(true)
			check(Model.settle(retreat, retreat.run.party[0].id) != "" and retreat == unchanged, "starter cannot be banked")
			check(Model.settle(retreat, eligible[0].id) == "" and retreat.profile.roster.size() == 3 and retreat.profile.completed == 0, "retreat banks one without victory credit")
			unchanged = retreat.duplicate(true)
			check(Model.settle(retreat, "") != "" and retreat == unchanged, "settlement retry cannot duplicate admission")
			valid(retreat, "settled retreat")
			check(Model.camp(d, "continue") == "", "camp continues to stage three")
	# Third reward prepares the uncapturable guardian with an independent saved seed.
	check(d.run.pending.guardian and d.run.relics.size() == 3, "guardian and build prepared")
	valid(d, "guardian checkpoint")
	snapshots.append(d.duplicate(true))
	var guardian_session := Session.new(); guardian_session.configure(d)
	var guardian: RefCounted = guardian_session.begin("brindlewick", 7)
	var rules := Resolver.new(guardian_session.catalog)
	var rng_before: int = guardian.rng.state
	check(not rules.resolve(guardian, {"kind": "flee"}).valid and not rules.resolve(guardian, {"kind": "item", "item": "charm"}).valid and guardian.rng.state == rng_before and guardian.turn == 0, "guardian restrictions before costs/RNG")
	finish(d)
	valid(d, "victory settlement checkpoint")
	snapshots.append(d.duplicate(true))
	var selected: Dictionary = Model.eligible(d.run)[0]
	check(Model.settle(d, selected.id) == "" and d.profile.completed == 1 and d.profile.roster.size() == 3 and d.run.is_empty(), "victory settles once with one recruit")
	check(d.profile.roster[2] == Model.record(selected.id, selected.species, selected.appearance), "admission retains only identity/cosmetics")
	valid(d, "settled victory")
	snapshots.append(d.duplicate(true))
	check(Model.depart(d, 2) == "" and d.run.party[0].level == 5 and d.run.party[0].xp == 0 and d.run.relics.is_empty() and d.run.inventory.balm == 2, "second expedition resets combat growth/build/supplies")
	Model.choose_route(d, 0)
	Model.prepare(d, 0)
	var originals: Array = d.profile.roster.duplicate(true)
	finish(d, "defeat")
	check(d.run.party[0].hp == 0 and d.run.outcome == "defeat", "defeat does not heal and continue expedition")
	valid(d, "defeat settlement checkpoint")
	snapshots.append(d.duplicate(true))
	Model.settle(d, "")
	check(d.profile.roster == originals and d.profile.completed == 1, "defeat leaves sanctuary and prior completion safe")
	# Bounded party/reserve and camp-only exchanges.
	var full := Model.fresh(); Model.depart(full, 0); Model.choose_route(full, 0)
	for serial in range(1, 8):
		full.run.serial = serial
		full.run.claimed.append(serial)
		var m: RefCounted = Model.monster(full.run.party[0]).clone()
		m.id = "run_1_capture_%s" % serial
		(full.run.party if full.run.party.size() < 4 else full.run.reserve).append(Model.member(m))
	Model.prepare(full, 0)
	var full_session := Session.new(); full_session.configure(full)
	var full_state: RefCounted = full_session.begin(full.run.pending.species, int(full.run.pending.level))
	check(not Resolver.new(full_session.catalog).resolve(full_state, {"kind": "item", "item": "charm"}).valid and full_state.inventory.charm == 4 and full_state.turn == 0, "full party/reserve rejects capture without cost")
	full.run.pending.clear()
	unchanged = full.duplicate(true)
	check(Model.field_action(full, "withdraw", 0, 0) != "" and full == unchanged, "reserve inaccessible outside camp")
	full.run.stage = 1; full.run.phase = "camp"
	check(Model.field_action(full, "deposit", 0) == "THE FOUR RESERVE SLOTS ARE FULL.", "reserve capacity enforced")
	var old: String = full.run.party[2].id
	check(Model.field_action(full, "withdraw", 0, 2) == "" and full.run.reserve[0].id == old and full.run.party.size() == 4 and full.run.reserve.size() == 4, "full-party camp swap preserves all identities")
	var size_before: int = full.run.reserve.size()
	check(Model.field_action(full, "release_reserve", 0) == "" and full.run.reserve.size() == size_before - 1, "confirmed camp release creates a free reserve slot")
	check(Model.field_action(full, "release_party", 0) != "", "starter copy cannot be released")
	full.run.phase = "field"
	unchanged = full.duplicate(true)
	check(Model.field_action(full, "release_reserve", 0) != "" and full == unchanged, "release rejected outside camp without mutation")
	# Adversarial decode; malformed data never reaches map generation or mutable state.
	for snapshot: Dictionary in snapshots:
		for field: String in snapshot:
			var bad := snapshot.duplicate(true); bad.erase(field)
			check(Codec.decode(bad, {}).has("error"), "required root field " + field)
		if not snapshot.run.is_empty():
			for field: String in snapshot.run:
				var bad := snapshot.duplicate(true); bad.run[field] = null
				check(Codec.decode(bad, {}).has("error"), "required run field " + field)
	# Relics alter combat and post-battle recovery without introducing extra RNG draws.
	var plain_session := Session.new(); plain_session.configure(snapshots[2])
	var relic_data: Dictionary = snapshots[2].duplicate(true)
	relic_data.run.relics = ["thorn", "shell"]
	var relic_session := Session.new(); relic_session.configure(relic_data)
	var plain: RefCounted = plain_session.begin(snapshots[2].run.pending.species, int(snapshots[2].run.pending.level))
	var boosted: RefCounted = relic_session.begin(relic_data.run.pending.species, int(relic_data.run.pending.level))
	Resolver.new(plain_session.catalog).resolve(plain, {"kind": "move", "move": "nudge"})
	Resolver.new(relic_session.catalog).resolve(boosted, {"kind": "move", "move": "nudge"})
	check(plain.enemy.hp - boosted.enemy.hp == 3 and boosted.party[0].hp - plain.party[0].hp == 3, "thorn and shell change opposing damage by three")
	check(plain.rng.state == boosted.rng.state, "relics preserve battle draw count")
	relic_data.run.relics = ["hearth"]
	var hearth := Session.new(); hearth.configure(relic_data)
	var recovered: RefCounted = hearth.begin(relic_data.run.pending.species, int(relic_data.run.pending.level))
	recovered.party[0].hp = 10
	var fainted: RefCounted = recovered.party[0].clone(); fainted.id = "fixture_fainted"; fainted.hp = 0
	recovered.party.append(fainted)
	recovered.outcome = "victory"
	hearth.claim(recovered)
	check(hearth.party[0].hp == 16 and hearth.party[1].hp == 0, "hearth heals living party without reviving fainted companions")
	check(hearth.claim(recovered).is_empty() and hearth.party[0].hp == 16, "hearth reward is exactly once")
	# Valid shapes with inconsistent cross-field state must still be refused.
	var baseline: Dictionary = snapshots[1]
	for field: String in baseline.profile:
		var bad := baseline.duplicate(true); bad.profile[field] = null
		check(Codec.decode(bad, {}).has("error"), "required profile field " + field)
	for field: String in ["stage", "phase", "serial", "seed", "cell", "facing", "options", "choices", "rewards", "inventory"]:
		for bad_value: Variant in [true, -1, 0.5, "invalid", [], {}]:
			if typeof(bad_value) == typeof(baseline.run[field]) and bad_value == baseline.run[field]: continue
			var bad := baseline.duplicate(true); bad.run[field] = bad_value
			check(Codec.decode(bad, {}).has("error"), "malformed field " + field)
	var forged := baseline.duplicate(true)
	forged.run.options[0][0].seed = "1"
	check(Codec.decode(forged, {}).has("error"), "route plan must match seed")
	forged = baseline.duplicate(true); forged.run.source = "starter_2"
	check(Codec.decode(forged, {}).has("error"), "starter must match source record")
	forged = baseline.duplicate(true); forged.run.phase = "settle"; forged.run.outcome = "victory"
	check(Codec.decode(forged, {}).has("error"), "cannot claim victory before guardian")
	forged = baseline.duplicate(true); forged.run.serial = 1; forged.run.claimed = [1]
	check(Codec.decode(forged, {}).has("error"), "battle ledger must match finite progress")
	forged = baseline.duplicate(true); forged.profile.next_run = 5; forged.run.id = 4
	check(Codec.decode(forged, {}).has("error"), "cannot skip profile run sequence")
	# Actual filesystem layouts at each safe checkpoint and both sides of settlement.
	var base := "res://.godot/m5_validation/state_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(base)
	for i in range(snapshots.size()):
		var path := base + "/phase_%s" % i
		DirAccess.make_dir_recursive_absolute(path)
		var saves := Saves.new(); saves.codec = Codec; saves.directory = path
		var snapshot: Dictionary = snapshots[i]
		check(saves.save_game(snapshot, {}) == "SAVED.", "write validated checkpoint " + str(i))
		check(saves.load_game({}).data == snapshot, "roundtrip entire profile/run")
		write_raw(path, "pending.json", snapshots.back())
		check(saves.load_game({}).data == snapshot, "committed primary wins before rotation")
		DirAccess.rename_absolute(path + "/slot.json", path + "/backup.json")
		check(saves.load_game({}).data == snapshots.back(), "valid pending wins interrupted install")
		var f := FileAccess.open(path + "/pending.json", FileAccess.WRITE); f.store_string("{partial"); f.close()
		check(saves.load_game({}).data == snapshot, "partial pending falls back to known-good backup")
		check(saves.save_game(snapshot, {}) == "SAVED.", "resave after recovery")
		var future := snapshot.duplicate(true); future.version = 4
		write_raw(path, "slot.json", future)
		check(saves.load_game({}).error == "UNSUPPORTED SAVE VERSION." and saves.save_game(snapshot, {}) == "NEWER SAVE PROTECTED.", "future schema protected")
		future.version = 3; future.content = "future"
		write_raw(path, "slot.json", future)
		check(saves.load_game({}).error == "UNSUPPORTED CONTENT VERSION." and saves.save_game(snapshot, {}) == "NEWER SAVE PROTECTED.", "future generator/content protected")
	# v1/v2 migration preserves records and the original file independent of rotation.
	var old_app := preload("res://tests/fixtures/legacy_game.tscn").instantiate()
	root.add_child(old_app)
	var legacy: Dictionary = Legacy.snapshot(old_app)
	for version in [1, 2]:
		legacy.version = version
		var path := base + "/legacy_%s" % version
		DirAccess.make_dir_recursive_absolute(path)
		write_raw(path, "slot.json", legacy)
		var saves := Saves.new(); saves.codec = Codec; saves.directory = path
		var migrated: Dictionary = saves.load_game({}).data
		var invalid_backup := FileAccess.open(path + "/legacy_v2.json", FileAccess.WRITE)
		invalid_backup.store_string("{partial"); invalid_backup.close()
		var original_bytes := FileAccess.get_file_as_bytes(path + "/slot.json")
		check(saves.save_game(migrated, {}) == "LEGACY BACKUP FAILED VALIDATION." and FileAccess.get_file_as_bytes(path + "/slot.json") == original_bytes, "interrupted legacy backup blocks migration without replacing original")
		DirAccess.remove_absolute(path + "/legacy_v2.json")
		check(migrated.profile.roster[0].id == legacy.members[0][0].id and migrated.run.is_empty(), "legacy migration keeps identity and returns hub")
		check(saves.save_game(migrated, {}) == "SAVED." and FileAccess.file_exists(path + "/legacy_v2.json"), "legacy source separately preserved")
		var bytes := FileAccess.get_file_as_bytes(path + "/legacy_v2.json")
		Model.depart(migrated, 0)
		saves.save_game(migrated, {})
		saves.save_game(migrated, {})
		check(FileAccess.get_file_as_bytes(path + "/legacy_v2.json") == bytes, "legacy backup survives later rotations")
	old_app.free()
	print("M5 STATE PASS: %s assertions, %s failures; 64 seeds / 384 generated routes" % [checks, failures])
	quit(1 if failures else 0)