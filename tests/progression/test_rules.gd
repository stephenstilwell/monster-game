extends SceneTree
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Session = preload("res://scripts/progression/expedition_session.gd")
const Resolver = preload("res://scripts/battle/battle_resolver.gd")
const Codec = preload("res://scripts/progression/save_codec.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func battle(relic: String = "", wounded: bool = false) -> RefCounted:
	var d := Model.fresh()
	Model.depart(d, 1, 0)
	Model.choose_route(d, 0)
	Model.prepare(d, 0)
	d.run.pending.species = "brindlewick"
	d.run.pending.level = 5
	if not relic.is_empty(): d.run.relics = [relic]
	var s := Session.new()
	s.configure(d)
	var state := s.begin("brindlewick", 5)
	if wounded: state.party[0].hp = state.party[0].max_hp(s.catalog.species.cindrel) / 2
	return state
func hit(state: RefCounted, side: String) -> int:
	var result := Resolver.new(Model.Catalog.new()).resolve(state, {"kind": "move", "move": "nudge"})
	for event: Dictionary in result.events:
		if event.kind == "hit" and event.side == side: return event.message.split(" ")[-2].to_int()
	return 0
func _initialize() -> void:
	var plain := battle()
	var thorn := battle("thorn")
	check(hit(thorn, "ally") - hit(plain, "ally") == 3, "thorn always adds3")
	var swift := battle("swift")
	plain = battle()
	check(hit(swift, "ally") - hit(plain, "ally") == 6, "feather first turn")
	swift = battle("swift")
	plain = battle()
	swift.turn = 1
	plain.turn = 1
	check(hit(swift, "ally") == hit(plain, "ally"), "feather not later turns")
	var risk := battle("emberglass", true)
	plain = battle("", true)
	check(hit(risk, "ally") - hit(plain, "ally") == 7, "glass rewards injured play")
	risk = battle("emberglass")
	plain = battle()
	check(hit(risk, "ally") == hit(plain, "ally"), "glass no bonus healthy")
	var shell := battle("shell")
	plain = battle()
	check(hit(plain, "foe") - hit(shell, "foe") == 3, "shell guard")
	var charm := battle("charmleaf")
	plain = battle()
	var resolver := Resolver.new(Model.Catalog.new())
	check(is_equal_approx(resolver.capture_chance(charm) - resolver.capture_chance(plain), 0.15), "leaf adds15 percent")
	charm.enemy.hp = 1
	check(resolver.capture_chance(charm) <= 0.95, "capture capped")
	charm.guardian = true
	charm.capture_allowed = false
	var rng_before: int = charm.rng.state
	check(not resolver.resolve(charm, {"kind": "item", "item": "charm"}).valid and charm.rng.state == rng_before and charm.inventory.charm == 4, "guardian rejects before cost RNG")
	# Every template has a distinct, finite choice with exact supply/health consequences.
	for template in range(3):
		var d := Model.fresh()
		Model.depart(d, 0, 0)
		Model.choose_route(d, 0)
		d.run.options[0][int(d.run.choices[0])].template = template
		d.run.party[0].hp = 10
		if template == 2: d.run.inventory.charm = 3
		check(Model.trail_event(d, "sip") == "", "event variant")
		check(d.run.party[0].hp == (18 if template == 0 else 14 if template == 1 else 10), "exact variant heal")
		if template == 2: check(d.run.inventory == {"charm": 5, "balm": 1}, "shrine trade")
		var before := d.duplicate(true)
		check(Model.trail_event(d, "gather") != "" and d == before, "no event farming")
	# Seeded surveys do not reroll the other wild slot or battle stream.
	for seed_value in range(16):
		var d := Model.fresh()
		Model.depart(d, 0, seed_value)
		d.run.stage = 1
		d.run.choices = [0]
		d.run.rules.survey = "rillume"
		d.run.phase = "route"
		Model.choose_route(d, 0)
		Model.prepare(d, 0)
		check(d.run.pending.species == "rillume", "stage2 survey")
	# M6 additions preserve mandatory route connectivity across the M5 seed set.
	var driver := Driver.new()
	for seed_value in range(64):
		var d := Model.fresh()
		Model.depart(d, 0, seed_value)
		for stage in range(3):
			for branch in range(2):
				var r: Dictionary = d.run.duplicate(true)
				r.stage = stage
				r.choices = [branch, branch, branch]
				var map: Resource = Model.map_for(r)
				for id: String in ["event", "encounter_0", "encounter_1", "exit"]:
					check(not driver.path(map, map.start, map.landmarks[id]).is_empty(), "M6 route connected")
	# Corrupt run additions fail validation without property-access errors.
	var clean := Model.fresh()
	Model.depart(clean, 0, 2)
	Model.choose_route(clean, 0)
	for field: String in ["rules", "events", "secured", "marks_start", "source_species"]:
		var bad := clean.duplicate(true)
		bad.run.erase(field)
		check(Codec.decode(bad, {}).has("error"), "missing run field " + field)
	for field: String in ["growth", "relic_pool", "loadout", "survey", "tier", "pool", "guardian_bonus", "camp_fraction", "xp_multiplier"]:
		var bad := clean.duplicate(true)
		bad.run.rules.erase(field)
		check(Codec.decode(bad, {}).has("error"), "missing snapshot " + field)
	print("M6 RULES %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
