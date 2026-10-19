extends SceneTree
const Recipes = preload("res://tools/art/management_recipes.gd")
const Base = preload("res://tools/art/art_recipes.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize() -> void:
	var output := "res://.godot/m4_validation/art_" + str(Time.get_ticks_usec())
	var a := Recipes.generate(output + "/a")
	var b := Recipes.generate(output + "/b")
	check(not a.has("error") and a == b, "repeat generation manifest")
	check(FileAccess.get_file_as_string(output + "/a/manifest.json") == FileAccess.get_file_as_string("res://assets/generated/m4/manifest.json"), "baked manifest matches recipe")
	var palette: Array = Base.new().palette
	for id: String in a.assets:
		var im := raw_image(output + "/a/" + id + ".png")
		var baked := raw_image("res://assets/generated/m4/" + id + ".png")
		check(im.get_data() == baked.get_data(), "baked pixels " + id)
		check(FileAccess.get_file_as_bytes(output + "/a/" + id + ".png") == FileAccess.get_file_as_bytes(output + "/b/" + id + ".png"), "deterministic PNG " + id)
		check(Pipeline.digest(im.get_data()) == a.assets[id].sha256, "digest " + id)
		check([im.get_width(), im.get_height()] == a.assets[id].size, "dimensions " + id)
		var valid := true
		for y in range(im.get_height()):
			for x in range(im.get_width()):
				var c := im.get_pixel(x, y)
				valid = valid and (c.a == 0.0 or (c.a == 1.0 and c in palette))
		check(valid, "exact palette and hard alpha " + id)
	for id: String in a.regions:
		var region: Dictionary = a.regions[id]
		var size: Array = a.assets[region.asset].size
		var rect: Array = region.rect
		check(rect[0] >= 0 and rect[1] >= 0 and rect[0] + rect[2] <= size[0] and rect[1] + rect[3] <= size[1], "region bounds " + id)
		var im := raw_image("res://assets/generated/m4/" + region.asset + ".png").get_region(Rect2i(rect[0], rect[1], rect[2], rect[3]))
		check(not im.is_invisible(), "populated region " + id)
	print("M4 ART PASS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)
func raw_image(path: String) -> Image:
	var im := Image.new()
	assert(im.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK)
	return im
