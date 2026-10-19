extends RefCounted
const Recipes = preload("res://tools/art/battle_recipes.gd")
const Hash = preload("res://tools/art/asset_pipeline.gd")
const Stable = preload("res://tools/art/stable_resource.gd")
const Species = preload("res://scripts/monsters/species_definition.gd")
const Move = preload("res://scripts/battle/move_definition.gd")
const Item = preload("res://scripts/battle/item_definition.gd")

static func generate(output: String, data_root: String) -> Dictionary:
	for directory in [output, data_root + "/species", data_root + "/moves", data_root + "/items"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var assets := {}
	var animations := {}
	var images := Recipes.images()
	for id: String in images:
		var im: Image = images[id]
		if im.save_png(output + "/" + id + ".png") != OK: return {"error": "Cannot save " + id}
		assets[id] = {"size": [im.get_width(), im.get_height()], "pixel_sha256": Hash.digest(im.get_data())}
	for id: String in Recipes.IDS:
		for back in range(2):
			for state in ["idle", "react"]:
				var rects: Array = []
				for frame in range(4): rects.append([(frame + (4 if state == "react" else 0)) * 48, back * 48, 48, 48])
				animations[id + "_" + ("back" if back else "front") + "_" + state] = {"asset": id, "rects": rects, "fps": 4 if state == "idle" else 10, "anchor": [24, 43]}
	for index in range(6):
		var rects: Array = []
		for frame in range(4): rects.append([frame * 48, index * 16, 48, 16])
		animations[["impact", "leaf", "ember", "brook", "charm", "heal"][index]] = {"asset": "effects", "rects": rects, "fps": 8, "anchor": [24, 8]}
	for spec: Array in [["brindlewick", "BRINDLEWICK", "grove", 24, 5, 6, 5, 0.18, ["nudge", "leaf_arc"]], ["cindrel", "CINDREL", "ember", 22, 6, 5, 8, 0.20, ["nudge", "cinder"]], ["rillume", "RILLUME", "brook", 22, 5, 6, 7, 0.22, ["quickstep", "rill"]]]:
		var species := Species.new()
		species.id = spec[0]; species.title = spec[1]; species.affinity = spec[2]
		species.base_hp = spec[3]; species.base_attack = spec[4]; species.base_defense = spec[5]; species.base_speed = spec[6]; species.catch_rate = spec[7]
		species.moves.assign(spec[8])
		if Stable.save(species, data_root + "/species/" + species.id + ".tres") != OK: return {"error": "Species save"}
	for spec: Array in [["nudge", "NUDGE", "plain", 5, 1.0, 0, "impact"], ["leaf_arc", "LEAF ARC", "grove", 8, 0.95, 0, "leaf"], ["cinder", "CINDER", "ember", 8, 0.95, 0, "ember"], ["rill", "RILL", "brook", 8, 0.95, 0, "brook"], ["quickstep", "QUICKSTEP", "plain", 4, 1.0, 1, "impact"]]:
		var move := Move.new()
		move.id = spec[0]; move.title = spec[1]; move.affinity = spec[2]; move.power = spec[3]; move.accuracy = spec[4]; move.priority = spec[5]; move.effect = spec[6]
		if Stable.save(move, data_root + "/moves/" + move.id + ".tres") != OK: return {"error": "Move save"}
	for spec: Array in [["charm", "LANTERN CHARM", "capture", 0], ["balm", "TRAIL BALM", "heal", 24]]:
		var item := Item.new()
		item.id = spec[0]; item.title = spec[1]; item.effect = spec[2]; item.value = spec[3]
		if Stable.save(item, data_root + "/items/" + item.id + ".tres") != OK: return {"error": "Item save"}
	var manifest := {"version": Recipes.VERSION, "seed": 462197, "assets": assets, "animations": animations, "species": Recipes.IDS}
	if Hash.write_text(output + "/manifest.json", JSON.stringify(manifest, "\t", true) + "\n") != OK: return {"error": "Manifest save"}
	return manifest
