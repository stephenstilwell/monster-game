extends RefCounted
const Base = preload("res://tools/art/art_recipes.gd")
const Battle = preload("res://tools/art/battle_recipes.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const Stable = preload("res://tools/art/stable_resource.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")
const REGIONS := {
	"m5_fern": ["props", [0, 0, 16, 32], [8, 31]], "m5_cleared": ["props", [16, 0, 16, 32], [8, 31]],
	"m5_gate": ["props", [32, 0, 48, 48], [24, 47]], "m5_camp": ["props", [80, 0, 48, 48], [24, 47]],
	"m5_guardian_gate": ["props", [128, 0, 48, 48], [24, 47]], "m5_sanctuary": ["props", [176, 0, 64, 48], [32, 47]],
	"thorn": ["relics", [0, 0, 24, 24], [0, 0]], "shell": ["relics", [24, 0, 24, 24], [0, 0]], "hearth": ["relics", [48, 0, 24, 24], [0, 0]],
	"victory": ["outcomes", [0, 0, 32, 32], [0, 0]], "retreat": ["outcomes", [32, 0, 32, 32], [0, 0]],
	"defeat": ["outcomes", [64, 0, 32, 32], [0, 0]], "abandon": ["outcomes", [96, 0, 32, 32], [0, 0]]}

static func crest(r: RefCounted, im: Image, cx: int, top: int) -> void:
	for side in [-1, 1]:
		for leaf in range(4):
			var root := Vector2i(cx + side * (3 + leaf * 2), top + 10 - leaf)
			r.line(im, root, root + Vector2i(side * 4, -5), 9)
			r.line(im, root + Vector2i(side, -2), root + Vector2i(side * 4, -2), 13)
	r.poly(im, [Vector2i(cx - 4, top + 6), Vector2i(cx, top), Vector2i(cx + 4, top + 6), Vector2i(cx, top + 9)], 12)
	r.pixel(im, cx, top + 4, 3)

static func images() -> Dictionary:
	var r := Base.new()
	var props := r.blank(240, 48)
	for x in [0, 16]:
		for side in [-1, 1]:
			for leaf in range(3):
				r.line(props, Vector2i(x + 8, 30), Vector2i(x + 8 + side * (3 + leaf), 23 + leaf), 5)
		r.box(props, x + 6, 10, 4, 18, 0)
		r.box(props, x + 7, 11, 2, 16, 8)
		r.oval(props, x + 8, 15, 5, 7, 0)
		r.oval(props, x + 8, 14, 3, 5, 13 if x == 0 else 2)
		r.pixel(props, x + 7, 12, 3 if x == 0 else 1)
		r.line(props, Vector2i(x + 3, 8), Vector2i(x + 12, 8), 9)
	for x in [32, 128]:
		for post in [6, 38]:
			r.box(props, x + post - 1, 10, 6, 37, 0)
			r.box(props, x + post, 11, 3, 35, 7)
			r.line(props, Vector2i(x + post + 1, 13), Vector2i(x + post + 1, 42), 9)
			r.oval(props, x + post + 1, 22, 5, 7, 0)
			r.oval(props, x + post + 1, 21, 3, 5, 13)
		r.poly(props, [Vector2i(x + 2, 13), Vector2i(x + 24, 2), Vector2i(x + 45, 13), Vector2i(x + 44, 19), Vector2i(x + 24, 8), Vector2i(x + 3, 19)], 0)
		r.line(props, Vector2i(x + 4, 14), Vector2i(x + 24, 4), 8)
		r.line(props, Vector2i(x + 24, 4), Vector2i(x + 43, 14), 9)
		if x == 128: crest(r, props, x + 24, 10)
		else:
			r.line(props, Vector2i(x + 24, 12), Vector2i(x + 24, 24), 9)
			r.oval(props, x + 24, 26, 4, 6, 12)
			r.pixel(props, x + 23, 24, 13)
	# Resting camp: canvas shelter, log bench, contained lantern and fern mat.
	r.poly(props, [Vector2i(82, 28), Vector2i(104, 4), Vector2i(124, 28)], 0)
	r.poly(props, [Vector2i(85, 27), Vector2i(104, 7), Vector2i(120, 27)], 5)
	r.poly(props, [Vector2i(102, 10), Vector2i(108, 27), Vector2i(97, 27)], 1)
	r.line(props, Vector2i(104, 7), Vector2i(120, 27), 6)
	r.oval(props, 103, 42, 21, 4, 4)
	r.box(props, 84, 32, 19, 5, 0)
	r.box(props, 85, 33, 17, 3, 8)
	r.oval(props, 87, 34, 2, 2, 9)
	r.oval(props, 116, 36, 6, 8, 0)
	r.oval(props, 116, 35, 4, 6, 12)
	r.box(props, 115, 31, 2, 8, 13)
	r.line(props, Vector2i(110, 28), Vector2i(121, 28), 9)
	# Sanctuary enclosure with plank fencing, woven nest and lit banner.
	for x in range(178, 239, 6):
		r.box(props, x, 20, 3, 24, 0)
		r.box(props, x + 1, 21, 1, 20, 9)
	for y in [25, 37]: r.box(props, 179, y, 59, 3, 8)
	r.oval(props, 207, 32, 15, 6, 0)
	r.oval(props, 207, 31, 13, 4, 9)
	for x in range(197, 219, 3): r.line(props, Vector2i(x, 32), Vector2i(x + 2, 29), 7)
	r.box(props, 201, 3, 13, 19, 0)
	r.box(props, 202, 4, 11, 16, 5)
	crest(r, props, 207, 6)
	var relics := r.blank(72, 24)
	for index in range(3):
		var x := index * 24
		r.oval(relics, x + 12, 21, 10, 2, 0)
	if true:
		r.box(relics, 7, 5, 10, 16, 0)
		r.box(relics, 8, 6, 8, 14, 8)
		r.box(relics, 10, 8, 4, 9, 13)
		for side in [-1, 1]:
			for y in [7, 12, 17]: r.line(relics, Vector2i(12 + side * 6, y + 3), Vector2i(12 + side * 9, y), 6)
		r.oval(relics, 36, 13, 9, 9, 0)
		r.oval(relics, 36, 12, 7, 7, 10)
		for i in range(5): r.line(relics, Vector2i(31 + i, 16), Vector2i(35 + i, 6 + i), 11)
		r.oval(relics, 36, 12, 3, 3, 3)
		r.oval(relics, 36, 12, 2, 2, 10)
		r.oval(relics, 60, 13, 8, 9, 0)
		r.oval(relics, 60, 12, 6, 7, 8)
		r.poly(relics, [Vector2i(55, 12), Vector2i(58, 8), Vector2i(60, 10), Vector2i(63, 8), Vector2i(65, 12), Vector2i(60, 17)], 13)
		r.line(relics, Vector2i(60, 5), Vector2i(64, 2), 6)
	var guardian := Battle.monster("brindlewick").get_region(Rect2i(0, 0, 384, 48))
	for frame in range(8): crest(r, guardian, frame * 48 + 24, 1)
	var effects := r.blank(192, 32)
	for frame in range(4):
		for particle in range(8):
			var center := Vector2i(frame * 48 + 24, 16)
			var offset := Vector2i((particle % 4 - 2) * (frame + 3), (particle / 4 * 2 - 1) * (frame + 4))
			r.line(effects, center + offset, center + offset + Vector2i(2, -3), 13 if particle % 2 else 6)
	var outcomes := r.blank(128, 32)
	for i in range(4):
		var x := i * 32 + 16
		r.oval(outcomes, x, 26, 11, 3, 1)
		r.oval(outcomes, x, 15, 8, 11, 0)
		r.oval(outcomes, x, 14, 6, 9, [12, 10, 2, 7][i])
		r.box(outcomes, x - 1, 10, 3, 10, [13, 11, 1, 9][i])
		r.line(outcomes, Vector2i(x - 7, 6), Vector2i(x + 7, 6), 9)
		if i == 0: crest(r, outcomes, x, 1)
		elif i == 1: r.line(outcomes, Vector2i(x - 9, 23), Vector2i(x + 9, 23), 11)
		elif i == 3: r.line(outcomes, Vector2i(x - 7, 24), Vector2i(x + 7, 10), 8)
	var journal := r.blank(320, 180)
	r.box(journal, 0, 0, 320, 180, 0)
	r.box(journal, 3, 3, 314, 174, 8)
	r.box(journal, 4, 4, 312, 172, 7)
	r.box(journal, 6, 6, 308, 168, 0)
	for y in range(13, 170, 12):
		r.line(journal, Vector2i(3, y), Vector2i(5, y + 3), 9)
		r.line(journal, Vector2i(314, y), Vector2i(316, y + 3), 9)
	for x in [8, 307]:
		for y in [8, 171]: r.box(journal, x, y, 5, 3, 13)
	return {"props": props, "relics": relics, "guardian": guardian, "effects": effects, "outcomes": outcomes, "journal": journal}

static func generate(folder: String) -> Dictionary:
	if DirAccess.make_dir_recursive_absolute(folder) != OK: return {"error": "CANNOT CREATE ART DIRECTORY"}
	var manifest := {"version": Routes.CONTENT, "seed": 842031, "palette": "woodland16", "assets": {}, "regions": {}, "animations": {"guardian_idle": {"asset": "guardian", "frames": 4, "fps": 4, "size": [48, 48], "anchor": [24, 43]}, "guardian_react": {"asset": "guardian", "frames": 4, "fps": 10, "size": [48, 48], "anchor": [24, 43]}, "guardian_entry": {"asset": "effects", "frames": 4, "fps": 8, "size": [48, 32], "anchor": [24, 16]}}}
	var outputs := images()
	for id: String in outputs:
		var im: Image = outputs[id]
		if im.save_png(folder + "/" + id + ".png") != OK: return {"error": "PNG WRITE FAILED"}
		manifest.assets[id] = {"size": [im.get_width(), im.get_height()], "sha256": Pipeline.digest(im.get_data())}
	for id: String in REGIONS:
		var s: Array = REGIONS[id]
		manifest.regions[id] = {"asset": s[0], "rect": s[1], "anchor": s[2]}
	if Pipeline.write_text(folder + "/manifest.json", JSON.stringify(manifest, "\t", true) + "\n") != OK: return {"error": "MANIFEST WRITE FAILED"}
	for index in range(3):
		if Stable.save(Routes.build({"template": index, "theme": index, "seed": "842031"}, index), folder + "/template_%s.tres" % index) != OK: return {"error": "MAP WRITE FAILED"}
	return manifest