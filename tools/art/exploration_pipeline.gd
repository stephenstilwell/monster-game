extends RefCounted
const Recipes = preload("res://tools/art/exploration_recipes.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const Maps = preload("res://tools/art/map_recipes.gd")
const Stable = preload("res://tools/art/stable_resource.gd")

static func generate(output: String, map_output: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(map_output))
	var assets := {}
	var images: Dictionary = Recipes.images()
	for id: String in images:
		var image: Image = images[id]
		if image.save_png(output.path_join(id + ".png")) != OK:
			return {"error": "Could not save " + id}
		assets[id] = {"size": [image.get_width(), image.get_height()], "pixel_sha256": Pipeline.digest(image.get_data())}
	var animations := {}
	for id in ["mara", "ivo"]:
		for direction in range(4):
			var name: String = ["south", "north", "west", "east"][direction]
			animations[id + "_idle_" + name] = {"asset": id, "rects": [[0, direction * 24, 16, 24]], "fps": 1, "anchor": [8, 23]}
			var rects: Array = []
			for frame in range(4):
				rects.append([(frame + 1) * 16, direction * 24, 16, 24])
			animations[id + "_walk_" + name] = {"asset": id, "rects": rects, "fps": 8, "anchor": [8, 23]}
	var regions := {"route_sign": {"asset": "props", "rect": [0, 0, 24, 24], "anchor": [10, 23]}, "lantern_post": {"asset": "props", "rect": [24, 0, 16, 32], "anchor": [6, 31]}, "stump": {"asset": "props", "rect": [40, 0, 24, 24], "anchor": [12, 21]}, "reeds": {"asset": "props", "rect": [64, 0, 16, 24], "anchor": [8, 23]}}
	var manifest := {"version": Recipes.VERSION, "seed": Recipes.SEED, "map_seeds": Maps.SEEDS, "assets": assets, "animations": animations, "regions": regions}
	if Pipeline.write_text(output.path_join("manifest.json"), JSON.stringify(manifest, "\t", true) + "\n") != OK:
		return {"error": "Cannot save M2 manifest"}
	for map in Maps.maps():
		if Stable.save(map, map_output.path_join(map.id + ".tres")) != OK:
			return {"error": "Cannot save map " + map.id}
	return manifest
