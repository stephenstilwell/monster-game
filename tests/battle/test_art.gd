extends SceneTree
const Pipeline = preload("res://tools/art/battle_pipeline.gd")
const Hash = preload("res://tools/art/asset_pipeline.gd")
var checks: int = 0
var failed: bool = false
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failed = true; push_error(label)
func _initialize() -> void:
	var a := "res://.godot/m3_validation/a"
	var b := "res://.godot/m3_validation/b"
	check(not Pipeline.generate(a + "/assets", a + "/data").has("error"), "Clean art/data build A")
	check(not Pipeline.generate(b + "/assets", b + "/data").has("error"), "Clean art/data build B")
	var text := FileAccess.get_file_as_string(a + "/assets/manifest.json")
	check(text == FileAccess.get_file_as_string(b + "/assets/manifest.json") and text == FileAccess.get_file_as_string("res://assets/generated/m3/manifest.json"), "Deterministic persisted manifest")
	var manifest: Dictionary = JSON.parse_string(text)
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	var palette: Array[Color] = []
	for hex: String in base.palette: palette.append(Color.html(hex))
	var images := {}
	for id: String in manifest.assets:
		var bytes := FileAccess.get_file_as_bytes(a + "/assets/" + id + ".png")
		check(bytes == FileAccess.get_file_as_bytes(b + "/assets/" + id + ".png") and bytes == FileAccess.get_file_as_bytes("res://assets/generated/m3/" + id + ".png"), "Reproducible PNG " + id)
		var image := Image.new()
		check(image.load_png_from_buffer(bytes) == OK, "Valid PNG " + id)
		images[id] = image
		check(Hash.digest(image.get_data()) == manifest.assets[id].pixel_sha256, "Pixel digest " + id)
		var size: Array = manifest.assets[id].size
		check(image.get_size() == Vector2i(int(size[0]), int(size[1])), "Asset dimensions " + id)
		var invalid := false
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				if color.a != 0 and (color.a != 1 or not color in palette): invalid = true
		check(not invalid, "Opaque palette or transparent " + id)
	for name: String in manifest.animations:
		var spec: Dictionary = manifest.animations[name]
		var image: Image = images[spec.asset]
		var frames: SpriteFrames = load("res://assets/generated/m3/" + spec.asset + "_frames.tres")
		check(frames.has_animation(name) and frames.get_frame_count(name) == 4 and frames.get_animation_speed(name) == spec.fps, "Reusable animation " + name)
		for index in range(4):
			var r: Array = spec.rects[index]
			var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
			check(Rect2i(Vector2i.ZERO, image.get_size()).encloses(rect) and not image.get_region(rect).is_invisible(), "Populated bounded frame " + name)
			check(Rect2i(Vector2i.ZERO, rect.size).has_point(Vector2i(int(spec.anchor[0]), int(spec.anchor[1]))), "Anchor " + name)
			check(Rect2i(frames.get_frame_texture(name, index).region) == rect, "Atlas reference " + name)
	for id in ["brindlewick", "cindrel", "rillume"]:
		check(images[id].get_region(Rect2i(0, 0, 48, 48)).get_data() != images[id].get_region(Rect2i(0, 48, 48, 48)).get_data(), "Distinct front/back " + id)
	for entry: Array in [["species", ["brindlewick", "cindrel", "rillume"]], ["moves", ["nudge", "leaf_arc", "cinder", "rill", "quickstep"]], ["items", ["charm", "balm"]]]:
		for id: String in entry[1]:
			var suffix: String = "/data/" + entry[0] + "/" + id + ".tres"
			check(FileAccess.get_file_as_bytes(a + suffix) == FileAccess.get_file_as_bytes(b + suffix) and FileAccess.get_file_as_bytes(a + suffix) == FileAccess.get_file_as_bytes("res://data/" + entry[0] + "/" + id + ".tres"), "Reproducible definition " + id)
	print("M3 ART %s: %s assertions for deterministic sprites/data, palette, frames, anchors and resource references" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
