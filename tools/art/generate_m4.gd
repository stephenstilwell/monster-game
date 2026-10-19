extends SceneTree
func _initialize() -> void:
	var result: Dictionary = preload("res://tools/art/management_recipes.gd").generate("res://assets/generated/m4")
	if result.has("error"):
		push_error(result.error)
		quit(1)
	else:
		print("M4 GENERATED: portraits, items, menu states")
		quit()
