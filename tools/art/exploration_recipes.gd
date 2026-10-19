extends RefCounted
const Base = preload("res://tools/art/art_recipes.gd")
const VERSION := "m2.1"
const SEED := 611942

static func npc(id: String) -> Image:
	var r := Base.new()
	var image := r.player()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color == r.palette[14]: image.set_pixel(x, y, r.palette[5 if id == "mara" else 8])
			elif color == r.palette[15]: image.set_pixel(x, y, r.palette[6 if id == "mara" else 9])
	for facing in range(4):
		for frame in range(5):
			var cell := image.get_region(Rect2i(frame * 16, facing * 24, 16, 24))
			if id == "mara":
				r.oval(cell, 8, 5, 4, 4, 0)
				r.oval(cell, 8, 5, 3, 3, 5)
				r.line(cell, Vector2i(6, 3), Vector2i(9, 2), 6)
				if facing != 1:
					r.box(cell, 6, 5, 4, 3, 9)
					r.pixel(cell, 6 if facing != 3 else 9, 6, 0)
					if facing == 0: r.pixel(cell, 9, 6, 0)
				r.box(cell, 10, 14, 3, 4, 7)
				r.box(cell, 11, 14, 2, 1, 9)
			else:
				r.box(cell, 4, 2, 8, 2, 0)
				r.box(cell, 5, 2, 6, 1, 2)
				if facing != 1:
					r.box(cell, 6, 8, 4, 2, 2)
					r.pixel(cell, 5, 5, 2)
					r.pixel(cell, 10, 5, 2)
				r.box(cell, 6, 12, 4, 5, 7)
				r.box(cell, 7, 12, 2, 3, 9)
				r.box(cell, 10, 14, 3, 4, 8)
				r.line(cell, Vector2i(11, 13), Vector2i(11, 17), 2)
			image.blit_rect(cell, Rect2i(0, 0, 16, 24), Vector2i(frame * 16, facing * 24))
	return image

static func props() -> Image:
	var r := Base.new()
	var im := r.blank(96, 48)
	# Carved trail sign with an east-pointing lantern motif.
	r.box(im, 9, 10, 4, 13, 0)
	r.box(im, 10, 10, 2, 12, 8)
	r.poly(im, [Vector2i(1, 2), Vector2i(18, 2), Vector2i(23, 7), Vector2i(18, 12), Vector2i(1, 12)], 0)
	r.poly(im, [Vector2i(2, 3), Vector2i(17, 3), Vector2i(21, 7), Vector2i(17, 10), Vector2i(2, 10)], 8)
	r.line(im, Vector2i(3, 3), Vector2i(16, 3), 9)
	r.box(im, 5, 5, 4, 4, 13)
	r.line(im, Vector2i(12, 7), Vector2i(17, 7), 7)
	r.pixel(im, 16, 6, 7)
	r.pixel(im, 16, 8, 7)
	# Tall hanging lantern post.
	r.box(im, 29, 3, 3, 28, 0)
	r.box(im, 29, 4, 2, 26, 8)
	r.box(im, 29, 4, 1, 25, 9)
	r.line(im, Vector2i(30, 4), Vector2i(37, 4), 9)
	r.line(im, Vector2i(36, 4), Vector2i(36, 8), 7)
	r.box(im, 33, 8, 7, 11, 0)
	r.box(im, 34, 9, 5, 8, 12)
	r.box(im, 34, 9, 2, 6, 13)
	r.pixel(im, 34, 9, 3)
	r.box(im, 33, 18, 7, 1, 9)
	# Mossy stump with growth rings and roots.
	r.poly(im, [Vector2i(45, 5), Vector2i(58, 5), Vector2i(60, 17), Vector2i(63, 21), Vector2i(42, 21), Vector2i(45, 16)], 0)
	r.box(im, 46, 7, 12, 12, 7)
	r.box(im, 47, 8, 2, 10, 8)
	r.box(im, 54, 8, 2, 10, 8)
	r.oval(im, 52, 6, 8, 4, 9)
	r.oval(im, 52, 6, 5, 2, 8)
	r.line(im, Vector2i(50, 6), Vector2i(54, 6), 7)
	r.box(im, 55, 15, 5, 3, 5)
	r.pixel(im, 57, 14, 6)
	# Shore reeds, kept separate from collision geometry.
	for x in range(4):
		var px := 68 + x * 3
		r.line(im, Vector2i(px, 23), Vector2i(px - 2, 8 + x % 2 * 4), 4)
		r.line(im, Vector2i(px + 1, 23), Vector2i(px + 2, 4 + x % 3 * 3), 6)
		r.box(im, px + 1, 3 + x % 3 * 3, 2, 5, 8)
	return im

static func route_tiles() -> Image:
	var r := Base.new()
	var image := r.blank(32, 16)
	for tile in range(2):
		var ox := tile * 16
		r.box(image, ox, 0, 16, 16, 8)
		for x in range(0, 16, 4):
			r.box(image, ox + x, 0, 1, 16, 7)
			r.box(image, ox + x + 1, 0, 1, 16, 9)
		var y: int = 1 if tile == 0 else 13
		r.box(image, ox, y, 16, 2, 0)
		r.box(image, ox, y, 16, 1, 9)
		for x in [3, 11]:
			r.pixel(image, ox + x, 6, 7)
			r.pixel(image, ox + x, 10, 7)
	return image

static func images() -> Dictionary:
	return {"mara": npc("mara"), "ivo": npc("ivo"), "props": props(), "route_tiles": route_tiles()}
