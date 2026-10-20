extends SceneTree
func _initialize() -> void:
	preload("res://tools/art/environment_recipes.gd").generate("res://assets/generated/environment")
	print("ENVIRONMENT GENERATED: 6 trees, 4 houses, 4 animated flowers, 4 ground plants")
	quit()
