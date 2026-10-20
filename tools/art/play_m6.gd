extends SceneTree
## Real movement/event timing and real resolver, isolated saves; no combat-stat fixtures.
const App = preload("res://scenes/app/game.tscn")
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var app: Node
var driver := Driver.new()
var started := 0
var commands := 0
var steps := 0
var project_times: Dictionary = {}
var results: Array = []
var mode: String = "victory"
func _initialize() -> void: run.call_deferred()
func pause(seconds: float) -> void: await create_timer(seconds).timeout
func track() -> void:
	for id: String in Meta.PROJECTS:
		if app.data.profile.meta.marks >= Meta.PROJECTS[id].cost and not project_times.has(id): project_times[id] = (Time.get_ticks_msec() - started) / 1000.0
func walk(target: Vector2i) -> void:
	for cell: Vector2i in driver.path(app.world.current_map, app.world.movement.cell, target):
		assert(app.world.movement.try_step(cell - app.world.movement.cell, app.world.current_map.can_enter))
		steps += 1
		while app.world.movement.moving: await process_frame
		await process_frame
func fight() -> String:
	var battle: Node = app.battle
	for iteration in range(10000):
		if battle.phase == battle.Phase.COMMAND:
			await pause(0.12)
			var command: Dictionary = {"kind": "move", "move": "nudge"} if mode == "defeat" else driver.command(battle.session, battle.state)
			assert(battle.submit(command))
			commands += 1
		elif battle.phase == battle.Phase.RESULT:
			await pause(0.6)
			var outcome: String = battle.state.outcome
			battle.confirm()
			track()
			return outcome
		await process_frame
	assert(false, "paced fight timeout")
	return "timeout"
func play(outcome: String) -> void:
	mode = outcome
	app = App.instantiate()
	app.saves.directory = "res://.godot/m6_validation/paced_" + outcome + "_" + str(Time.get_ticks_usec())
	root.add_child(app)
	commands = 0
	steps = 0
	project_times = {}
	started = Time.get_ticks_msec()
	var marks_before: int = app.data.profile.meta.marks
	app.open_menu()
	app.field_menu.confirm()
	app.field_menu.selected = 0 if mode == "defeat" else 1
	app.field_menu.confirm()
	app.field_menu.confirm()
	var finished := false
	for depth in range(3):
		app.field_menu.selected = driver.route_index(app)
		if mode == "defeat":
			for i in range(2):
				if app.data.run.options[depth][i].theme == 1: app.field_menu.selected = i
		await pause(0.5)
		app.field_menu.confirm()
		if mode != "defeat":
			await walk(app.world.current_map.landmarks.event)
			app._world_action("trail_event")
			await pause(0.5)
			app.field_menu.selected = 1 if Model.event_kind(app.data.run) == 2 else 0
			app.field_menu.confirm()
		for slot in range(2):
			await walk(app.world.current_map.landmarks["encounter_%s" % slot])
			var result := await fight()
			if result == "defeat": finished = true; break
		if finished: break
		await walk(app.world.current_map.landmarks.exit)
		track()
		await pause(0.5)
		var offers: Array = app.data.run.offers
		app.field_menu.selected = offers.find("hearth") if "hearth" in offers else offers.find("shell") if "shell" in offers else 0
		app.field_menu.confirm()
		if depth == 1:
			if mode == "retreat":
				app.field_menu.selected = 4
				app.field_menu.confirm()
				finished = true
				break
			if mode != "defeat": app.field_menu.confirm()
			app.field_menu.selected = 3
			app.field_menu.confirm()
	if not finished: await fight()
	var terminal: String = app.data.run.outcome
	assert(terminal == mode, "expected actual " + mode + " got " + terminal)
	var supplies: Dictionary = app.data.run.inventory.duplicate()
	await pause(0.5)
	app.field_menu.selected = 1 if not Model.eligible(app.data.run).is_empty() else 0
	app.field_menu.confirm()
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	var earned: int = app.data.profile.meta.marks - marks_before
	results.append({"outcome": terminal, "seconds": seconds, "commands": commands, "steps": steps, "marks": earned, "marks_per_minute": earned * 60.0 / seconds, "supply_remaining": supplies, "first_affordable_seconds": project_times, "note": "scripted real clocks, minimal decision time; defeat deliberately uses weak moves and no recovery"})
	print("M6 PACED RESULT: ", JSON.stringify(results.back()))
	app.queue_free()
	await process_frame
	await process_frame
func run() -> void:
	for outcome: String in ["victory", "retreat", "defeat"]: await play(outcome)
	var file := FileAccess.open("res://.godot/m6_validation/paced_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	print("M6 PACED PASS: victory, retreat and defeat at real clocks; not human timing")
	quit()
