extends SceneTree
## Runs a real-time graphical playthrough. No player save or combat-stat fixtures.
const App = preload("res://tests/fixtures/m5_game.tscn")
const Driver = preload("res://tests/expedition/play_driver.gd")
var app: Node
var driver := Driver.new()
var commands: int = 0
var started: int = 0
func _initialize() -> void: run.call_deferred()
func pause(seconds: float) -> void: await create_timer(seconds).timeout
func paced_walk(target: Vector2i) -> void:
	var cells := driver.path(app.world.current_map, app.world.movement.cell, target)
	for cell: Vector2i in cells:
		assert(app.world.movement.try_step(cell - app.world.movement.cell, app.world.current_map.can_enter))
		while app.world.movement.moving: await process_frame
		await process_frame
func paced_fight() -> String:
	var battle: Node = app.battle
	assert(battle != null)
	for iteration in range(10000):
		if battle.phase == battle.Phase.COMMAND:
			await pause(0.12)
			assert(battle.submit(driver.command(battle.session, battle.state)))
			commands += 1
		elif battle.phase == battle.Phase.RESULT:
			await pause(0.6)
			var outcome: String = battle.state.outcome
			battle.confirm()
			return outcome
		await process_frame
	return "timeout"
func run() -> void:
	app = App.instantiate()
	app.saves.directory = "res://.godot/m5_validation/paced_" + str(Time.get_ticks_usec())
	root.add_child(app)
	started = Time.get_ticks_msec()
	app.open_menu(); app.field_menu.confirm(); app.field_menu.selected = 1; app.field_menu.confirm()
	for depth in range(3):
		print("M5 PACED STAGE %s: real movement/event clocks" % (depth + 1))
		app.field_menu.selected = driver.route_index(app)
		await pause(0.5)
		app.field_menu.confirm()
		for slot in range(2):
			await paced_walk(app.world.current_map.landmarks["encounter_%s" % slot])
			assert(await paced_fight() in ["victory", "capture"])
		await paced_walk(app.world.current_map.landmarks.exit)
		await pause(0.5)
		var offers: Array = app.data.run.offers
		app.field_menu.selected = offers.find("hearth") if "hearth" in offers else offers.find("shell") if "shell" in offers else 0
		app.field_menu.confirm()
		if depth == 1:
			await pause(0.5)
			app.field_menu.confirm()
			app.field_menu.selected = 3
			await pause(0.5)
			app.field_menu.confirm()
	assert(await paced_fight() == "victory")
	await pause(0.5)
	app.field_menu.selected = 1
	app.field_menu.confirm()
	assert(app.data.profile.completed == 1 and app.data.profile.roster.size() == 3)
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	var file := FileAccess.open("res://.godot/m5_validation/paced_result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seconds": seconds, "commands": commands, "outcome": "victory", "note": "scripted graphical playthrough at real movement/presentation clocks; not human playtime"}))
	file.close()
	print("M5 PACED PASS: %.2f seconds, %s real-time commands; victory/admission; scripted, not human playtime" % [seconds, commands])
	app.queue_free()
	await process_frame
	quit()