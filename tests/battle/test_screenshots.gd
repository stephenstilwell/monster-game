extends SceneTree
var failed: bool = false
var checks: int = 0
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	var palette: Array[Color] = []
	for hex: String in manifest.palette: palette.append(Color.html(hex))
	var directory := DirAccess.open("res://artifacts/visual/m3")
	var count := 0
	for name: String in directory.get_files():
		if not name.ends_with(".png") or name.ends_with("_3x.png"): continue
		count += 1
		var im := Image.new()
		var enlarged := Image.new()
		var path := "res://artifacts/visual/m3/" + name
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or enlarged.load_png_from_buffer(FileAccess.get_file_as_bytes(path.trim_suffix(".png") + "_3x.png")) != OK:
			verify(false, "Missing capture pair " + name); continue
		verify(im.get_size() == (Vector2i(384, 536) if name == "art_sheet.png" else Vector2i(320, 180)), "Native dimensions " + name)
		var invalid := false
		for y in range(im.get_height()):
			for x in range(im.get_width()):
				if not im.get_pixel(x, y) in palette: invalid = true
		verify(not invalid, "Exact shared palette " + name)
		im.resize(im.get_width() * 3, im.get_height() * 3, Image.INTERPOLATE_NEAREST)
		verify(im.get_size() == enlarged.get_size() and im.get_data() == enlarged.get_data(), "Exact nearest 3x " + name)
	verify(count == 17, "All 16 views and art sheet are present")
	print("M3 SCREENSHOT %s: %s palette/dimension/scaling assertions" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
func verify(value: bool, label: String) -> void:
	checks += 1
	if not value: failed = true; push_error(label)
