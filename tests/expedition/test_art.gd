extends SceneTree
const Recipes = preload("res://tools/art/expedition_recipes.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const Base = preload("res://tools/art/art_recipes.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func raw_image(path: String) -> Image:
	var im := Image.new()
	check(im.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK, "decode PNG")
	return im
func _initialize() -> void:
	var output := "res://.godot/m5_validation/art_" + str(Time.get_ticks_usec())
	var first := Recipes.generate(output + "/a")
	var second := Recipes.generate(output + "/b")
	check(first == second and not first.has("error"), "two deterministic manifests")
	check(FileAccess.get_file_as_string(output + "/a/manifest.json") == FileAccess.get_file_as_string("res://assets/generated/m5/manifest.json"), "persisted manifest matches recipes")
	var palette: Array = Base.new().palette
	for id: String in first.assets:
		var a := raw_image(output + "/a/" + id + ".png")
		var saved := raw_image("res://assets/generated/m5/" + id + ".png")
		check(a.get_data() == saved.get_data(), "persisted pixels " + id)
		check(FileAccess.get_file_as_bytes(output + "/a/" + id + ".png") == FileAccess.get_file_as_bytes(output + "/b/" + id + ".png"), "byte-identical PNG " + id)
		check(Pipeline.digest(a.get_data()) == first.assets[id].sha256 and [a.get_width(), a.get_height()] == first.assets[id].size, "digest and dimensions " + id)
		var exact := true
		for y in range(a.get_height()):
			for x in range(a.get_width()):
				var c := a.get_pixel(x, y)
				exact = exact and (c.a == 0.0 or (c.a == 1.0 and c in palette))
		check(exact, "palette/hard alpha " + id)
	for id: String in first.regions:
		var s: Dictionary = first.regions[id]
		var r: Array = s.rect
		var im := raw_image("res://assets/generated/m5/" + s.asset + ".png")
		check(Rect2i(0, 0, im.get_width(), im.get_height()).encloses(Rect2i(r[0], r[1], r[2], r[3])), "region bounds " + id)
		check(not im.get_region(Rect2i(r[0], r[1], r[2], r[3])).is_invisible(), "region populated " + id)
		check(s.anchor[0] >= 0 and s.anchor[0] < r[2] and s.anchor[1] >= 0 and s.anchor[1] < r[3], "anchor " + id)
	for i in range(3):
		var name := "/template_%s.tres" % i
		check(FileAccess.get_file_as_bytes(output + "/a" + name) == FileAccess.get_file_as_bytes(output + "/b" + name) and FileAccess.get_file_as_bytes(output + "/a" + name) == FileAccess.get_file_as_bytes("res://assets/generated/m5" + name), "stable baked map template")
	var frames: SpriteFrames = load("res://assets/generated/m5/guardian_frames.tres")
	for id: String in first.animations:
		var animation := "guardian_front_idle" if id == "guardian_idle" else "guardian_front_react" if id == "guardian_react" else "guardian_entry"
		check(frames.has_animation(animation) and frames.get_frame_count(animation) == 4, "persisted animation " + id)
		check(frames.get_animation_speed(animation) == first.animations[id].fps, "animation timing " + id)
		for i in range(4):
			var texture: AtlasTexture = frames.get_frame_texture(animation, i)
			check(texture.region.end.x <= texture.atlas.get_width() and texture.region.end.y <= texture.atlas.get_height(), "animation atlas bounds")
	print("M5 ART PASS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)