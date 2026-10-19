extends SceneTree
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const Recipes = preload("res://tools/art/art_recipes.gd")
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func rect_from(values: Array) -> Rect2i:
	return Rect2i(int(values[0]), int(values[1]), int(values[2]), int(values[3]))

func read_manifest(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path.path_join("manifest.json")))

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var a := "res://.godot/m1_validation/a"
	var b := "res://.godot/m1_validation/b"
	check(not Pipeline.generate(a).has("error"), "Clean build A succeeds")
	check(not Pipeline.generate(b).has("error"), "Clean build B succeeds")
	var manifest := read_manifest(a)
	check(FileAccess.get_file_as_string(a.path_join("manifest.json")) == FileAccess.get_file_as_string(b.path_join("manifest.json")), "Two clean manifests match byte-for-byte")
	check(manifest == read_manifest("res://assets/generated"), "Committed manifest matches clean generation")
	check(FileAccess.get_file_as_string(a.path_join("lanternwild.fnt")) == FileAccess.get_file_as_string(b.path_join("lanternwild.fnt")), "Font descriptors match")
	check(manifest.assets.size() == 8 and manifest.animations.size() == 15 and manifest.tiles.size() == 32, "Required asset groups are complete")
	var images := {}
	var allowed: Array[Color] = []
	for hex: String in Recipes.HEX:
		allowed.append(Color.html(hex))
	for id: String in manifest.assets:
		var filename: String = manifest.assets[id].file
		var bytes_a := FileAccess.get_file_as_bytes(a.path_join(filename))
		check(bytes_a == FileAccess.get_file_as_bytes(b.path_join(filename)), "Clean PNG bytes match: " + id)
		check(bytes_a == FileAccess.get_file_as_bytes("res://assets/generated/" + filename), "Persisted PNG matches recipe: " + id)
		var im := Image.new()
		check(im.load_png_from_buffer(bytes_a) == OK, "PNG decodes: " + id)
		images[id] = im
		var size: Array = manifest.assets[id].size
		check(im.get_size() == Vector2i(int(size[0]), int(size[1])), "Manifest dimensions: " + id)
		check(Pipeline.digest(im.get_data()) == manifest.assets[id].pixel_sha256, "Pixel digest: " + id)
		var invalid_pixels := 0
		for y in range(im.get_height()):
			for x in range(im.get_width()):
				var color := im.get_pixel(x, y)
				if color.a != 0.0 and (color.a != 1.0 or (color != Color.WHITE if id == "font" else not color in allowed)):
					invalid_pixels += 1
		check(invalid_pixels == 0, "Palette/alpha constraint: " + id)
	for id: String in manifest.animations:
		var spec: Dictionary = manifest.animations[id]
		var image: Image = images[spec.asset]
		var bounds := Rect2i(Vector2i.ZERO, image.get_size())
		check(spec.fps > 0, "Positive animation speed: " + id)
		var resource: SpriteFrames = load("res://assets/generated/" + spec.asset + "_frames.tres")
		check(resource != null and resource.has_animation(id), "Animation resource: " + id)
		check(resource.get_frame_count(id) == spec.rects.size(), "Frame count: " + id)
		check(is_equal_approx(resource.get_animation_speed(id), spec.fps), "Resource speed: " + id)
		for index in range(spec.rects.size()):
			var rect := rect_from(spec.rects[index])
			check(bounds.encloses(rect), "Frame is within atlas: " + id)
			check(Rect2i(Vector2i.ZERO, rect.size).has_point(Vector2i(int(spec.anchor[0]), int(spec.anchor[1]))), "Anchor within frame: " + id)
			check(not image.get_region(rect).is_invisible(), "Frame is populated: " + id)
			var atlas_texture: AtlasTexture = resource.get_frame_texture(id, index)
			check(Rect2i(atlas_texture.region) == rect, "Resource rectangle matches manifest: " + id)
		if spec.asset == "player":
			for values: Array in spec.rects:
				var rect := rect_from(values)
				check(image.get_pixel(rect.position.x + 8, rect.position.y + 23) == allowed[1], "Stable player foot/shadow anchor: " + id)
	var player: Image = images.player
	check(player.get_region(Rect2i(0, 0, 16, 24)).get_data() != player.get_region(Rect2i(0, 24, 16, 24)).get_data(), "North and south differ")
	check(player.get_region(Rect2i(0, 48, 16, 24)).get_data() != player.get_region(Rect2i(0, 72, 16, 24)).get_data(), "East and west differ")
	check(player.get_region(Rect2i(16, 0, 16, 24)).get_data() != player.get_region(Rect2i(48, 0, 16, 24)).get_data(), "Walk cycle changes articulated feet")
	var monster: Image = images.brindlewick
	check(monster.get_region(Rect2i(0, 0, 48, 48)).get_data() != monster.get_region(Rect2i(0, 48, 48, 48)).get_data(), "Moss variant is distinct")
	for id: String in manifest.regions:
		var spec: Dictionary = manifest.regions[id]
		var image: Image = images[spec.asset]
		var rect := rect_from(spec.rect)
		check(Rect2i(Vector2i.ZERO, image.get_size()).encloses(rect) and not image.get_region(rect).is_invisible(), "Named region valid: " + id)
	var tileset: TileSet = load("res://assets/generated/woodland_tileset.tres")
	var source: TileSetAtlasSource = tileset.get_source(0)
	check(source.get_tiles_count() == 32, "Reusable TileSet has all tiles")
	for spec: Dictionary in manifest.tiles:
		var coords := Vector2i(int(spec.id) % 8, int(spec.id) / 8)
		var tile := source.get_tile_data(coords, 0)
		check(tile.get_custom_data("terrain_id") == spec.terrain and tile.get_custom_data("encounter") == spec.encounter, "Tile metadata: %s" % spec.id)
		check((tile.get_collision_polygons_count(0) > 0) == spec.collision, "Tile collision: %s" % spec.id)
		if spec.id >= 8 and spec.id < 24:
			check(tile.get_custom_data("exposed_edges_nesw") == int(spec.id) - 8, "All bank adjacency masks: %s" % spec.id)
	var theme: Theme = load("res://assets/generated/woodland_theme.tres")
	check(theme.default_font != null and theme.has_stylebox("panel", "Panel"), "Reusable font/theme")
	for character: String in manifest.glyphs:
		check(theme.default_font.has_char(character.unicode_at(0)), "Bitmap font contains " + character)
	await test_controls()
	if failures.is_empty():
		print("ART/SHOWCASE PASS: %s checks; two clean builds, persisted outputs, palette/mask, frames/anchors, TileSet/font, input/state" % checks)
		quit()
	else:
		print("FAIL: %s / %s checks" % [failures.size(), checks])
		quit(1)

func key(view: Node, code: Key, shift: bool = false, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.shift_pressed = shift
	event.echo = echo
	view._unhandled_input(event)

func test_controls() -> void:
	var scene: PackedScene = load("res://scenes/showcase/showcase.tscn")
	var view = scene.instantiate()
	root.add_child(view)
	await process_frame
	key(view, KEY_4)
	check(view.page == 3, "Number keys select pages")
	key(view, KEY_TAB)
	check(view.page == 0, "Tab wraps forward")
	key(view, KEY_TAB, true)
	check(view.page == 3, "Shift-tab wraps backward")
	key(view, KEY_TAB, false, true)
	check(view.page == 3, "Held key echo does not repeat")
	key(view, KEY_V)
	check(view.variant == 1, "Variant toggles")
	key(view, KEY_V)
	check(view.variant == 0, "Variant returns")
	for entry: Array in [[KEY_DOWN, 0], [KEY_UP, 1], [KEY_LEFT, 2], [KEY_RIGHT, 3]]:
		key(view, entry[0])
		check(view.facing == entry[1], "Arrow previews facing")
	key(view, KEY_I)
	check(not view.walking, "Idle preview toggles")
	key(view, KEY_R)
	check(view.calm, "Reduced-flashing preview toggles")
	key(view, KEY_SPACE)
	var prior: float = view.clock
	view._process(1.0)
	check(view.clock == prior, "Pause freezes clock")
	key(view, KEY_SPACE)
	view._process(0.125)
	check(is_equal_approx(view.clock, prior + 0.125), "Playback resumes")
	key(view, KEY_A)
	view._process(0.2)
	check(view.reacting, "Reaction holds before completion")
	view._process(0.21)
	check(not view.reacting, "Reaction returns to idle")
	var button := InputEventJoypadButton.new()
	button.pressed = true
	button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	view._unhandled_input(button)
	check(view.page == 0, "Gamepad shoulder wraps pages")
	button.button_index = JOY_BUTTON_A
	view._unhandled_input(button)
	check(view.variant == 1, "Gamepad variant control")
	view.queue_free()
	await process_frame
