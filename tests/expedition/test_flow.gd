extends SceneTree
const App = preload("res://tests/fixtures/m5_game.tscn")
const Model = preload("res://scripts/expedition/expedition_service.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var checks: int = 0
var failures: int = 0
var app: Node
var driver := Driver.new()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func key(code: Key) -> void:
	var e := InputEventKey.new(); e.keycode = code; e.pressed = true; Input.parse_input_event(e)
	await process_frame
	e = InputEventKey.new(); e.keycode = code; Input.parse_input_event(e)
	await process_frame
	app.world.set_physics_process(false)
func button(code: JoyButton) -> void:
	var e := InputEventJoypadButton.new(); e.button_index = code; e.pressed = true; Input.parse_input_event(e)
	await process_frame
	e = InputEventJoypadButton.new(); e.button_index = code; Input.parse_input_event(e)
	await process_frame
	app.world.set_physics_process(false)
func _initialize() -> void: run.call_deferred()
func setup(index: int = 1) -> void:
	check(app.open_menu(), "open hub journal")
	app.field_menu.confirm()
	app.field_menu.selected = index
	app.field_menu.confirm()
	check(app.field_menu.screen == "route", "departure reaches mandatory route choice")
func select_route() -> void:
	app.field_menu.selected = driver.route_index(app)
	app.field_menu.confirm()
	app.world.set_physics_process(false)
func complete_stage() -> bool:
	for slot in range(2):
		check(driver.walk(app, app.world.current_map.landmarks["encounter_%s" % slot]), "actual grid traversal to fern light")
		check(app.battle != null, "completed step enters battle")
		var outcome := driver.fight(app)
		check(outcome in ["victory", "capture"], "real commands resolve finite encounter: " + outcome)
		if not app.data.run.is_empty() and app.data.run.phase == "settle": return false
	check(driver.walk(app, app.world.current_map.landmarks.exit), "grid traversal reaches stage gate")
	check(app.field_menu != null and app.field_menu.screen == "reward", "stage gate opens relic reward")
	return true
func choose_relic() -> void:
	var offers: Array = app.data.run.offers
	app.field_menu.selected = offers.find("hearth") if "hearth" in offers else offers.find("shell") if "shell" in offers else 0
	app.field_menu.confirm()
	app.world.set_physics_process(false)
func run() -> void:
	var started := Time.get_ticks_msec()
	var directory := "res://.godot/m5_validation/flow_" + str(Time.get_ticks_usec())
	app = App.instantiate()
	app.saves.directory = directory
	root.add_child(app)
	app.world.set_physics_process(false)
	var sanctuary: Array = app.data.profile.roster.duplicate(true)
	await key(KEY_TAB)
	check(app.field_menu.screen == "hub", "keyboard opens sanctuary menu")
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "starter", "gamepad starter selection")
	await button(JOY_BUTTON_DPAD_DOWN)
	await button(JOY_BUTTON_A)
	check(app.data.run.party.size() == 1 and app.field_menu.screen == "route", "gamepad commits departure")
	await button(JOY_BUTTON_B)
	check(app.field_menu.screen == "abandon" and app.field_menu.selected == 0, "mandatory route back offers safe abandon cancellation")
	await button(JOY_BUTTON_B)
	check(app.field_menu.screen == "route", "back returns to route")
	select_route()
	check(not app.continue_run(), "active field cannot roll back through Continue")
	var first_map: Resource = app.world.current_map
	check(driver.walk(app, first_map.landmarks.encounter_0), "walk first finite light")
	check(app.battle != null and not app.open_menu(), "battle locks field journal")
	var pending: Dictionary = app.data.duplicate(true)
	var replay := App.instantiate()
	replay.saves.directory = directory
	root.add_child(replay)
	replay.world.set_physics_process(false)
	check(replay.awaiting_continue and replay.data == pending, "startup reads active checkpoint without replacing it")
	check(replay.continue_run() and replay.battle != null, "Continue resumes pending encounter")
	replay.battle.set_process(false)
	check(replay.battle.state.enemy.id == app.battle.state.enemy.id and replay.battle.state.rng.state == app.battle.state.rng.state, "pending enemy identity and battle RNG survive interruption")
	replay.free()
	# Failed post-battle write leaves profile/run unchanged and retryable battle result.
	var obstruction := directory + "/blocked"
	var f := FileAccess.open(obstruction, FileAccess.WRITE); f.store_string("file"); f.close()
	app.saves.directory = obstruction
	var outcome := driver.fight(app)
	check(outcome in ["victory", "capture"] and app.battle != null and app.battle.phase == app.battle.Phase.RESULT, "failed battle checkpoint stays retryable")
	check(app.data == pending, "failed checkpoint never publishes candidate")
	app.saves.directory = directory
	app.battle.confirm()
	app.world.set_physics_process(false)
	check(app.battle == null and app.data.run.cleared == [0], "retry commits once and returns field")
	var count: int = app.data.profile.discovered.size()
	check(driver.walk(app, app.world.current_map.landmarks.encounter_0), "revisit cleared light")
	check(app.battle == null and app.data.profile.discovered.size() == count, "revisit cannot farm encounters/discoveries")
	check(driver.walk(app, app.world.current_map.landmarks.encounter_1), "walk second light")
	check(driver.fight(app) in ["victory", "capture"], "finish second light")
	check(driver.walk(app, app.world.current_map.landmarks.exit), "walk to first reward")
	await button(JOY_BUTTON_B)
	check(app.field_menu.screen == "abandon", "reward back has a safe abandonment path")
	await button(JOY_BUTTON_B)
	app.field_menu.selected = app.data.run.offers.find("hearth")
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "route", "stage one reward advances route")
	select_route()
	if not complete_stage(): finish_test(started); return
	choose_relic()
	check(app.field_menu.screen == "camp", "stage two reward reaches camp")
	await button(JOY_BUTTON_A)
	check(app.data.run.camp_used, "gamepad spends one camp rest")
	var unchanged: Dictionary = app.data.duplicate(true)
	await button(JOY_BUTTON_A)
	check(app.data == unchanged, "repeated camp confirm cannot refill/heal")
	# Every optional screen has a working back path.
	for entry in [1, 2]:
		app.field_menu.selected = entry
		await button(JOY_BUTTON_A)
		check(app.field_menu.screen == ("party" if entry == 1 else "reserve"), "camp submenu navigation")
		await button(JOY_BUTTON_B)
		check(app.field_menu.screen == "camp", "camp submenu back")
	# Confirmed-release cancellation is reachable on a physical-input-shaped path.
	app.field_menu.selected = 1
	await button(JOY_BUTTON_A)
	app.field_menu.selected = 1
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "member", "gamepad reaches companion actions")
	app.field_menu.selected = 3
	var before_release: Dictionary = app.data.duplicate(true)
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "release" and app.field_menu.selected == 0, "release defaults to keeping companion")
	await button(JOY_BUTTON_B)
	check(app.data == before_release, "release cancellation preserves collection")
	await button(JOY_BUTTON_B)
	await button(JOY_BUTTON_B)
	# A controlled reserve fixture exercises readonly focus paths without writes.
	var camp_original: Dictionary = app.data.duplicate(true)
	var reserve_fixture: Dictionary = app.data.run.party[0].duplicate(true)
	reserve_fixture.id = "run_1_capture_4"
	app.data.run.reserve.append(reserve_fixture)
	app.field_menu.selected = 2
	await button(JOY_BUTTON_A)
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "reserve_member", "reserve actions reachable")
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "reserve_target", "exchange target reachable")
	await button(JOY_BUTTON_B)
	await button(JOY_BUTTON_DPAD_DOWN)
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "release", "reserve release confirmation reachable")
	await button(JOY_BUTTON_B)
	await button(JOY_BUTTON_B)
	await button(JOY_BUTTON_B)
	app.data = camp_original
	app.field_menu.selected = 5
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "field", "camp exposes journal and field screens")
	for menu_index in [1, 3, 4, 5]:
		app.field_menu.selected = menu_index
		await button(JOY_BUTTON_A)
		check(app.field_menu.screen in ["balm", "relics", "journal", "settings"], "optional journal screen focus")
		await button(JOY_BUTTON_B)
		app.field_menu.selected = 5
		await button(JOY_BUTTON_A)
	app.field_menu.go("camp")
	app.field_menu.selected = 3
	await button(JOY_BUTTON_A)
	select_route()
	if not complete_stage(): finish_test(started); return
	choose_relic()
	check(app.battle != null and app.battle.state.guardian, "third relic enters guardian")
	check(driver.fight(app, false) == "victory", "real guardian victory")
	check(app.field_menu.screen == "settle" and app.data.profile.roster == sanctuary, "sanctuary not mutated before admission")
	check(not Model.eligible(app.data.run).is_empty(), "real captures supply an eligible recruit")
	var settlement: Dictionary = app.data.duplicate(true)
	app.saves.directory = obstruction
	app.field_menu.selected = 1
	await button(JOY_BUTTON_A)
	check(app.field_menu.screen == "settle" and app.data == settlement, "failed admission write keeps retryable settlement and original profile")
	app.saves.directory = directory
	await button(JOY_BUTTON_A)
	check(app.data.run.is_empty() and app.data.profile.roster.size() == 3 and app.data.profile.completed == 1, "victory admission commits exactly once")
	check(app.world.mode == app.world.Mode.MENU, "result presentation keeps movement locked")
	await button(JOY_BUTTON_B)
	check(app.field_menu == null and app.world.mode == app.world.Mode.EXPLORE, "result exits to usable hub")
	# Second expedition uses a new seed; abandonment before choosing a route is safe.
	setup(2)
	check(app.data.run.id == 2 and app.data.run.party[0].level == 5 and app.data.run.relics.is_empty() and app.data.run.inventory.balm == 2, "second run resets copied team and resources")
	await key(KEY_ESCAPE)
	await key(KEY_DOWN)
	await key(KEY_E)
	check(app.field_menu.screen == "settle" and app.data.run.outcome == "abandon", "confirmed route abandonment")
	await key(KEY_E)
	check(app.data.run.is_empty() and app.data.profile.completed == 1, "abandon returns without extra completion")
	await key(KEY_ESCAPE)
	# A real resolver defeat with a wounded starter must end, not heal the run.
	setup(0); select_route()
	var wounded: Dictionary = app.data.duplicate(true)
	wounded.run.party[0].hp = 1
	check(app.commit(wounded), "persist wounded starting fixture")
	check(driver.walk(app, app.world.current_map.landmarks.encounter_0), "defeat fixture enters through walking")
	app.battle.set_process(false)
	app.battle.state.enemy.moves.assign(["nudge"])
	app.battle.confirm()
	app.battle.submit({"kind": "move", "move": "nudge"})
	for i in range(10):
		if app.battle.phase == app.battle.Phase.RESULT: break
		app.battle.advance(0.6)
	check(app.battle.state.outcome == "defeat", "actual attack resolution defeats wounded team")
	app.battle.confirm()
	check(app.data.run.outcome == "defeat" and app.data.run.party[0].hp == 0, "defeat cannot continue a healed expedition")
	app.field_menu.confirm()
	check(app.data.profile.roster.size() == 3 and app.data.profile.completed == 1, "defeat preserves original roster and completions")
	app.close_menu()
	# Real camp retreat loop, without banking a second recruit.
	setup(1)
	for stage in range(2):
		select_route()
		if not complete_stage(): finish_test(started); return
		choose_relic()
	app.field_menu.selected = 4
	app.field_menu.confirm()
	check(app.data.run.outcome == "retreat", "camp retreat enters settlement")
	app.field_menu.confirm()
	check(app.data.run.is_empty() and app.data.profile.last.outcome == "retreat" and app.data.profile.completed == 1, "retreat without recruit leaves correct profile")
	app.close_menu()
	setup(0)
	check(app.data.run.id == 5, "all outcomes permit another departure")
	finish_test(started)
func finish_test(started: int) -> void:
	print("M5 FLOW METRICS: %sms, %s steps, %s battles, %s commands, %s captures (automated, not human duration)" % [Time.get_ticks_msec() - started, driver.steps, driver.battles, driver.turns, driver.captures])
	app.queue_free()
	await process_frame
	print("M5 FLOW PASS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)