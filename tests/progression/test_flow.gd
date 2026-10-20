extends SceneTree
const App = preload("res://scenes/app/game.tscn")
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Codec = preload("res://scripts/progression/save_codec.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var app: Node
var driver := Driver.new()
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func key(action: String, joy: bool = false) -> void:
	var event: InputEvent
	if joy:
		var button := InputEventJoypadButton.new()
		button.button_index = {"interact": JOY_BUTTON_A, "close_dialogue": JOY_BUTTON_B, "field_menu": JOY_BUTTON_START, "walk_down": JOY_BUTTON_DPAD_DOWN}[action]
		button.pressed = true
		event = button
	else:
		var keyboard := InputEventKey.new()
		keyboard.keycode = {"interact": KEY_E, "close_dialogue": KEY_ESCAPE, "field_menu": KEY_TAB, "walk_down": KEY_DOWN}[action]
		keyboard.pressed = true
		event = keyboard
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	app.world.set_physics_process(false)
func setup() -> void:
	check(app.open_menu(), "open hub")
	app.field_menu.confirm()
	app.field_menu.selected = 1
	app.field_menu.confirm()
	check(app.field_menu.screen == "briefing", "review departure rules")
	app.field_menu.confirm()
	check(app.field_menu.screen == "route", "depart to route")
func stage() -> void:
	app.field_menu.selected = driver.route_index(app)
	app.field_menu.confirm()
	app.world.set_physics_process(false)
	check(driver.walk(app, app.world.current_map.landmarks.event), "walk to spring")
	app._world_action("trail_event")
	check(app.field_menu.screen == "event", "spring choices")
	app.field_menu.selected = 1 if Model.event_kind(app.data.run) == 2 else 0
	app.field_menu.confirm()
	check(app.data.run.events.has(int(app.data.run.stage)), "finite event committed")
	for slot in range(2):
		check(driver.walk(app, app.world.current_map.landmarks["encounter_%s" % slot]), "walk to encounter")
		check(app.battle != null, "enters actual battle")
		check(app.audio.theme == "battle", "wild battle music")
		check(driver.fight(app) in ["victory", "capture"], "resolver wins or captures")
		check(app.audio.theme == "forest", "exploration music returns")
	check(driver.walk(app, app.world.current_map.landmarks.exit), "walk to gate")
	check(app.field_menu.screen == "reward", "relic offer")
	check(app.data.run.offers.size() <= 2, "mutually exclusive reward")
	var offers: Array = app.data.run.offers
	app.field_menu.selected = offers.find("hearth") if "hearth" in offers else offers.find("shell") if "shell" in offers else 0
	app.field_menu.confirm()
	app.world.set_physics_process(false)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	app = App.instantiate()
	var directory := "res://.godot/m6_validation/flow_" + str(Time.get_ticks_usec())
	app.saves.directory = directory
	root.add_child(app)
	app.world.set_physics_process(false)
	var original: Array = app.data.profile.roster.duplicate(true)
	await process_frame
	await key("field_menu")
	check(app.field_menu.screen == "hub", "keyboard menu")
	for screen: String in ["research", "projects", "preparation", "goals", "mastery", "settings"]:
		app.field_menu.go("hub")
		app.field_menu.selected = {"research": 4, "projects": 5, "preparation": 6, "goals": 7, "mastery": 8, "settings": 3}[screen]
		await key("interact", true)
		check(app.field_menu.screen == screen, "gamepad enters " + screen)
		check(not app.field_menu.choices().is_empty(), "reachable " + screen)
		await key("walk_down", true)
		await key("close_dialogue", true)
		check(app.field_menu.screen == "hub", "gamepad back " + screen)
	app.field_menu.go("projects")
	app.field_menu.confirm()
	check(app.field_menu.screen == "project", "project detail")
	app.field_menu.selected = 1
	app.field_menu.confirm()
	check(app.data.profile.meta.projects.is_empty(), "locked purchase no charge")
	app.field_menu.back()
	app.field_menu.back()
	app.field_menu.back()
	setup()
	var pending: Dictionary
	for depth in range(3):
		stage()
		if depth == 0:
			check(app.data.profile.meta.marks >= 3, "first stage marks permanent")
			var checkpoint: Dictionary = app.saves.load_game({})
			check(not checkpoint.has("error") and checkpoint.data == app.data, "actual checkpoint roundtrip")
		if depth == 1:
			check(app.field_menu.screen == "camp", "camp")
			check(app.audio.theme == "camp", "camp music")
			app.field_menu.confirm()
			check(app.data.run.camp_used, "one rest")
			app.field_menu.selected = 3
			app.field_menu.confirm()
	check(app.battle != null and app.battle.state.guardian, "guardian")
	check(app.audio.theme == "guardian", "guardian music")
	check(driver.fight(app) == "victory", "guardian victory")
	check(app.audio.theme == "camp", "settlement calm music")
	check(app.data.run.secured == 3, "third stage mark committed before settlement")
	var result: Dictionary = app.data.duplicate(true)
	var obstruction := directory + "/blocked"
	var blocker := FileAccess.open(obstruction, FileAccess.WRITE)
	blocker.store_string("fixture")
	blocker.close()
	app.saves.directory = obstruction
	app.field_menu.confirm()
	check(app.data == result and app.field_menu.screen == "settle", "settlement I/O failure atomic")
	app.saves.directory = directory
	app.field_menu.selected = 1 if not Model.eligible(app.data.run).is_empty() else 0
	app.field_menu.confirm()
	check(app.data.profile.completed == 1 and app.data.run.is_empty(), "return/admit")
	check(app.audio.theme == "hub", "home music")
	check(app.data.profile.roster.slice(0, 2) == original, "originals safe")
	check(app.data.profile.last.bonus == 1 and app.data.profile.last.secured == 3, "separate bonus and secured")
	app.field_menu.go("projects")
	app.field_menu.confirm()
	var before_buy: Dictionary = app.data.duplicate(true)
	app.saves.directory = obstruction
	check(not app.perform("buy", {"id": "trail"}) and app.data == before_buy, "purchase I/O failure atomic")
	app.saves.directory = directory
	app.field_menu.selected = 1
	app.field_menu.confirm()
	check("trail" in app.data.profile.meta.projects, "earned marks build project")
	check(app.world.current_map.props.any(func(p: Dictionary) -> bool: return p.region == "m6_trail_2"), "hub reflects purchase")
	var balance: int = app.data.profile.meta.marks
	check(not app.perform("buy", {"id": "trail"}) and app.data.profile.meta.marks == balance, "purchase once")
	check(app.perform("prepare", {"key": "survey", "value": "rillume"}), "survey unlocked")
	app.close_menu()
	setup()
	var snapshot: Dictionary = app.data.run.rules.duplicate(true)
	app.field_menu.confirm()
	app.world.set_physics_process(false)
	check(driver.walk(app, app.world.current_map.landmarks.encounter_0), "second run encounter")
	pending = app.data.run.pending.duplicate(true)
	# Restart while a battle is open, then Continue the same descriptor.
	app.free()
	app = App.instantiate()
	app.saves.directory = directory
	root.add_child(app)
	app.world.set_physics_process(false)
	check(app.awaiting_continue, "startup offers Continue")
	check(app.open_menu(), "open Continue")
	app.field_menu.confirm()
	check(app.battle != null and app.data.run.pending == pending and app.data.run.rules == snapshot, "Continue same enemy and snapshot")
	check(app.audio.theme == "battle", "Continue selects battle without forest detour")
	check(driver.fight(app) in ["victory", "capture"], "resumed battle")
	check(app.open_menu(), "abandon menu")
	check(app.perform("end", {"outcome": "abandon"}), "abandon")
	app.render_state()
	app.field_menu.confirm()
	check(app.data.run.is_empty() and app.data.profile.completed == 1, "abandon no victory")
	check(app.saves.load_game({}).data == app.data, "final persisted profile")
	app.queue_free()
	await process_frame
	print("M6 FLOW %s: %s assertions, %s failures, %s steps, %s commands" % ["PASS" if failures == 0 else "FAIL", checks, failures, driver.steps, driver.turns])
	quit(1 if failures else 0)
