extends SceneTree
const Pipeline = preload("res://tools/art/exploration_pipeline.gd")
func _initialize() -> void:
	var result := Pipeline.generate("res://assets/generated/m2", "res://data/maps")
	if result.has("error"):
		push_error(result.error)
		quit(1)
	else:
		print("M2 GENERATED: 4 raster assets, 16 NPC animations, 2 map resources")
		quit()
