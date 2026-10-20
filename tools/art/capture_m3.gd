extends SceneTree
const App = preload("res://tests/fixtures/legacy_game.tscn")
const Monster = preload("res://scripts/monsters/monster_state.gd")
const OUTPUT := "res://artifacts/visual/m3"
var app: Node
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	app = App.instantiate()
	root.add_child(app)
	app.world.set_physics_process(false)
	app.world._mount_map("forest", Vector2i(7, 18))
	assert(app.start_battle("rillume", 5))
	var battle: Node = app.battle
	battle.set_process(false)
	battle.confirm()
	await capture("01_rillume_battle")
	battle.menu = "moves"
	await capture("02_moves")
	battle.menu = "bag"
	await capture("03_bag")
	battle.menu = "party"
	await capture("04_party")
	assert(battle.submit({"kind": "move", "move": "leaf_arc"}))
	while battle.event.get("side", "") != "ally" and not battle.events.is_empty(): battle.next_event()
	await capture("05_leaf_arc")
	drain()
	# A wounded-ally fixture makes the healing presentation reproducible even if the foe missed.
	battle.state.party[battle.state.active].hp = mini(20, battle.state.party[battle.state.active].hp)
	battle.display_hp[battle.state.active] = battle.state.party[battle.state.active].hp
	assert(battle.submit({"kind": "item", "item": "balm"}))
	await capture("06_balm")
	drain()
	battle.state.rng.seed = 1
	assert(battle.submit({"kind": "item", "item": "charm"}))
	await capture("07_capture_ring")
	drain()
	assert(battle.state.outcome == "capture")
	await capture("08_capture_result")
	battle.confirm()
	app.world.set_physics_process(false)
	await capture("09_return_to_grass")
	assert(app.start_battle("cindrel", 4))
	battle = app.battle
	battle.set_process(false); battle.confirm()
	await capture("10_cindrel_battle")
	assert(battle.submit({"kind": "switch", "index": 2}))
	await capture("11_rillume_back")
	drain()
	battle.state.enemy.hp = 1; battle.display_enemy_hp = 1
	assert(battle.submit({"kind": "move", "move": "quickstep"}))
	drain()
	await capture("12_victory_result")
	battle.confirm()
	app.world.set_physics_process(false)
	assert(app.start_battle("brindlewick", 20))
	battle = app.battle
	battle.set_process(false); battle.confirm()
	assert(battle.submit({"kind": "switch", "index": 1}))
	await capture("13_cindrel_back")
	drain()
	# Wounded-team fixture exercises real defeat resolution, never a fabricated outcome.
	battle.state.party = [battle.state.party[1]]
	battle.state.active = 0; battle.state.party[0].hp = 1
	battle.display_active = 0; battle.display_hp.assign([1])
	battle.state.enemy.moves.assign(["nudge"])
	assert(battle.submit({"kind": "move", "move": "nudge"}))
	drain()
	assert(battle.state.outcome == "defeat")
	await capture("14_defeat_result")
	battle.confirm()
	app.world.set_physics_process(false)
	await capture("15_defeat_town")
	while app.session.party.size() < 4:
		app.session.party.append(Monster.create("fixture_%s" % app.session.party.size(), app.session.catalog.species.brindlewick, 3))
	assert(app.start_battle("rillume", 3))
	battle = app.battle
	battle.set_process(false); battle.confirm()
	battle.state.enemy.hp = 1; battle.display_enemy_hp = 1; battle.state.rng.seed = 1
	assert(battle.submit({"kind": "item", "item": "charm"}))
	drain()
	assert(battle.state.outcome == "capture" and app.session.storage.size() == 1)
	await capture("16_storage_result")
	var sheet := Image.create(384, 536, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.html("20283d"))
	for index in range(3):
		var image := read_image(["brindlewick", "cindrel", "rillume"][index])
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(0, index * 96))
	var effects := read_image("effects")
	sheet.blend_rect(effects, Rect2i(Vector2i.ZERO, effects.get_size()), Vector2i(8, 296))
	var arena := read_image("arena")
	sheet.blit_rect(arena, Rect2i(Vector2i.ZERO, arena.get_size()), Vector2i(8, 400))
	var icons := read_image("icons")
	sheet.blend_rect(icons, Rect2i(Vector2i.ZERO, icons.get_size()), Vector2i(296, 512))
	assert(sheet.save_png(OUTPUT + "/art_sheet.png") == OK)
	sheet.resize(1152, 1608, Image.INTERPOLATE_NEAREST)
	assert(sheet.save_png(OUTPUT + "/art_sheet_3x.png") == OK)
	app.queue_free()
	await process_frame
	print("M3 CAPTURE PASS: 16 native/3x battle/world views and original-art contact sheets")
	quit()
func drain() -> void:
	for index in range(20):
		if app.battle.phase != app.battle.Phase.PRESENT: break
		app.battle.advance(0.6)
func read_image(id: String) -> Image:
	var result := Image.new()
	assert(result.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/m3/" + id + ".png")) == OK)
	return result
func capture(id: String) -> void:
	if app.battle != null:
		app.battle.clock = 0.2
		app.battle.event_clock = 0.2
		app.battle.view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == Vector2i(320, 180))
	assert(image.save_png(OUTPUT + "/" + id + ".png") == OK)
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(image.save_png(OUTPUT + "/" + id + "_3x.png") == OK)
