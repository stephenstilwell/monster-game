extends RefCounted
const Base = preload("res://tools/art/art_recipes.gd")
const Battle = preload("res://tools/art/battle_recipes.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const IDS := ["brindlewick", "cindrel", "rillume"]

static func images() -> Dictionary:
	var r := Base.new()
	var portraits := r.blank(144, 48)
	for i in range(3):
		var card := r.blank(48, 48)
		r.box(card, 0, 0, 48, 48, 0)
		r.box(card, 1, 1, 46, 46, 8)
		r.box(card, 2, 2, 44, 44, 4)
		for y in range(5, 44, 5):
			r.line(card, Vector2i(3, y), Vector2i(44, y - 2), 5)
		card.blend_rect(Battle.monster(IDS[i]), Rect2i(0, 0, 48, 48), Vector2i(0, -1))
		for corner: Vector2i in [Vector2i(2, 2), Vector2i(43, 2), Vector2i(2, 43), Vector2i(43, 43)]:
			r.box(card, corner.x, corner.y, 3, 3, 13)
		portraits.blit_rect(card, Rect2i(0, 0, 48, 48), Vector2i(i * 48, 0))
	var items := r.blank(48, 24)
	# Braided amber capture charm, with metal clasp and glowing heart.
	r.line(items, Vector2i(6, 8), Vector2i(12, 2), 9)
	r.line(items, Vector2i(12, 2), Vector2i(18, 8), 9)
	r.oval(items, 12, 14, 8, 8, 0)
	r.oval(items, 12, 13, 6, 6, 8)
	r.oval(items, 12, 12, 4, 4, 12)
	r.box(items, 10, 10, 4, 5, 13)
	r.pixel(items, 10, 9, 3)
	r.box(items, 9, 6, 6, 3, 9)
	# Stoppered herbal flask, leaf label and glass highlights.
	r.box(items, 29, 7, 14, 15, 0)
	r.box(items, 30, 8, 12, 13, 10)
	r.box(items, 31, 13, 10, 7, 5)
	r.box(items, 32, 2, 8, 5, 0)
	r.box(items, 33, 3, 6, 3, 9)
	r.box(items, 32, 10, 2, 7, 11)
	r.poly(items, [Vector2i(35, 18), Vector2i(35, 13), Vector2i(40, 11), Vector2i(39, 16)], 6)
	r.pixel(items, 34, 8, 3)
	var states := r.blank(144, 20)
	for i in range(3):
		var x := i * 48
		r.box(states, x, 0, 48, 20, 0)
		r.box(states, x + 1, 1, 46, 18, [8, 13, 2][i])
		r.box(states, x + 2, 2, 44, 16, [1, 4, 0][i])
		r.line(states, Vector2i(x + 4, 4), Vector2i(x + 10, 4), [9, 6, 1][i])
		r.line(states, Vector2i(x + 37, 15), Vector2i(x + 43, 15), [9, 6, 1][i])
	return {"portraits": portraits, "items": items, "menu_states": states}

static func generate(output: String) -> Dictionary:
	if DirAccess.make_dir_recursive_absolute(output) != OK: return {"error": "OUTPUT DIRECTORY FAILED"}
	var manifest := {"version": "m4.1", "seed": 842031, "palette": "woodland16", "assets": {}, "regions": {}}
	var generated := images()
	for id: String in generated:
		var image: Image = generated[id]
		if image.save_png(output + "/" + id + ".png") != OK: return {"error": "PNG WRITE FAILED"}
		manifest.assets[id] = {"size": [image.get_width(), image.get_height()], "sha256": Pipeline.digest(image.get_data())}
	for i in range(3): manifest.regions[IDS[i]] = {"asset": "portraits", "rect": [i * 48, 0, 48, 48], "anchor": [0, 0]}
	for i in range(2): manifest.regions[["charm", "balm"][i]] = {"asset": "items", "rect": [i * 24, 0, 24, 24], "anchor": [0, 0]}
	for i in range(3): manifest.regions[["normal", "focused", "disabled"][i]] = {"asset": "menu_states", "rect": [i * 48, 0, 48, 20], "anchor": [0, 0]}
	if Pipeline.write_text(output + "/manifest.json", JSON.stringify(manifest, "\t", true) + "\n") != OK: return {"error": "MANIFEST WRITE FAILED"}
	return manifest
