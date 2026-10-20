extends SceneTree
const Session = preload("res://scripts/core/run_session.gd")
const Rules = preload("res://scripts/battle/battle_resolver.gd")
const Monster = preload("res://scripts/monsters/monster_state.gd")
const Encounters = preload("res://scripts/world/encounter_controller.gd")
const App = preload("res://tests/fixtures/legacy_game.tscn")
var checks: int = 0
var failed: bool = false
var content: RefCounted
var rules: RefCounted
func verify(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func fresh(seed_value: int = 51, species: String = "rillume") -> RefCounted:
	var session := Session.new()
	var state: RefCounted = session.begin(species, 3)
	state.rng.seed = seed_value
	return state
func snapshot(state: RefCounted) -> String:
	var hp: Array = []
	for mon: RefCounted in state.party: hp.append([mon.id, mon.hp, mon.level, mon.experience])
	return JSON.stringify([state.turn, state.active, state.enemy.hp, hp, state.inventory, state.rng.state, state.outcome])
func run() -> void:
	var session := Session.new()
	content = session.catalog
	rules = Rules.new(content)
	test_rules()
	test_outcomes()
	test_encounters()
	await test_game_flow()
	print("M3 BATTLE %s: %s assertions for rules, ordering, items, capture/storage, rewards, encounters, UI and world round trips" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
func test_rules() -> void:
	verify(content.species.size() == 3 and content.moves.size() == 5 and content.items.size() == 2, "Complete content")
	for species: Resource in content.species.values():
		for move: String in species.moves: verify(content.moves.has(move), "Move IDs resolve")
	verify(Rules.affinity_multiplier("grove", "brook") == 1.5 and Rules.affinity_multiplier("grove", "ember") == 0.75 and Rules.affinity_multiplier("plain", "grove") == 1.0, "Affinity cycle")
	for command: Dictionary in [{}, {"kind": 4}, {"kind": "move", "move": "missing"}, {"kind": "item", "item": "missing"}, {"kind": "switch", "index": 0}, {"kind": "switch", "index": -1}, {"kind": "switch", "index": "bad"}, {"kind": "dance"}, {"kind": "item", "item": "balm"}]:
		var state := fresh()
		var before := snapshot(state)
		verify(not rules.resolve(state, command).valid and snapshot(state) == before, "Invalid command preserves turn/items/HP/RNG")
	var state := fresh()
	state.inventory.charm = 0
	verify(not rules.resolve(state, {"kind": "item", "item": "charm"}).valid, "Empty charm rejected")
	state.party[1].hp = 0
	verify(not rules.resolve(state, {"kind": "switch", "index": 1}).valid, "Fainted switch rejected")
	state = fresh()
	state.party[0].hp = 1
	var result: Dictionary = rules.resolve(state, {"kind": "item", "item": "balm"})
	verify(result.valid and result.events[0].kind == "heal" and result.events[0].hp == 25 and state.inventory.balm == 5, "Balm priority/heal/cost")
	state = fresh()
	var old_hp: int = state.party[0].hp
	result = rules.resolve(state, {"kind": "switch", "index": 1})
	verify(result.events[0].kind == "switch" and state.active == 1 and state.party[0].hp == old_hp and state.party[1].hp < state.party[1].max_hp(content.species.cindrel), "Switch precedes foe and retargets attack")
	state = fresh()
	state.party[0].hp = 0
	var random_state: int = state.rng.state
	result = rules.resolve(state, {"kind": "switch", "index": 1})
	verify(result.valid and result.events.size() == 1 and state.turn == 0 and state.rng.state == random_state, "Forced replacement is free and has no enemy attack")
	state = fresh(71, "cindrel")
	state.enemy.level = 15
	state.enemy.hp = state.enemy.max_hp(content.species.cindrel)
	state.enemy.moves.assign(["nudge"])
	result = rules.resolve(state, {"kind": "move", "move": "nudge"})
	verify(result.events[0].side == "foe", "Speed determines equal-priority order")
	state = fresh(71, "cindrel")
	state.party[0].moves.assign(["quickstep"])
	state.enemy.level = 15
	state.enemy.moves.assign(["nudge"])
	result = rules.resolve(state, {"kind": "move", "move": "quickstep"})
	verify(result.events[0].side == "ally", "Move priority overrides speed")
	var sides := {}
	for seed_value in range(1, 30):
		var a := fresh(seed_value, "brindlewick")
		var b := fresh(seed_value, "brindlewick")
		a.enemy.level = 5; b.enemy.level = 5
		a.enemy.moves.assign(["nudge"]); b.enemy.moves.assign(["nudge"])
		var ea: Dictionary = rules.resolve(a, {"kind": "move", "move": "nudge"})
		var eb: Dictionary = rules.resolve(b, {"kind": "move", "move": "nudge"})
		verify(ea == eb and snapshot(a) == snapshot(b), "Same-seed ties and damage replay exactly")
		sides[ea.events[0].side] = true
	verify(sides.size() == 2, "Tie breaker can choose either side")
	var growth: RefCounted = Monster.create("growth", content.species.brindlewick, 1)
	growth.gain_experience(100000, content.species.brindlewick)
	verify(growth.level == 20 and growth.hp <= growth.max_hp(content.species.brindlewick), "Progression bounded at level 20")
func test_outcomes() -> void:
	var captures := {}
	var escapes := {}
	for seed_value in range(1, 80):
		var state := fresh(seed_value)
		var result: Dictionary = rules.resolve(state, {"kind": "item", "item": "charm"})
		verify(state.inventory.charm == 11 and state.turn == 1, "Valid charm always consumes one item/turn")
		captures[state.outcome == "capture"] = state
		if state.outcome == "capture":
			verify(result.events.size() == 1, "Successful capture stops enemy retaliation")
		else:
			verify(result.events.any(func(e: Dictionary) -> bool: return e.get("side", "") == "foe"), "Failed capture gives enemy turn")
		state = fresh(seed_value)
		result = rules.resolve(state, {"kind": "flee"})
		escapes[state.outcome == "flee"] = true
		if captures.size() == 2 and escapes.size() == 2: break
	verify(captures.size() == 2 and escapes.size() == 2, "Seeded success/failure for capture and flee")
	var state := fresh()
	var healthy_chance: float = rules.capture_chance(state)
	state.enemy.hp = 1
	verify(rules.capture_chance(state) > healthy_chance, "Weakening improves capture chance")
	state = fresh(25)
	state.enemy.hp = 1
	state.party[0].moves.assign(["quickstep"])
	var result: Dictionary = rules.resolve(state, {"kind": "move", "move": "quickstep"})
	verify(state.outcome == "victory" and not result.events.any(func(e: Dictionary) -> bool: return e.get("side", "") == "foe"), "KO prevents retaliation")
	var session := Session.new()
	var earned: Dictionary = session.claim(state)
	var xp: int = session.party[0].experience
	verify(earned.xp > 0 and session.claim(state).is_empty() and session.party[0].experience == xp, "Victory reward claimed once")
	verify(not rules.resolve(state, {"kind": "flee"}).valid, "Ended battles reject commands")
	for full: bool in [false, true]:
		session = Session.new()
		if full:
			session.party.append(Monster.create("extra_1", content.species.rillume, 3))
			session.party.append(Monster.create("extra_2", content.species.brindlewick, 3))
		state = session.begin("rillume", 3)
		var parent_hp: int = session.party[0].hp
		state.party[0].hp = 1
		verify(session.party[0].hp == parent_hp, "Battle snapshot does not mutate run state")
		state.party[0].hp = parent_hp
		state.enemy.hp = 1
		for seed_value in range(1, 100):
			state.rng.seed = seed_value
			result = rules.resolve(state, {"kind": "item", "item": "charm"})
			if state.outcome == "capture": break
		var before: int = session.party.size()
		earned = session.claim(state)
		verify(state.outcome == "capture" and not earned.is_empty(), "Capture can be claimed")
		verify(session.party.size() == before + (0 if full else 1) and session.storage.size() == (1 if full else 0), "Full party sends capture to storage")
		verify(session.claim(state).is_empty() and session.storage.size() == (1 if full else 0), "Capture cannot duplicate")
	state = fresh(3, "cindrel")
	state.party.resize(1)
	state.party[0].hp = 1
	state.enemy.level = 20
	state.enemy.moves.assign(["nudge"])
	result = rules.resolve(state, {"kind": "move", "move": "nudge"})
	verify(state.outcome == "defeat" and state.party[0].hp == 0 and not result.events.any(func(e: Dictionary) -> bool: return e.get("side", "") == "ally"), "Defeat stops fainted command")
	session = Session.new()
	earned = session.claim(state)
	verify(earned.xp == 0 and session.party[0].hp > 0, "Defeat recovers team without XP")
func test_encounters() -> void:
	var a := Encounters.new(58)
	var b := Encounters.new(58)
	var map: Resource = load("res://data/maps/forest.tres")
	var found := false
	for step in range(5):
		var ea: Dictionary = a.step(map, Vector2i(6 + step % 2, 18))
		verify(ea == b.step(map, Vector2i(6 + step % 2, 18)), "Encounter stream replays")
		found = found or not ea.is_empty()
	verify(found, "Encounter guaranteed within five eligible steps")
	a.returned()
	for step in range(6): verify(a.step(map, Vector2i(6, 18)).is_empty(), "Return cooldown prevents instant encounter")
	map = load("res://data/maps/town.tres")
	for step in range(10): verify(a.step(map, Vector2i(10, 12)).is_empty(), "Town steps never encounter")
func drain(controller: Node) -> void:
	for frame in range(20):
		if controller.phase != controller.Phase.PRESENT: break
		controller.advance(0.6)
func test_game_flow() -> void:
	var app := App.instantiate()
	root.add_child(app)
	app.world.set_physics_process(false)
	await process_frame
	app.world._mount_map("forest", Vector2i(6, 18))
	app.world.movement.facing = Vector2i.RIGHT
	for step in range(5):
		var direction := Vector2i.RIGHT if step % 2 == 0 else Vector2i.LEFT
		verify(app.world.movement.try_step(direction, app.world.current_map.can_enter), "Walk an eligible grass step")
		app.world._physics_process(0.16)
		if app.battle != null: break
	verify(app.battle != null and app.world.mode == app.world.Mode.BATTLE and app.world.movement.locked, "Real completed grass steps enter battle and lock world")
	app.battle.set_process(false)
	app.battle.confirm()
	verify(app.battle.phase == app.battle.Phase.COMMAND, "Entry reaches command UI")
	app.battle.menu = "bag"; app.battle.selected = 1
	app.battle.confirm()
	verify(app.battle.phase == app.battle.Phase.COMMAND and app.battle.state.turn == 0, "Invalid UI item leaves command active")
	app.battle.menu = "root"; app.battle.selected = 0
	await key(KEY_RIGHT)
	verify(app.battle.selected == 1, "Keyboard selects battle commands through viewport")
	await pad(JOY_BUTTON_A)
	verify(app.battle.menu == "bag", "Gamepad confirms submenu")
	await pad(JOY_BUTTON_B)
	verify(app.battle.menu == "root" and app.battle.selected == 0, "Gamepad cancels submenu")
	app._battle_closed(app.battle.state)
	verify(app.battle != null and app.world.mode == app.world.Mode.BATTLE, "Unfinished result cannot unlock world")
	app.battle.menu = "party"; app.battle.selected = 1
	app.battle.confirm()
	verify(not app.battle.submit({"kind": "flee"}), "Presentation blocks double submit")
	drain(app.battle)
	verify(app.battle.state.active == 1, "Party UI switches active companion")
	for attempt in range(30):
		if app.battle.phase == app.battle.Phase.RESULT: break
		app.battle.submit({"kind": "flee"})
		drain(app.battle)
	verify(app.battle.phase == app.battle.Phase.RESULT and app.battle.state.outcome == "flee", "Flee reaches result")
	var expected_cell: Vector2i = app.world.movement.cell
	await key(KEY_E)
	app.world.set_physics_process(false)
	verify(app.battle == null and app.world.mode == app.world.Mode.EXPLORE and app.world.movement.cell == expected_cell and not app.world.movement.locked, "Battle result returns to same world cell")
	verify(app.world.visible and app.world.get_node("HUD").visible and app.encounters.cooldown == 6, "World visuals/input restored with cooldown")
	verify(app.start_battle("cindrel", 20), "Can begin another battle")
	app.battle.set_process(false)
	app.battle.state.party.resize(1)
	app.battle.state.party[0].hp = 1
	app.battle.state.enemy.moves.assign(["nudge"])
	app.battle.confirm()
	app.battle.submit({"kind": "move", "move": app.battle.state.party[0].moves[0]})
	drain(app.battle)
	verify(app.battle.state.outcome == "defeat", "Second battle can end in defeat")
	app.battle.confirm()
	app.world.set_physics_process(false)
	verify(app.world.current_map.id == "town" and app.session.party[0].hp > 0, "Defeat returns to town with usable team")
	app.queue_free()
	await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame