extends SceneTree
func _initialize() -> void:
	var result: Dictionary = preload("res://tools/art/expedition_recipes.gd").generate("res://assets/generated/m5")
	if result.has("error"): push_error(result.error); quit(1)
	else: print("M5 GENERATED: six atlases, thirteen regions, three baked templates"); quit()