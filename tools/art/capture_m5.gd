extends SceneTree
const App = preload("res://tests/fixtures/m5_game.tscn")
const Driver = preload("res://tests/expedition/play_driver.gd")
const Model = preload("res://scripts/expedition/expedition_service.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")
var app: Node
var driver := Driver.new()
var names: Array[String] = []
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	if app.field_menu != null: app.field_menu.queue_redraw()
	app.world.hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	assert(im.get_size() == Vector2i(320, 180))
	assert(im.save_png("res://artifacts/visual/m5/" + name + "_native.png") == OK)
	im.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(im.save_png("res://artifacts/visual/m5/" + name + "_3x.png") == OK)
	names.append(name)
func select_route() -> void:
	app.field_menu.selected = driver.route_index(app)
	app.field_menu.confirm()
	app.world.set_physics_process(false)
func reward() -> void:
	var offers: Array = app.data.run.offers
	app.field_menu.selected = offers.find("hearth") if "hearth" in offers else offers.find("shell") if "shell" in offers else 0
	app.field_menu.confirm()
	app.world.set_physics_process(false)
func run() -> void:
	app = App.instantiate()
	app.saves.directory = "res://.godot/m5_validation/capture_" + str(Time.get_ticks_usec())
	root.add_child(app)
	app.world.set_physics_process(false)
	await capture("hub_world")
	app.open_menu()
	await capture("hub_journal")
	app.field_menu.go("journal")
	await capture("discoveries_empty")
	app.field_menu.go("starter")
	app.field_menu.selected = 1
	await capture("starter")
	app.field_menu.confirm()
	await capture("route_choice")
	select_route()
	await capture("expedition_start")
	for depth in range(3):
		for slot in range(2):
			assert(driver.walk(app, app.world.current_map.landmarks["encounter_%s" % slot]))
			if depth == 0 and slot == 0:
				app.battle.set_process(false)
				await capture("expedition_encounter")
			assert(driver.fight(app) in ["victory", "capture"])
		assert(driver.walk(app, app.world.current_map.landmarks.exit))
		if depth == 0: await capture("relic_choice")
		reward()
		if depth == 0:
			select_route()
			await capture("stage_two")
		elif depth == 1:
			await capture("camp_fresh")
			app.field_menu.confirm()
			await capture("camp_spent")
			# Capture the actual camp-retreat screen from a saved copy of this run.
			var original: Dictionary = app.data.duplicate(true)
			assert(app.perform("end", {"outcome": "retreat"}))
			app.render_state()
			await capture("retreat_settlement")
			app.data = original
			app.render_state()
			app.field_menu.go("party")
			await capture("camp_party")
			app.field_menu.selected = 1
			app.field_menu.confirm()
			await capture("party_actions")
			app.field_menu.selected = 3
			app.field_menu.confirm()
			await capture("release_confirm")
			app.field_menu.go("reserve")
			await capture("reserve_empty")
			# Controlled full-capacity fixture for the exchange presentation.
			var camp_copy: Dictionary = app.data.duplicate(true)
			while app.data.run.party.size() < 4:
				var serial: int = app.data.run.party.size()
				var m: Dictionary = app.data.run.party[0].duplicate(true)
				m.id = "fixture_party_%s" % serial
				app.data.run.party.append(m)
			for i in range(4):
				var m: Dictionary = app.data.run.party[0].duplicate(true)
				m.id = "fixture_reserve_%s" % i
				m.species = ["rillume", "cindrel", "brindlewick"][i % 3]
				app.data.run.reserve.append(m)
			app.field_menu.selected = 2
			await capture("reserve_full_fixture")
			app.field_menu.confirm()
			app.field_menu.confirm()
			await capture("exchange_target_fixture")
			app.data = camp_copy
			app.render_state()
			app.field_menu.selected = 3
			app.field_menu.confirm()
			select_route()
			await capture("stage_three")
	# Guardian uses its own generated crown, reaction frames and entry effect.
	app.battle.set_process(false)
	await capture("guardian_entry")
	app.battle.confirm()
	app.battle.menu = "moves"
	await capture("guardian_moves")
	assert(driver.fight(app, false) == "victory")
	await capture("victory_settlement")
	app.field_menu.selected = 1
	await capture("recruit_selected")
	app.field_menu.confirm()
	await capture("admitted_recruit")
	app.field_menu.go("sanctuary")
	app.field_menu.selected = 2
	await capture("sanctuary_recruit")
	app.close_menu()
	# Resume real persisted stage state, then show abandonment and no-recruit return.
	app.open_menu(); app.field_menu.confirm(); app.field_menu.confirm(); select_route()
	app.open_menu(); app.field_menu.go("field"); app.field_menu.selected = 6; app.field_menu.confirm()
	app.close_menu()
	app.awaiting_continue = true
	assert(app.continue_run())
	app.world.set_physics_process(false)
	await capture("resumed_stage")
	app.open_menu(); app.field_menu.previous = "field"; app.field_menu.go("abandon")
	await capture("abandon_confirm")
	app.field_menu.selected = 1; app.field_menu.confirm()
	await capture("abandon_settlement")
	app.field_menu.confirm(); app.close_menu()
	# Actual defeat with a documented wounded-team fixture.
	app.open_menu(); app.field_menu.confirm(); app.field_menu.confirm(); select_route()
	app.data.run.party[0].hp = 1
	assert(driver.walk(app, app.world.current_map.landmarks.encounter_0))
	app.battle.set_process(false); app.battle.state.enemy.moves.assign(["nudge"])
	app.battle.confirm(); app.battle.submit({"kind": "move", "move": app.battle.state.party[0].moves[0]})
	for i in range(10):
		if app.battle.phase == app.battle.Phase.RESULT: break
		app.battle.advance(0.6)
	assert(app.battle.state.outcome == "defeat")
	await capture("defeat_result")
	app.battle.confirm()
	await capture("defeat_settlement")
	app.field_menu.confirm(); app.close_menu()
	await capture("returned_hub")
	# Full-map renders of all three reusable authored templates.
	for template in range(3):
		var view := SubViewport.new()
		view.size = Vector2i(512, 320)
		view.world_2d = World2D.new()
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var world := preload("res://scenes/world/exploration.tscn").instantiate()
		view.add_child(world)
		world.set_physics_process(false)
		world.get_node("HUD").visible = false
		world.regions.merge(app.world.regions)
		world.maps.expedition = Routes.build({"template": template, "theme": template, "seed": "842031"}, template)
		world._mount_map("expedition", world.maps.expedition.start)
		world.camera.enabled = false
		await process_frame
		await RenderingServer.frame_post_draw
		var im := view.get_texture().get_image()
		im.save_png("res://artifacts/visual/m5/map_%s_native.png" % template)
		im.resize(1024, 640, Image.INTERPOLATE_NEAREST)
		im.save_png("res://artifacts/visual/m5/map_%s_2x.png" % template)
		view.queue_free()
		await process_frame
	var sheet := Image.create(384, 400, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.html("20283d"))
	var top := 0
	for id: String in ["props", "relics", "outcomes", "guardian", "effects", "journal"]:
		var source := Image.new()
		assert(source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/m5/" + id + ".png")) == OK)
		sheet.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i(0, top))
		top += source.get_height() + 4
	sheet.save_png("res://artifacts/visual/m5/assets_native.png")
	sheet.resize(1152, 1200, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://artifacts/visual/m5/assets_3x.png")
	var f := FileAccess.open("res://artifacts/visual/m5/views.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(names, "\t") + "\n"); f.close()
	app.queue_free()
	await process_frame
	print("M5 CAPTURE PASS: %s native/3x interface views plus three native/2x map overviews" % names.size())
	quit()