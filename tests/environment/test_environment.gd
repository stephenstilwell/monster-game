extends SceneTree
const Recipes = preload("res://tools/art/environment_recipes.gd")
const Style = preload("res://scripts/world/environment_style.gd")
const Model = preload("res://scripts/progression/expedition_service.gd")
const Base = preload("res://tools/art/art_recipes.gd")
const App = preload("res://scenes/app/game.tscn")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func image(path: String) -> Image:
	var result := Image.new()
	result.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return result
func art() -> void:
	var folder := "res://.godot/environment_validation/art_" + str(Time.get_ticks_usec())
	var first := Recipes.generate(folder + "/a")
	var second := Recipes.generate(folder + "/b")
	check(first == second, "deterministic manifest")
	var palette: Array = []
	for color: Color in Base.new().palette: palette.append(color.to_rgba32())
	for id: String in first.assets:
		var file := folder + "/a/" + id + ".png"
		check(FileAccess.get_file_as_bytes(file) == FileAccess.get_file_as_bytes(folder + "/b/" + id + ".png"), "deterministic pixels " + id)
		var im := image(file)
		check([im.get_width(), im.get_height()] == first.assets[id].size, "atlas dimensions " + id)
		var valid := true
		for y in range(im.get_height()):
			for x in range(im.get_width()):
				var c := im.get_pixel(x, y)
				if c.a != 0.0 and (c.a != 1.0 or not c.to_rgba32() in palette): valid = false
		check(valid, "palette/hard transparency " + id)
	for id: String in first.regions:
		var spec: Dictionary = first.regions[id]
		var size: Array = first.assets[spec.asset].size
		check(spec.rect[0] + spec.rect[2] * spec.frames <= size[0] and spec.rect[1] + spec.rect[3] <= size[1], "animation region bounds " + id)
	var silhouettes: Dictionary = {}
	for variant in range(6):
		var base := Recipes.tree(variant, 0)
		silhouettes[base.get_data().hex_encode().sha256_text()] = true
		for frame in range(4):
			var pose := Recipes.tree(variant, frame)
			check(base.get_region(Rect2i(0, 52, 48, 12)).get_data() == pose.get_region(Rect2i(0, 52, 48, 12)).get_data(), "stable roots/trunk")
		check(base.get_data() != Recipes.tree(variant, 1).get_data(), "tree has actual wind poses")
	check(silhouettes.size() == 6, "six unique trees")
	for variant in range(4):
		var base := Recipes.flowers(variant, 0)
		check(base.get_region(Rect2i(0, 13, 24, 3)).get_data() == Recipes.flowers(variant, 1).get_region(Rect2i(0, 13, 24, 3)).get_data(), "flower roots pinned")
		check(base.get_data() != Recipes.flowers(variant, 1).get_data(), "flower pose moves")
func maps_and_state() -> void:
	var style := Style.new()
	var maps: Array = [preload("res://scripts/expedition/route_generator.gd").hub()]
	for seed_value in range(16):
		var d := Model.fresh()
		Model.depart(d, 0, seed_value)
		Model.choose_route(d, 0)
		maps.append(Model.map_for(d.run))
	for map: Resource in maps:
		var tiles: PackedInt32Array = map.tiles.duplicate()
		var props: Array = map.props.duplicate(true)
		var blocked: Array = map.blocked_cells.duplicate()
		var seed_value := Style.map_seed(map)
		var seen: Dictionary = {}
		var houses: Dictionary = {}
		var ordinal := 0
		var regions := {}
		for folder: String in ["res://assets/generated", "res://assets/generated/m2", "res://assets/generated/m5", "res://assets/generated/m6"]:
			var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "/manifest.json"))
			regions.merge(manifest.regions)
		for prop: Dictionary in props:
			var id := style.variant(prop, map, ordinal, seed_value)
			check(id == style.variant(prop, map, ordinal, seed_value), "stable variant selection")
			if prop.region == "tree": seen[id] = true
			if prop.region == "waystation": houses[id] = true; ordinal += 1
		check(seen.size() >= 4, "map mixes at least four tree silhouettes")
		if map.id == "town": check(houses.size() == 2, "town lodges differ")
		var additions := style.scatter(map, regions, seed_value)
		check(additions == style.scatter(map, regions, seed_value), "deterministic ground placement")
		for prop: Dictionary in additions:
			check(map.tile_at(prop.origin) in [0, 1] and map.can_enter(prop.origin), "dressing only on traversable grass")
		check(map.tiles == tiles and map.props == props and map.blocked_cells == blocked, "presentation does not mutate map or collision")
	var sprite := style.sprite("tree_0", Vector2(3, 4), 0)
	sprite.set_process(false)
	var at := sprite.position
	var anchor := sprite.offset
	var frames: Dictionary = {}
	for index in range(24):
		sprite.synchronize(index * 0.6)
		frames[sprite.current_pose] = true
		check(sprite.position == at and sprite.offset == anchor, "animation never shifts world anchor")
	check(frames.size() == 4, "wind cycle visits all poses")
	sprite.free()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	art()
	maps_and_state()
	var app := App.instantiate()
	app.saves.directory = "res://.godot/environment_validation/app_" + str(Time.get_ticks_usec())
	root.add_child(app)
	app.world.set_physics_process(false)
	check(app.world.environment_polish and app.world.environment_style != null, "actual default app enables polish")
	var animated: Array = []
	for object: Node in app.world.objects.get_children():
		if object.has_method("synchronize") and object.frame_count > 1: animated.append(object)
	check(animated.size() > 10, "actual map contains animated scenery")
	var target: Node = animated[0]
	var before: float = target.elapsed
	await create_timer(0.1).timeout
	check(target.elapsed > before, "idle exploration advances ambient animation")
	app.world.visible = false
	before = target.elapsed
	await create_timer(0.1).timeout
	check(target.elapsed == before, "hidden world pauses ambient processing")
	app.queue_free()
	await process_frame
	print("ENVIRONMENT TEST %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
