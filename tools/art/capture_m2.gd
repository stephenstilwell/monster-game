extends SceneTree
const Scene = preload("res://scenes/world/exploration.tscn")
var world: Node2D
const OUTPUT := "res://artifacts/visual/m2"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	world = Scene.instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	await process_frame
	await capture("town_entry")
	place("town", Vector2i(13, 12), Vector2i.UP)
	assert(world.interact())
	await capture("mara_dialogue")
	place("forest", Vector2i(2, 14), Vector2i.RIGHT)
	await capture("forest_entry")
	place("forest", Vector2i(12, 14), Vector2i.UP)
	assert(world.interact())
	await capture("ivo_dialogue")
	place("forest", Vector2i(21, 6), Vector2i.RIGHT)
	await capture("bridge_crossing")
	place("forest", Vector2i(27, 22), Vector2i.UP)
	assert(world.interact())
	await capture("old_waystation")
	place("town", Vector2i(29, 12), Vector2i.LEFT)
	await capture("return_town")
	place("town", Vector2i(10, 12), Vector2i.RIGHT)
	assert(world.movement.try_step(Vector2i.RIGHT, world.current_map.can_enter))
	world.movement.advance(0.08)
	world._sync_visuals()
	await capture("walking")
	for id in ["town", "forest"]:
		await overview(id)
	var sheet := Image.create(200, 168, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.html("20283d"))
	for entry: Array in [["mara", Vector2i(8, 8)], ["ivo", Vector2i(104, 8)], ["props", Vector2i(8, 112)], ["route_tiles", Vector2i(120, 120)]]:
		var image := Image.new()
		assert(image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/m2/" + entry[0] + ".png")) == OK)
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), entry[1])
	assert(sheet.save_png(OUTPUT + "/npc_props.png") == OK)
	sheet.resize(600, 504, Image.INTERPOLATE_NEAREST)
	assert(sheet.save_png(OUTPUT + "/npc_props_3x.png") == OK)
	world.queue_free()
	await process_frame
	print("M2 CAPTURE PASS: 8 native/3x exploration views, 2 full-map overviews at 1x/2x, NPC/prop contact sheets")
	quit()

func place(id: String, cell: Vector2i, facing: Vector2i) -> void:
	world.mode = world.Mode.EXPLORE
	world.dialogue.close()
	world.movement.locked = false
	world._mount_map(id, cell)
	world.movement.facing = facing
	world._sync_visuals()
	world.camera.force_update_scroll()

func capture(id: String) -> void:
	# Hold a deterministic presentation pose while sampling the real rendered scene.
	world.player.get_node("Sprite").pause()
	world.player.get_node("Sprite").frame = 1 if world.movement.moving else 0
	world.hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == Vector2i(320, 180))
	assert(image.save_png(OUTPUT + "/" + id + ".png") == OK)
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(image.save_png(OUTPUT + "/" + id + "_3x.png") == OK)

func overview(id: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = world.maps[id].size * 16
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var map_view := Scene.instantiate()
	viewport.add_child(map_view)
	map_view.set_physics_process(false)
	map_view._mount_map(id, map_view.maps[id].start)
	map_view.camera.enabled = false
	map_view.get_node("HUD").visible = false
	viewport.canvas_transform = Transform2D.IDENTITY
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	assert(image.save_png(OUTPUT + "/" + id + "_overview.png") == OK)
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	assert(image.save_png(OUTPUT + "/" + id + "_overview_2x.png") == OK)
	viewport.queue_free()
	await process_frame
