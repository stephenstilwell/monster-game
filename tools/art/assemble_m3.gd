extends SceneTree
const Stable = preload("res://tools/art/stable_resource.gd")
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/m3/manifest.json"))
	for id in ["brindlewick", "cindrel", "rillume", "effects"]:
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for name: String in manifest.animations:
			var spec: Dictionary = manifest.animations[name]
			if spec.asset != id: continue
			frames.add_animation(name)
			frames.set_animation_speed(name, spec.fps)
			frames.set_animation_loop(name, not name.ends_with("react"))
			for rect: Array in spec.rects:
				var texture := AtlasTexture.new()
				texture.atlas = load("res://assets/generated/m3/" + id + ".png")
				texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
				frames.add_frame(name, texture)
		if Stable.save(frames, "res://assets/generated/m3/" + id + "_frames.tres") != OK:
			quit(1)
			return
	print("M3 ASSEMBLED: 4 reusable SpriteFrames resources")
	quit()
