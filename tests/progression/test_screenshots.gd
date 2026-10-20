extends SceneTree
const Base = preload("res://tools/art/art_recipes.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func load_image(path: String) -> Image:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return image
func _initialize() -> void:
	var folder := "res://artifacts/visual/m6/"
	var names: Array = JSON.parse_string(FileAccess.get_file_as_string(folder + "views.json"))
	var sheet := Image.create(320 * 4, 180 * ceili(names.size() / 4.0), false, Image.FORMAT_RGBA8)
	sheet.fill(Base.new().palette[0])
	var colors: Array = []
	for color: Color in Base.new().palette: colors.append(color.to_rgba32())
	for i in range(names.size()):
		var name: String = names[i]
		var native := load_image(folder + name + "_native.png")
		var scaled := load_image(folder + name + "_3x.png")
		check(native.get_size() == Vector2i(320, 180), "native " + name)
		check(scaled.get_size() == Vector2i(960, 540), "scaled " + name)
		var valid := true
		for y in range(180):
			for x in range(320):
				if not native.get_pixel(x, y).to_rgba32() in colors: valid = false
		check(valid, "palette " + name)
		var expected := native.duplicate()
		expected.resize(960, 540, Image.INTERPOLATE_NEAREST)
		check(expected.get_data() == scaled.get_data(), "nearest scale " + name)
		sheet.blit_rect(native, Rect2i(0, 0, 320, 180), Vector2i(i % 4 * 320, i / 4 * 180))
	sheet.save_png(folder + "contact_sheet.png")
	for id: String in ["sanctuary_map", "route_0", "route_1", "route_2"]:
		var native := load_image(folder + id + "_native.png")
		var scaled := load_image(folder + id + "_2x.png")
		check(native.get_size() == (Vector2i(512, 384) if id == "sanctuary_map" else Vector2i(512, 320)), "overview dimensions")
		var valid := true
		for y in range(native.get_height()):
			for x in range(native.get_width()):
				if not native.get_pixel(x, y).to_rgba32() in colors: valid = false
		check(valid, "overview palette")
		native.resize(native.get_width() * 2, native.get_height() * 2, Image.INTERPOLATE_NEAREST)
		check(native.get_data() == scaled.get_data(), "overview nearest scaling")
	print("M6 SCREENSHOT %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
