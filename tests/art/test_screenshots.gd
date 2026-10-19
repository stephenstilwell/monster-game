extends SceneTree
const Recipes = preload("res://tools/art/art_recipes.gd")
var checks: int = 0
var failed: bool = false

func _initialize() -> void:
	var palette: Array[Color] = []
	for hex: String in Recipes.HEX:
		palette.append(Color.html(hex))
	for name: String in ["1_field", "2_creature", "3_battle", "4_party", "5_moss_variant", "6_reaction"]:
		var native := Image.new()
		var native_error := native.load_png_from_buffer(FileAccess.get_file_as_bytes("res://artifacts/visual/" + name + ".png"))
		var scaled := Image.new()
		var scaled_error := scaled.load_png_from_buffer(FileAccess.get_file_as_bytes("res://artifacts/visual/" + name + "_3x.png"))
		if native_error != OK or scaled_error != OK:
			push_error("Missing capture: " + name)
			failed = true
			continue
		var invalid := {}
		for y in range(native.get_height()):
			for x in range(native.get_width()):
				var color := native.get_pixel(x, y)
				if not color in palette:
					invalid[color.to_html()] = true
		checks += 1
		if not invalid.is_empty():
			push_error("Off-palette screen pixels in %s: %s" % [name, invalid.keys()])
			failed = true
		checks += 1
		if native.get_size() != Vector2i(320, 180) or scaled.get_size() != Vector2i(960, 540):
			push_error("Wrong capture dimensions: " + name)
			failed = true
		native.resize(960, 540, Image.INTERPOLATE_NEAREST)
		checks += 1
		if native.get_data() != scaled.get_data():
			push_error("Noninteger scaling: " + name)
			failed = true
	print("SCREENSHOT %s: %s checks for palette, dimensions and exact nearest 3x scaling" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
