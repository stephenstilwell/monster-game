extends SceneTree
func _initialize() -> void:
	preload("res://tools/art/progression_recipes.gd").assemble("res://assets/generated/m6")
	print("M6 ASSEMBLED: 3 growth form SpriteFrames")
	quit()
