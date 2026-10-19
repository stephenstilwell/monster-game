extends SceneTree
const Pipeline = preload("res://tools/art/asset_pipeline.gd")

func _initialize() -> void:
	var output := "res://assets/generated"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	var result: Dictionary = Pipeline.generate(output)
	if result.has("error"):
		push_error(result.error)
		quit(1)
	else:
		print("GENERATED: %s raster assets, %s animations, %s tiles -> %s" % [result.assets.size(), result.animations.size(), result.tiles.size(), output])
		quit()
