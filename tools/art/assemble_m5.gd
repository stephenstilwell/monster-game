extends SceneTree
const Stable = preload("res://tools/art/stable_resource.gd")
func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in ["guardian_front_idle", "guardian_front_react", "guardian_entry"]:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 4 if animation.ends_with("idle") else 8 if animation.ends_with("entry") else 10)
		for i in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = load("res://assets/generated/m5/" + ("effects" if animation.ends_with("entry") else "guardian") + ".png")
			atlas.region = Rect2(i * 48 + (192 if animation.ends_with("react") else 0), 0, 48, 32 if animation.ends_with("entry") else 48)
			frames.add_frame(animation, atlas)
	if Stable.save(frames, "res://assets/generated/m5/guardian_frames.tres") != OK: quit(1); return
	print("M5 ASSEMBLED: reusable guardian and entry animations")
	quit()