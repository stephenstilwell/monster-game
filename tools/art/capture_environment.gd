extends SceneTree
const App = preload("res://scenes/app/game.tscn")
const World = preload("res://scenes/world/exploration.tscn")
const Model = preload("res://scripts/progression/expedition_service.gd")
const Base = preload("res://tools/art/art_recipes.gd")
var app: Node
func _initialize() -> void: run.call_deferred()
func freeze(world: Node, time: float) -> void:
	for object: Node in world.objects.get_children():
		if object.has_method("synchronize"):
			object.set_process(false)
			object.synchronize(time)
func save_image(im: Image, name: String, scale_factor: int) -> void:
	assert(im.save_png("res://artifacts/visual/environment/" + name + "_native.png") == OK)
	im.resize(im.get_width() * scale_factor, im.get_height() * scale_factor, Image.INTERPOLATE_NEAREST)
	assert(im.save_png("res://artifacts/visual/environment/" + name + "_%sx.png" % scale_factor) == OK)
func overview(map: Resource, name: String, polished: bool) -> void:
	var view := SubViewport.new()
	view.size = map.size * 16
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world := World.instantiate()
	world.environment_polish = polished
	view.add_child(world)
	world.regions.merge(app.world.regions)
	world.set_physics_process(false)
	world.get_node("HUD").visible = false
	world.maps[map.id] = map
	world._mount_map(map.id, map.start)
	world.camera.enabled = false
	freeze(world, 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	save_image(view.get_texture().get_image(), name, 2)
	view.queue_free()
	await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/visual/environment")
	app = App.instantiate()
	app.saves.directory = "res://.godot/environment_validation/capture_" + str(Time.get_ticks_usec())
	root.add_child(app)
	app.world.set_physics_process(false)
	freeze(app.world, 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	save_image(root.get_texture().get_image(), "town_game", 3)
	await overview(app.world.maps.town, "town_before", false)
	await overview(app.world.maps.town, "town_after", true)
	for template in range(3):
		var d := Model.fresh()
		Model.depart(d, 0, 20)
		Model.choose_route(d, 0)
		d.run.options[0][0].template = template
		await overview(Model.map_for(d.run), "route_%s" % template, true)
	# Native-scale contact sheet: all silhouettes and house facades, with flowers/ground.
	var sheet := Image.create(384, 304, false, Image.FORMAT_RGBA8)
	sheet.fill(Base.new().palette[0])
	var trees := Image.new()
	trees.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/environment/trees.png"))
	for variant in range(6):
		for frame in range(4):
			sheet.blend_rect(trees, Rect2i(frame * 48, variant * 64, 48, 64), Vector2i(frame * 48 + (variant % 2) * 192, (variant / 2) * 64))
	var houses := Image.new()
	houses.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/environment/houses.png"))
	sheet.blend_rect(houses, Rect2i(0, 0, 256, 64), Vector2i(0, 192))
	var flowers := Image.new()
	flowers.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/environment/flowers.png"))
	for variant in range(4): sheet.blend_rect(flowers, Rect2i(0, variant * 16, 96, 16), Vector2i(variant * 96, 264))
	var ground := Image.new()
	ground.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/environment/ground.png"))
	sheet.blend_rect(ground, Rect2i(0, 0, 64, 16), Vector2i(0, 288))
	save_image(sheet, "asset_sheet", 3)
	# Render a small looping wind/flower preview through the actual sprite scripts.
	var animation_view := SubViewport.new()
	animation_view.size = Vector2i(192, 96)
	animation_view.world_2d = World2D.new()
	animation_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(animation_view)
	var style := preload("res://scripts/world/environment_style.gd").new()
	var sprites: Array = []
	for i in range(3):
		var sprite: Sprite2D = style.sprite("tree_%s" % i, Vector2(i * 4, 0), i * 19)
		animation_view.add_child(sprite)
		sprite.set_process(false)
		sprites.append(sprite)
		var flower: Sprite2D = style.sprite("flower_%s" % i, Vector2(i * 4 + 1, 4.5), i * 7)
		animation_view.add_child(flower)
		flower.set_process(false)
		sprites.append(flower)
	var playback := Image.create(192 * 4, 96 * 2, false, Image.FORMAT_RGBA8)
	playback.fill(Base.new().palette[0])
	for i in range(8):
		for sprite: Sprite2D in sprites: sprite.synchronize(i * 0.9)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := animation_view.get_texture().get_image()
		playback.blit_rect(image, Rect2i(0, 0, 192, 96), Vector2i(i % 4 * 192, i / 4 * 96))
		var scaled := image.duplicate()
		scaled.resize(576, 288, Image.INTERPOLATE_NEAREST)
		scaled.save_png("res://artifacts/visual/environment/wind_%02d.png" % i)
	save_image(playback, "animation_contact", 2)
	animation_view.queue_free()
	app.queue_free()
	await process_frame
	await process_frame
	print("ENVIRONMENT CAPTURE PASS: actual app, before/after town, three routes, all variants and 8 rendered wind samples")
	quit()
