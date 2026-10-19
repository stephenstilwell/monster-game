extends RefCounted
const Recipes = preload("res://tools/art/art_recipes.gd")

static func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

static func write_text(path: String, content: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK

static func generate(output: String) -> Dictionary:
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if err != OK:
		return {"error": "Cannot create output directory: %s" % err}
	var recipes := Recipes.new()
	var images: Dictionary = recipes.images()
	var entries := {}
	for id: String in images:
		var image: Image = images[id]
		if image.save_png(output.path_join(id + ".png")) != OK:
			return {"error": "Cannot save " + id}
		entries[id] = {"file": id + ".png", "size": [image.get_width(), image.get_height()], "pixel_sha256": digest(image.get_data())}
	var frames := {}
	for facing in range(4):
		var direction: String = ["south", "north", "west", "east"][facing]
		frames["player_idle_" + direction] = {"asset": "player", "rects": [[0, facing * 24, 16, 24]], "fps": 1, "anchor": [8, 23]}
		var walk: Array = []
		for frame in range(4):
			walk.append([(frame + 1) * 16, facing * 24, 16, 24])
		frames["player_walk_" + direction] = {"asset": "player", "rects": walk, "fps": 8, "anchor": [8, 23]}
	for variant in range(2):
		for state in ["idle", "react"]:
			var rects: Array = []
			for frame in range(4):
				rects.append([(frame + (4 if state == "react" else 0)) * 48, variant * 48, 48, 48])
			frames["brindlewick_%s_%s" % [variant, state]] = {"asset": "brindlewick", "rects": rects, "fps": 4 if state == "idle" else 10, "anchor": [24, 43]}
	for effect in range(3):
		var rects: Array = []
		for frame in range(4):
			rects.append([frame * 48, effect * 16, 48, 16])
		frames[["lantern", "leaf", "charm"][effect]] = {"asset": "effects", "rects": rects, "fps": 6, "anchor": [24, 8]}
	var regions := {
		"tree": {"asset": "objects", "rect": [0, 0, 48, 64], "anchor": [24, 60]},
		"waystation": {"asset": "objects", "rect": [48, 0, 64, 64], "anchor": [32, 61]},
		"rock": {"asset": "objects", "rect": [112, 0, 24, 16], "anchor": [12, 14]},
		"flowers": {"asset": "objects", "rect": [112, 20, 24, 16], "anchor": [12, 14]},
		"fence": {"asset": "objects", "rect": [136, 8, 24, 24], "anchor": [12, 20]},
		"panel": {"asset": "ui", "rect": [0, 0, 12, 12]},
		"cursor": {"asset": "ui", "rect": [16, 0, 8, 12]},
		"health": {"asset": "ui", "rect": [28, 0, 32, 8]},
		"grove": {"asset": "ui", "rect": [64, 0, 12, 12]},
		"ember": {"asset": "ui", "rect": [76, 0, 10, 12]},
		"brook": {"asset": "ui", "rect": [86, 0, 12, 12]},
		"status": {"asset": "ui", "rect": [98, 0, 12, 12]},
		"lantern_icon": {"asset": "ui", "rect": [110, 0, 12, 12]},
		"dialogue": {"asset": "ui", "rect": [0, 16, 12, 8]}
	}
	var tiles: Array = []
	for tile in range(32):
		var terrain_id := "grass"
		if tile in [2, 3]: terrain_id = "path"
		elif tile in [4, 5]: terrain_id = "tall_grass"
		elif tile in [6, 7]: terrain_id = "water"
		elif tile >= 8 and tile < 28: terrain_id = "bank"
		elif tile >= 28: terrain_id = "bridge"
		tiles.append({"id": tile, "rect": [tile % 8 * 16, tile / 8 * 16, 16, 16], "terrain": terrain_id, "encounter": tile in [4, 5], "collision": tile >= 6 and tile < 28, "exposed_edges_nesw": tile - 8 if tile >= 8 and tile < 24 else 0})
	var chars: Array = Recipes.GLYPHS.keys()
	chars.sort()
	var font := "info face=\"Lanternwild-%s\" size=8\ncommon lineHeight=8 base=7 scaleW=96 scaleH=48 pages=1 packed=0\npage id=0 file=\"font.png\"\nchars count=%s\n" % [entries.font.pixel_sha256.substr(0, 12), chars.size()]
	for index in range(chars.size()):
		font += "char id=%s x=%s y=%s width=5 height=7 xoffset=0 yoffset=0 xadvance=6 page=0 chnl=15\n" % [chars[index].unicode_at(0), index % 16 * 6, index / 16 * 8]
	if write_text(output.path_join("lanternwild.fnt"), font) != OK:
		return {"error": "Cannot save font descriptor"}
	var manifest := {"generator_version": Recipes.VERSION, "seed": Recipes.SEED, "palette": Recipes.HEX, "assets": entries, "animations": frames, "regions": regions, "tiles": tiles, "glyphs": "".join(chars)}
	if write_text(output.path_join("manifest.json"), JSON.stringify(manifest, "\t", true) + "\n") != OK:
		return {"error": "Cannot save manifest"}
	return manifest
