extends SceneTree
const App = preload("res://scenes/app/game.tscn")
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Sim = preload("res://tests/progression/simulator.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var app: Node
var driver := Driver.new()
var names: Array[String] = []
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	if app.field_menu != null: app.field_menu.queue_redraw()
	app.world.hud.queue_redraw()
	if app.battle != null: app.battle.view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == Vector2i(320, 180))
	assert(image.save_png("res://artifacts/visual/m6/" + name + "_native.png") == OK)
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(image.save_png("res://artifacts/visual/m6/" + name + "_3x.png") == OK)
	names.append(name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/visual/m6")
	app = App.instantiate()
	app.saves.directory = "res://.godot/m6_validation/capture_" + str(Time.get_ticks_usec())
	root.add_child(app)
	app.world.set_physics_process(false)
	await capture("sanctuary_initial")
	app.open_menu()
	for screen: String in ["hub", "research", "projects", "preparation", "goals", "mastery", "settings"]:
		app.field_menu.go(screen)
		await capture(screen)
	app.field_menu.go("project")
	app.field_menu.project_index = 2
	await capture("workshop_locked")
	app.field_menu.go("starter")
	app.field_menu.selected = 1
	app.field_menu.confirm()
	await capture("briefing")
	app.field_menu.confirm()
	for depth in range(3):
		app.field_menu.selected = driver.route_index(app)
		app.field_menu.confirm()
		app.world.set_physics_process(false)
		if depth == 0:
			await capture("trail_start")
			assert(driver.walk(app, app.world.current_map.landmarks.event))
			app._world_action("trail_event")
			await capture("trail_event")
			app.field_menu.selected = 1 if Model.event_kind(app.data.run) == 2 else 0
			app.field_menu.confirm()
			await capture("spring_spent")
		for slot in range(2):
			assert(driver.walk(app, app.world.current_map.landmarks["encounter_%s" % slot]))
			assert(driver.fight(app) in ["victory", "capture"])
		assert(driver.walk(app, app.world.current_map.landmarks.exit))
		if depth == 0: await capture("relic_choice")
		var offers: Array = app.data.run.offers
		app.field_menu.selected = offers.find("hearth") if "hearth" in offers else offers.find("shell") if "shell" in offers else 0
		app.field_menu.confirm()
		if depth == 1:
			await capture("camp")
			var camp_copy: Dictionary = app.data.duplicate(true)
			assert(Model.request_end(app.data, "retreat") == "")
			app.render_state()
			await capture("retreat_return")
			assert(Model.settle(app.data, "") == "")
			app.mount_hub()
			app.show_menu("result")
			await capture("retreat_rewards")
			app.data = camp_copy
			app.render_state()
			app.field_menu.confirm()
			app.field_menu.selected = 3
			app.field_menu.confirm()
	assert(driver.fight(app) == "victory")
	await capture("victory_return")
	app.field_menu.selected = 1
	app.field_menu.confirm()
	await capture("result_rewards")
	app.field_menu.go("projects")
	await capture("projects_available")
	# Play additional pure expeditions to make the completed project screens reviewable.
	for index in range(5):
		assert(Model.depart(app.data, index % 2, index) == "")
		var sim := Sim.new()
		sim.run(app.data)
		assert(sim.error.is_empty())
		assert(Model.settle(app.data, "") == "")
	for id: String in Meta.PROJECTS: assert(Meta.buy(app.data, id) == "")
	app.dispose_menu()
	app.mount_hub()
	app.world.set_physics_process(false)
	assert(driver.walk(app, Vector2i(14, 21)))
	app.world.camera.reset_smoothing()
	app.world.camera.force_update_scroll()
	await capture("sanctuary_projects")
	await overview(app.world.current_map, "sanctuary_map")
	app.open_menu()
	for screen: String in ["projects", "research", "mastery", "goals"]:
		app.field_menu.go(screen)
		await capture(screen + "_progressed")
	app.field_menu.go("project")
	app.field_menu.project_index = 2
	await capture("workshop_built")
	for screen: String in ["loadout", "survey", "pool", "tier", "preview_pool"]:
		app.field_menu.go(screen)
		await capture(screen + "_choices")
	# Explicit presentation fixtures show every new relic and growth form without altering player saves.
	for i in range(6):
		app.field_menu.go("preview_pool")
		app.field_menu.selected = i
		await capture("relic_%s" % i)
	var progressed: Dictionary = app.data.duplicate(true)
	for i in range(3):
		app.data = progressed.duplicate(true)
		if i == 2:
			app.data.profile.roster.append(Model.record("capture_sheet_rillume", "rillume"))
			Meta.sync_research(app.data.profile)
		app.data.profile.meta.study[Meta.BASES[i]] = ["run_1/battle_1", "run_1/battle_2", "run_1/battle_3"]
		Meta.sync_research(app.data.profile)
		Model.depart(app.data, 0)
		app.data.run.rules.growth = [Meta.BASES[i]]
		Model.choose_route(app.data, 0)
		var m := Model.Monster.create("run_%s_starter" % app.data.run.id, Model.Catalog.new().species[Meta.FORMS[Meta.BASES[i]]], 7)
		app.data.run.party = [Model.member(m)]
		Model.prepare(app.data, 0)
		app.render_state()
		app.battle.set_process(false)
		app.battle.confirm()
		await capture("growth_%s_back" % i)
		app.battle.state.enemy.species_id = Meta.FORMS[Meta.BASES[i]]
		app.battle.state.enemy.moves.assign(app.session.catalog.species[app.battle.state.enemy.species_id].moves)
		app.battle.display_enemy_hp = app.battle.state.enemy.max_hp(app.session.catalog.species[app.battle.state.enemy.species_id])
		await capture("growth_%s_front" % i)
		app.remove_child(app.battle)
		app.battle.queue_free()
		app.battle = null
	app.data = progressed
	app.mount_hub()
	app.show_menu("result")
	await capture("latest_result")
	var profile_copy: Dictionary = app.data.duplicate(true)
	var captured_defeat := false
	for seed_value in range(16):
		var losing := Model.fresh()
		Model.depart(losing, 0, seed_value)
		var sim := Sim.new()
		sim.run(losing)
		if losing.run.outcome != "defeat": continue
		app.data = losing
		app.render_state()
		await capture("defeat_return")
		Model.settle(app.data, "")
		app.mount_hub()
		app.show_menu("result")
		await capture("defeat_rewards")
		captured_defeat = true
		break
	assert(captured_defeat, "seed set must include an actual resolver defeat")
	app.data = profile_copy
	app.render_state()
	for template in range(3):
		var d := Model.fresh()
		Model.depart(d, 0, 0)
		Model.choose_route(d, 0)
		d.run.options[0][0].template = template
		await overview(Model.map_for(d.run), "route_%s" % template)
	var file := FileAccess.open("res://artifacts/visual/m6/views.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(names, "\t") + "\n")
	file.close()
	print("M6 CAPTURE PASS: %s native/3x views, actual GPU app with isolated presentation fixtures" % names.size())
	app.queue_free()
	await process_frame
	await process_frame
	quit()

func overview(map: Resource, name: String) -> void:
	var view := SubViewport.new()
	view.size = map.size * 16
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world := preload("res://scenes/world/exploration.tscn").instantiate()
	view.add_child(world)
	world.set_physics_process(false)
	world.get_node("HUD").visible = false
	world.regions.merge(app.world.regions)
	world.maps[map.id] = map
	world._mount_map(map.id, map.start)
	world.camera.enabled = false
	await process_frame
	await RenderingServer.frame_post_draw
	var im := view.get_texture().get_image()
	im.save_png("res://artifacts/visual/m6/" + name + "_native.png")
	im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
	im.save_png("res://artifacts/visual/m6/" + name + "_2x.png")
	view.queue_free()
	await process_frame