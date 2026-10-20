extends SceneTree
func _initialize() -> void:
	preload("res://tools/audio/score_recipes.gd").new().generate("res://assets/generated/audio")
	print("AUDIO GENERATED: five original sixteen-bar stereo themes and eight effects")
	quit()
