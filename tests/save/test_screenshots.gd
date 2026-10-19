extends SceneTree
const Base = preload("res://tools/art/art_recipes.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func read_png(path: String) -> Image:
	var image := Image.new()
	assert(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK)
	return image
func _initialize() -> void:
	var names := ["party", "party_cindrel", "party_rillume", "party_actions", "storage_paged", "storage_exchange", "bag_charm", "bag_balm", "balm_target", "balm_used", "rest", "rested", "settings", "saved", "load_confirm", "loaded", "world"]
	var palette: Array = Base.new().palette
	var sheet := Image.create(1280, 900, false, Image.FORMAT_RGBA8)
	for index in range(names.size()):
		var name: String = names[index]
		var native := read_png("res://artifacts/visual/m4/" + name + "_native.png")
		var scaled := read_png("res://artifacts/visual/m4/" + name + "_3x.png")
		check(native.get_size() == Vector2i(320, 180) and scaled.get_size() == Vector2i(960, 540), "dimensions " + name)
		var valid := true
		for y in range(native.get_height()):
			for x in range(native.get_width()):
				valid = valid and native.get_pixel(x, y) in palette
		check(valid, "palette " + name)
		sheet.blit_rect(native, Rect2i(0, 0, 320, 180), Vector2i((index % 4) * 320, (index / 4) * 180))
		native.resize(960, 540, Image.INTERPOLATE_NEAREST)
		check(native.get_data() == scaled.get_data(), "nearest 3x " + name)
	sheet.save_png("res://artifacts/visual/m4/contact_sheet.png")
	print("M4 SCREENSHOT PASS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)
