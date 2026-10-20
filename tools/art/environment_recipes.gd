extends RefCounted
## Original integer-pixel scenery. Stable seed; independent from gameplay RNG.
const Base = preload("res://tools/art/art_recipes.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const VERSION := "environment.1"
const SEED := 20261020

static func tree(variant: int, frame: int) -> Image:
	var r := Base.new()
	var im := r.blank(48, 64)
	var sway: int = [0, 1, 0, -1][frame]
	r.oval(im, 24, 59, 17, 3, 4)
	# Fixed trunk and roots in every frame; foliage alone catches the breeze.
	r.poly(im, [Vector2i(21, 26), Vector2i(27, 26), Vector2i(28, 54), Vector2i(33, 60), Vector2i(15, 60), Vector2i(21, 54)], 0)
	r.box(im, 22, 28, 4, 29, 9 if variant == 1 else 7)
	r.line(im, Vector2i(22, 33), Vector2i(22, 55), 3 if variant == 1 else 8)
	for y in [38, 45, 51]: r.line(im, Vector2i(24, y), Vector2i(26, y + 1), 7 if variant == 1 else 9)
	if variant == 2:
		# Fir: a narrow leader and three asymmetric, layered needle skirts.
		for tier in range(4):
			var cy := 5 + tier * 9
			var width := 8 + tier * 4
			var cx := 24 + (sway if tier < 2 else 0)
			r.poly(im, [Vector2i(cx, cy), Vector2i(cx + width, cy + 17), Vector2i(cx + 6, cy + 15), Vector2i(cx + 10, cy + 20), Vector2i(cx - width, cy + 17)], 0)
			r.poly(im, [Vector2i(cx, cy + 2), Vector2i(cx + width - 3, cy + 15), Vector2i(cx - width + 3, cy + 15)], 4)
			r.line(im, Vector2i(cx - 1, cy + 5), Vector2i(cx - width + 5, cy + 13), 5)
			r.line(im, Vector2i(cx - 2, cy + 8), Vector2i(cx - width + 7, cy + 12), 6)
			for side in [-1, 1]:
				for branch in range(3):
					var p := Vector2i(cx + side * (2 + branch * 3), cy + 10 + branch * 2)
					r.line(im, p, p + Vector2i(side * 3, 2), 5 if side == 1 else 6)
					r.pixel(im, p.x + side * 2, p.y + 2, 4)
	else:
		var crowns: Array
		match variant:
			0: crowns = [[23, 14, 13, 11], [12, 27, 11, 12], [34, 28, 12, 13], [23, 36, 14, 11]]
			1: crowns = [[24, 12, 10, 10], [19, 23, 11, 12], [29, 31, 10, 11], [22, 38, 11, 9]]
			3: crowns = [[20, 15, 13, 10], [12, 27, 10, 12], [32, 24, 12, 10], [25, 34, 16, 10]]
			4: crowns = [[29, 14, 12, 10], [15, 21, 12, 10], [34, 30, 11, 11], [19, 34, 15, 11]]
			_: crowns = [[24, 14, 9, 11], [13, 28, 10, 10], [31, 27, 9, 10], [22, 36, 11, 9]]
		for i in range(crowns.size()):
			var c: Array = crowns[i]
			var dx: int = sway if i < 2 else 0
			var shade: int = 8 if variant == 4 else 4
			var mid: int = 9 if variant == 4 else 5
			var light: int = 13 if variant == 4 else 6
			r.oval(im, c[0] + dx, c[1], c[2], c[3], 0)
			r.oval(im, c[0] + dx, c[1] - 1, c[2] - 1, c[3] - 2, shade)
			r.oval(im, c[0] - 2 + dx, c[1] - 3, c[2] - 3, c[3] - 4, mid)
			# Broken leaf clusters instead of identical broad highlight ovals.
			for cluster in range(3):
				var x: int = c[0] - c[2] + 4 + cluster * 4 + dx
				var y: int = c[1] - c[3] + 4 + (cluster + i) % 3
				r.box(im, x, y, 3, 2, light)
				r.pixel(im, x - 1, y + 1, mid)
			r.line(im, Vector2i(c[0] - 3, c[1] + 3), Vector2i(c[0] + 2, c[1] + 4), mid)
		if variant == 3:
			for x in [8, 15, 30, 37]:
				r.line(im, Vector2i(x, 30), Vector2i(x + sway, 46 + x % 4), 4)
				r.line(im, Vector2i(x + 1, 32), Vector2i(x + 1 + sway, 44 + x % 4), 5)
				r.pixel(im, x + 1 + sway, 41, 6)
		if variant == 5:
			r.line(im, Vector2i(23, 49), Vector2i(15, 40), 8)
			r.line(im, Vector2i(25, 46), Vector2i(33, 37), 8)
			r.oval(im, 31 + sway, 38, 4, 3, 5)
	return im

static func house(variant: int) -> Image:
	var r := Base.new()
	var im := r.blank(64, 64)
	var wall: int = [9, 2, 8, 9][variant]
	var roof: int = [4, 10, 7, 14][variant]
	var trim: int = [5, 11, 8, 15][variant]
	r.oval(im, 32, 60, 28, 3, 4)
	r.box(im, 6, 27, 52, 33, 0)
	r.box(im, 8, 28, 48, 29, wall)
	for y in range(33, 56, 6): r.box(im, 9, y, 46, 1, 7 if variant != 1 else 1)
	for x in [9, 50]:
		r.box(im, x, 28, 4, 29, 7)
		r.box(im, x, 28, 1, 29, 8)
	if variant in [0, 2]:
		var peak := 27 if variant == 0 else 38
		r.poly(im, [Vector2i(1, 29), Vector2i(peak, 4), Vector2i(62, 29)], 0)
		r.poly(im, [Vector2i(5, 27), Vector2i(peak, 7), Vector2i(58, 27)], roof)
		for y in range(14, 27, 4):
			var reach := y - 7
			r.line(im, Vector2i(maxi(5, peak - reach), y), Vector2i(mini(58, peak + reach), y), trim)
			for x in range(maxi(6, peak - reach + 2), mini(57, peak + reach), 6): r.pixel(im, x, y - 1, trim)
	else:
		# Wide hipped roof and a small dormer; same doorway/collision as the lodge.
		r.poly(im, [Vector2i(11, 9), Vector2i(49, 9), Vector2i(63, 28), Vector2i(0, 28)], 0)
		r.poly(im, [Vector2i(13, 11), Vector2i(48, 11), Vector2i(59, 25), Vector2i(4, 25)], roof)
		for y in [15, 20, 24]: r.line(im, Vector2i(11 - (y - 11) / 2, y), Vector2i(48 + (y - 11) / 2, y), trim)
		r.poly(im, [Vector2i(24, 20), Vector2i(32, 11), Vector2i(40, 20)], 0)
		r.box(im, 27, 19, 10, 8, 9)
		r.box(im, 29, 19, 6, 5, 10)
		r.box(im, 29, 19, 2, 2, 11)
	# Chimney and stone cap on alternate silhouettes.
	if variant in [1, 2]:
		r.box(im, 45, 4, 8, 13, 0)
		r.box(im, 46, 5, 6, 11, 2)
		r.box(im, 44, 3, 10, 3, 1)
		r.line(im, Vector2i(47, 8), Vector2i(51, 8), 3)
	r.box(im, 26, 37, 13, 22, 0)
	r.box(im, 28, 38, 9, 19, 7)
	r.line(im, Vector2i(29, 39), Vector2i(29, 55), 8)
	r.pixel(im, 35, 49, 13)
	for x in [15, 43]:
		r.box(im, x, 36, 9, 11, 7)
		r.box(im, x + 1, 37, 7, 8, 10)
		r.box(im, x + 1, 37, 2, 3, 11)
		r.box(im, x + 4, 37, 1, 9, 9)
		if variant == 1:
			for side in [-2, 9]: r.box(im, x + side, 36, 2, 11, 5)
		elif variant in [0, 3]:
			r.box(im, x - 1, 47, 11, 3, 7)
			r.box(im, x, 46, 9, 2, 5)
			for bloom in [0, 4, 7]: r.pixel(im, x + bloom, 45, 15 if variant == 0 else 13)
	r.box(im, 24, 58, 17, 3, 2)
	r.box(im, 24, 58, 17, 1, 3)
	if variant == 2:
		r.box(im, 11, 51, 9, 6, 7)
		r.line(im, Vector2i(12, 52), Vector2i(18, 52), 9)
		r.line(im, Vector2i(12, 55), Vector2i(18, 55), 9)
	if variant == 0:
		for x in [9, 51]:
			for y in range(28, 42, 3): r.box(im, x, y, 2, 3, 5)
	return im

static func flowers(variant: int, frame: int) -> Image:
	var r := Base.new()
	var im := r.blank(24, 16)
	var bend: int = [0, 1, 0, -1][frame]
	for i in range(3):
		var x := 4 + i * 7
		var top := 5 + (i + variant) % 3
		var dx := bend if i != 1 else 0
		r.line(im, Vector2i(x, 14), Vector2i(x + dx, top + 2), 4)
		r.line(im, Vector2i(x, 12), Vector2i(x + 3, 10), 5)
		var petal: int = [3, 15, 13, 11][variant]
		if variant == 1:
			r.box(im, x + dx - 1, top, 3, 3, 14)
			r.box(im, x + dx - 1, top + 2, 4, 1, petal)
		else:
			r.box(im, x + dx - 2, top, 5, 1, petal)
			r.box(im, x + dx, top - 2, 1, 5, petal)
		r.pixel(im, x + dx, top, 12 if variant != 2 else 8)
	return im

static func ground(variant: int) -> Image:
	var r := Base.new()
	var im := r.blank(16, 16)
	if variant == 0:
		for side in [-1, 1]:
			for leaf in range(3):
				r.line(im, Vector2i(8, 14), Vector2i(8 + side * (3 + leaf), 6 + leaf * 2), 4)
				r.pixel(im, 8 + side * (3 + leaf), 5 + leaf * 2, 6)
	elif variant == 1:
		for p: Vector2i in [Vector2i(5, 11), Vector2i(10, 9), Vector2i(8, 13)]:
			r.oval(im, p.x, p.y, 3, 2, 4)
			r.oval(im, p.x - 1, p.y - 1, 2, 1, 5)
	elif variant == 2:
		for p: Vector2i in [Vector2i(4, 12), Vector2i(10, 10)]:
			r.box(im, p.x, p.y - 1, 1, 3, 9)
			r.oval(im, p.x, p.y - 2, 3, 2, 7)
			r.pixel(im, p.x - 1, p.y - 3, 12)
	else:
		r.line(im, Vector2i(3, 13), Vector2i(10, 9), 8)
		r.line(im, Vector2i(7, 12), Vector2i(13, 13), 7)
		r.pixel(im, 6, 11, 9)
		r.pixel(im, 12, 12, 9)
	return im

static func generate(folder: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(folder)
	var r := Base.new()
	var images := {"trees": r.blank(192, 384), "houses": r.blank(256, 64), "flowers": r.blank(96, 64), "ground": r.blank(64, 16)}
	var manifest := {"version": VERSION, "seed": SEED, "palette": "woodland16", "assets": {}, "regions": {}}
	for variant in range(6):
		for frame in range(4): images.trees.blit_rect(tree(variant, frame), Rect2i(0, 0, 48, 64), Vector2i(frame * 48, variant * 64))
		manifest.regions["tree_%s" % variant] = {"asset": "trees", "rect": [0, variant * 64, 48, 64], "anchor": [24, 60], "frames": 4, "step": 0.6}
	for variant in range(4):
		images.houses.blit_rect(house(variant), Rect2i(0, 0, 64, 64), Vector2i(variant * 64, 0))
		manifest.regions["house_%s" % variant] = {"asset": "houses", "rect": [variant * 64, 0, 64, 64], "anchor": [32, 61], "frames": 1, "step": 1.0}
		for frame in range(4): images.flowers.blit_rect(flowers(variant, frame), Rect2i(0, 0, 24, 16), Vector2i(frame * 24, variant * 16))
		manifest.regions["flower_%s" % variant] = {"asset": "flowers", "rect": [0, variant * 16, 24, 16], "anchor": [12, 14], "frames": 4, "step": 0.8}
		images.ground.blit_rect(ground(variant), Rect2i(0, 0, 16, 16), Vector2i(variant * 16, 0))
		manifest.regions["ground_%s" % variant] = {"asset": "ground", "rect": [variant * 16, 0, 16, 16], "anchor": [8, 15], "frames": 1, "step": 1.0}
	for id: String in images:
		var image: Image = images[id]
		assert(image.save_png(folder + "/" + id + ".png") == OK)
		manifest.assets[id] = {"size": [image.get_width(), image.get_height()], "sha256": Pipeline.digest(image.get_data())}
	assert(Pipeline.write_text(folder + "/manifest.json", JSON.stringify(manifest, "\t", true) + "\n") == OK)
	return manifest
