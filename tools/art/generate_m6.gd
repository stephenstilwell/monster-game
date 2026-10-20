extends SceneTree
func _initialize() -> void:
	preload("res://tools/art/progression_recipes.gd").generate("res://assets/generated/m6")
	print("M6 GENERATED: 8 atlases, 9 original PCM tracks/effects")
	quit()
