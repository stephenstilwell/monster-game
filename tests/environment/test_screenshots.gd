extends SceneTree
const Base = preload("res://tools/art/art_recipes.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func load_image(name: String) -> Image:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://artifacts/visual/environment/" + name + ".png"))
	return image
func _initialize() -> void:
	var palette: Array = []
	for c: Color in Base.new().palette: palette.append(c.to_rgba32())
	var views := {"town_game": [320, 180, 3], "town_before": [512, 384, 2], "town_after": [512, 384, 2], "route_0": [512, 320, 2], "route_1": [512, 320, 2], "route_2": [512, 320, 2], "asset_sheet": [384, 304, 3], "animation_contact": [768, 192, 2]}
	for id: String in views:
		var spec: Array = views[id]
		var image := load_image(id + "_native")
		var scaled := load_image(id + "_%sx" % spec[2])
		check(image.get_size() == Vector2i(spec[0], spec[1]), "native dimensions " + id)
		var valid := true
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				if color.a != 0.0 and (color.a != 1.0 or not color.to_rgba32() in palette): valid = false
		check(valid, "screenshot palette " + id)
		image.resize(spec[0] * spec[2], spec[1] * spec[2], Image.INTERPOLATE_NEAREST)
		check(image.get_data() == scaled.get_data(), "exact nearest scaling " + id)
	check(load_image("town_before_native").get_data() != load_image("town_after_native").get_data(), "actual town presentation changes")
	var frames: Dictionary = {}
	for index in range(8):
		var image := load_image("wind_%02d" % index)
		check(image.get_size() == Vector2i(576, 288), "animation sample dimensions")
		frames[image.get_data().hex_encode().sha256_text()] = true
	check(frames.size() >= 4, "rendered playback actually animates")
	print("ENVIRONMENT SCREENSHOT %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
