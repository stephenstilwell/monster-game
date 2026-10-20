extends SceneTree
const Base = preload("res://tools/art/art_recipes.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func read_png(path: String) -> Image:
	var image := Image.new()
	check(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK, "PNG decoded")
	return image
func exact_palette(im: Image) -> bool:
	var palette: Array = Base.new().palette
	for y in range(im.get_height()):
		for x in range(im.get_width()):
			if not im.get_pixel(x, y) in palette: return false
	return true
func _initialize() -> void:
	var names: Array = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/visual/m5/views.json"))
	var sheet := Image.create(1280, ceili(names.size() / 4.0) * 180, false, Image.FORMAT_RGBA8)
	for index in range(names.size()):
		var name: String = names[index]
		var native := read_png("res://artifacts/visual/m5/" + name + "_native.png")
		var scaled := read_png("res://artifacts/visual/m5/" + name + "_3x.png")
		check(native.get_size() == Vector2i(320, 180) and scaled.get_size() == Vector2i(960, 540), "dimensions " + name)
		check(exact_palette(native), "palette " + name)
		sheet.blit_rect(native, Rect2i(0, 0, 320, 180), Vector2i((index % 4) * 320, (index / 4) * 180))
		native.resize(960, 540, Image.INTERPOLATE_NEAREST)
		check(native.get_data() == scaled.get_data(), "nearest 3x " + name)
	sheet.save_png("res://artifacts/visual/m5/contact_sheet.png")
	for i in range(3):
		var native := read_png("res://artifacts/visual/m5/map_%s_native.png" % i)
		var scaled := read_png("res://artifacts/visual/m5/map_%s_2x.png" % i)
		check(native.get_size() == Vector2i(512, 320) and scaled.get_size() == Vector2i(1024, 640), "map dimensions")
		check(exact_palette(native), "map palette")
		native.resize(1024, 640, Image.INTERPOLATE_NEAREST)
		check(native.get_data() == scaled.get_data(), "map nearest 2x")
	var art := read_png("res://artifacts/visual/m5/assets_native.png")
	var scaled_art := read_png("res://artifacts/visual/m5/assets_3x.png")
	check(art.get_size() == Vector2i(384, 400) and scaled_art.get_size() == Vector2i(1152, 1200), "art sheet dimensions")
	check(exact_palette(art), "art sheet palette")
	art.resize(1152, 1200, Image.INTERPOLATE_NEAREST)
	check(art.get_data() == scaled_art.get_data(), "art sheet nearest 3x")
	print("M5 SCREENSHOT PASS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)