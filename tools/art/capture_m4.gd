extends SceneTree
const App = preload("res://scenes/app/game.tscn")
const Monster = preload("res://scripts/monsters/monster_state.gd")
var app: Node
var captures: int = 0
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	app.field_menu.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == Vector2i(320, 180))
	assert(image.save_png("res://artifacts/visual/m4/" + name + "_native.png") == OK)
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(image.save_png("res://artifacts/visual/m4/" + name + "_3x.png") == OK)
	captures += 1
func run() -> void:
	app = App.instantiate()
	root.add_child(app)
	app.world.set_physics_process(false)
	app.saves.directory = "res://.godot/m4_validation/capture_slot"
	while app.session.party.size() < 4:
		var i: int = app.session.party.size()
		app.session.party.append(Monster.create("sample_" + str(i), app.session.catalog.species[["rillume", "brindlewick"][i - 2]], 6 + i))
	app.session.party[0].hp = 13
	for i in range(7): app.session.storage.append(Monster.create("stored_" + str(i), app.session.catalog.species[["rillume", "cindrel", "brindlewick"][i % 3]], 3 + i))
	assert(app.open_menu())
	await capture("party")
	app.field_menu.selected = 1
	await capture("party_cindrel")
	app.field_menu.selected = 2
	await capture("party_rillume")
	app.field_menu.confirm()
	await capture("party_actions")
	app.field_menu.mode = "list"
	app.field_menu.page = 1
	app.field_menu.selected = 5
	app.field_menu.message = ""
	await capture("storage_paged")
	app.field_menu.confirm()
	await capture("storage_exchange")
	app.field_menu.page = 2
	app.field_menu.selected = 0
	app.field_menu.message = ""
	await capture("bag_charm")
	app.field_menu.selected = 1
	await capture("bag_balm")
	app.field_menu.confirm()
	await capture("balm_target")
	app.field_menu.selected = 0
	app.field_menu.confirm()
	await capture("balm_used")
	app.field_menu.page = 3
	app.field_menu.selected = 0
	app.field_menu.message = ""
	await capture("rest")
	app.field_menu.confirm()
	await capture("rested")
	app.field_menu.page = 4
	app.field_menu.message = ""
	app.field_menu.confirm()
	await capture("settings")
	app.field_menu.page = 5
	app.field_menu.selected = 0
	app.field_menu.confirm()
	await capture("saved")
	app.field_menu.selected = 1
	app.field_menu.confirm()
	await capture("load_confirm")
	app.field_menu.selected = 1
	app.field_menu.confirm()
	await capture("loaded")
	app.close_menu()
	app.world.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://artifacts/visual/m4/world_native.png")
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	image.save_png("res://artifacts/visual/m4/world_3x.png")
	app.queue_free()
	await process_frame
	print("M4 CAPTURE PASS: %s menu views plus world, native and 3x" % captures)
	quit()
