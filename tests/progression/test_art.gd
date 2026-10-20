extends SceneTree
const Recipes = preload("res://tools/art/progression_recipes.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Base = preload("res://tools/art/art_recipes.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func image_at(path: String) -> Image:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return image
func _initialize() -> void:
	var folder := "res://.godot/m6_validation/art_" + str(Time.get_ticks_usec())
	var first := Recipes.generate(folder + "/a")
	var second := Recipes.generate(folder + "/b")
	check(first == second, "metadata repeats")
	var colors: Array = []
	for color: Color in Base.new().palette: colors.append(color.to_rgba32())
	var sheet := Image.create(432, 480, false, Image.FORMAT_RGBA8)
	sheet.fill(Base.new().palette[0])
	var row := 0
	for id: String in first.assets:
		var path := folder + "/a/" + id + ".png"
		check(FileAccess.get_file_as_bytes(path) == FileAccess.get_file_as_bytes(folder + "/b/" + id + ".png"), "PNG repeats " + id)
		var image := image_at(path)
		check([image.get_width(), image.get_height()] == first.assets[id].size, "dimensions " + id)
		var valid := true
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				if color.a != 0.0 and (color.a != 1.0 or not color.to_rgba32() in colors): valid = false
		check(valid, "palette and hard alpha " + id)
		sheet.blit_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()), Vector2i(0, row))
		row += image.get_height()
	for id: String in first.regions:
		var spec: Dictionary = first.regions[id]
		var size: Array = first.assets[spec.asset].size
		var rect: Array = spec.rect
		check(rect[0] >= 0 and rect[1] >= 0 and rect[0] + rect[2] <= size[0] and rect[1] + rect[3] <= size[1], "region bounds " + id)
	for id: String in first.audio:
		var a := FileAccess.get_file_as_bytes(folder + "/a/" + id + ".wav")
		check(a == FileAccess.get_file_as_bytes(folder + "/b/" + id + ".wav"), "PCM repeats " + id)
		check(a.slice(0, 4).get_string_from_ascii() == "RIFF" and a.slice(8, 12).get_string_from_ascii() == "WAVE", "valid WAV " + id)
		check(first.audio[id].peak > 1000 and first.audio[id].peak < 30000 and first.audio[id].rate == 22050, "bounded non-silent audio " + id)
		var stream: AudioStreamWAV = load("res://assets/generated/m6/" + id + ".wav")
		check(stream != null and stream.mix_rate == 22050 and stream.get_length() > 0.1, "imported playback " + id)
	for id: String in Meta.FORMS.values():
		var frames: SpriteFrames = load("res://assets/generated/m6/" + id + "_frames.tres")
		check(frames.get_animation_names().size() == 4, "four animations " + id)
		for name: String in frames.get_animation_names():
			check(frames.get_frame_count(name) == 4 and frames.get_animation_speed(name) == (10 if name.ends_with("react") else 4), "frame timing " + name)
	DirAccess.make_dir_recursive_absolute("res://artifacts/visual/m6")
	sheet.save_png("res://artifacts/visual/m6/assets_native.png")
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://artifacts/visual/m6/assets_3x.png")
	print("M6 ART %s: %s assertions, %s failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)
