extends SceneTree
const Pipeline = preload("res://tools/art/battle_pipeline.gd")
func _initialize() -> void:
	var result := Pipeline.generate("res://assets/generated/m3", "res://data")
	if result.has("error"):
		push_error(result.error)
		quit(1)
	else:
		print("M3 GENERATED: 6 rasters, 18 animations, 3 species, 5 moves, 2 items")
		quit()
