extends SceneTree
var checks: int = 0
var failed: bool = false
const OUTPUT := "res://artifacts/visual/m2/"
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	var palette: Array[Color] = []
	for hex: String in manifest.palette:
		palette.append(Color.html(hex))
	var captures := {"town_entry": Vector2i(320, 180), "mara_dialogue": Vector2i(320, 180), "forest_entry": Vector2i(320, 180), "ivo_dialogue": Vector2i(320, 180), "bridge_crossing": Vector2i(320, 180), "old_waystation": Vector2i(320, 180), "return_town": Vector2i(320, 180), "walking": Vector2i(320, 180), "town_overview": Vector2i(512, 384), "forest_overview": Vector2i(576, 448), "npc_props": Vector2i(200, 168)}
	for id: String in captures:
		var image := Image.new()
		var scale: int = 2 if id.ends_with("overview") else 3
		var enlarged := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(OUTPUT + id + ".png")) != OK or enlarged.load_png_from_buffer(FileAccess.get_file_as_bytes(OUTPUT + id + "_%sx.png" % scale)) != OK:
			push_error("Missing/invalid screenshot: " + id)
			failed = true
			continue
		verify(image.get_size() == captures[id], "Native dimensions " + id)
		var invalid := false
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				if not image.get_pixel(x, y) in palette:
					invalid = true
		verify(not invalid, "Rendered palette " + id)
		image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
		verify(image.get_size() == enlarged.get_size() and image.get_data() == enlarged.get_data(), "Exact integer scaling " + id)
	print("M2 SCREENSHOT %s: %s dimension/palette/scaling checks" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)
