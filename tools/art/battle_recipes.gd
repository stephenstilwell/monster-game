extends RefCounted
const Base = preload("res://tools/art/art_recipes.gd")
const VERSION := "m3.1"
const IDS := ["brindlewick", "cindrel", "rillume"]

static func monster(id: String) -> Image:
	var r := Base.new()
	var atlas := r.blank(384, 96)
	if id == "brindlewick":
		atlas.blit_rect(r.creature(), Rect2i(0, 0, 384, 48), Vector2i.ZERO)
	for back in range(2):
		for frame in range(8):
			if id == "brindlewick" and back == 0: continue
			var im := r.blank(48, 48)
			var bob: int = [0, 0, -1, 0, 0, -2, -1, 0][frame]
			r.oval(im, 24, 43, 17, 2, 1)
			if id == "brindlewick":
				for foot in range(6):
					r.box(im, 6 + foot * 6, 34, 4, 9, 0)
					r.box(im, 7 + foot * 6, 36, 2, 6, 8)
				for side in [-1, 1]:
					for leaf in range(4):
						r.line(im, Vector2i(24 + side * 10, 20 + bob), Vector2i(24 + side * (12 + leaf * 3), 4 + leaf * 3 + bob), 6)
					r.line(im, Vector2i(24 + side * 10, 20 + bob), Vector2i(24 + side * 11, 5 + bob), 5)
				r.oval(im, 24, 28 + bob, 19, 13, 0)
				r.oval(im, 23, 27 + bob, 17, 11, 7)
				for plate in range(5):
					var x := 8 + plate * 6
					r.poly(im, [Vector2i(x, 23 + bob), Vector2i(x + 4, 17 + bob), Vector2i(x + 8, 28 + bob), Vector2i(x + 3, 37 + bob), Vector2i(x - 1, 31 + bob)], 8)
					r.line(im, Vector2i(x + 1, 23 + bob), Vector2i(x + 4, 20 + bob), 9)
					r.line(im, Vector2i(x + 3, 27 + bob), Vector2i(x + 3, 33 + bob), 7)
				r.box(im, 14, 35 + bob, 7, 2, 5)
			elif id == "cindrel":
				for side in [-1, 1]:
					for foot in range(2):
						var x: int = 24 + side * (8 + foot * 5)
						r.line(im, Vector2i(x, 31 + bob), Vector2i(x + side * 3, 41), 0)
						r.line(im, Vector2i(x + side * 3, 41), Vector2i(x, 42), 9)
					var points := [Vector2i(24 + side * 2, 26 + bob), Vector2i(24 + side * 13, 12 + bob), Vector2i(24 + side * 20, 31 + bob), Vector2i(24 + side * 7, 37 + bob)]
					r.poly(im, points, 0)
					r.poly(im, [points[0] + Vector2i(side * 2, 0), points[1] + Vector2i(0, 3), points[2] + Vector2i(-side * 3, -1), points[3]], 14)
					r.line(im, points[1] + Vector2i(0, 4), points[2] + Vector2i(-side * 4, -2), 15)
					r.line(im, Vector2i(24 + side * 6, 19 + bob), Vector2i(24 + side * 10, 5 + bob), 7)
					r.box(im, 23 + side * 10, 3 + bob, 3, 4, 12)
					r.pixel(im, 24 + side * 10, 3 + bob, 13)
				r.oval(im, 24, 29 + bob, 9, 13, 0)
				r.oval(im, 23, 28 + bob, 7, 11, 8)
				r.oval(im, 22, 24 + bob, 5, 7, 9)
				for y in [20, 25, 30]:
					r.box(im, 21, y + bob, 6, 2, 7)
					r.box(im, 22, y + bob, 4, 1, 13)
				if back == 0:
					r.oval(im, 24, 34 + bob, 8, 6, 7)
					for x in [20, 27]:
						r.box(im, x, 32 + bob, 3, 3, 0)
						r.pixel(im, x, 32 + bob, 13)
					r.box(im, 23, 37 + bob, 3, 1, 12)
			elif id == "rillume":
				r.poly(im, [Vector2i(3, 31 + bob), Vector2i(8, 22 + bob), Vector2i(16, 24 + bob), Vector2i(24, 17 + bob), Vector2i(36, 21 + bob), Vector2i(44, 29 + bob), Vector2i(39, 38 + bob), Vector2i(12, 40 + bob)], 0)
				r.poly(im, [Vector2i(5, 31 + bob), Vector2i(10, 25 + bob), Vector2i(17, 27 + bob), Vector2i(24, 20 + bob), Vector2i(35, 24 + bob), Vector2i(41, 30 + bob), Vector2i(37, 36 + bob), Vector2i(13, 38 + bob)], 10)
				r.oval(im, 25, 31 + bob, 13, 6, 11)
				r.line(im, Vector2i(13, 29 + bob), Vector2i(27, 26 + bob), 3)
				# River-pebble sail and asymmetric reed gills.
				r.poly(im, [Vector2i(18, 25 + bob), Vector2i(21, 8 + bob), Vector2i(28, 12 + bob), Vector2i(31, 25 + bob)], 0)
				r.poly(im, [Vector2i(20, 23 + bob), Vector2i(22, 11 + bob), Vector2i(26, 14 + bob), Vector2i(28, 23 + bob)], 2)
				r.line(im, Vector2i(22, 12 + bob), Vector2i(23, 19 + bob), 3)
				for gill in range(3):
					r.line(im, Vector2i(10, 31 + bob), Vector2i(5 + gill * 3, 15 + gill * 2 + bob), 6)
					r.box(im, 4 + gill * 3, 14 + gill * 2 + bob, 2, 4, 9)
				if back == 0:
					for x in [30, 37]:
						r.box(im, x, 29 + bob, 2, 3, 0)
						r.pixel(im, x, 29 + bob, 3)
					r.line(im, Vector2i(31, 34 + bob), Vector2i(35, 34 + bob), 10)
				else:
					r.line(im, Vector2i(15, 33 + bob), Vector2i(35, 33 + bob), 10)
			if frame == 2 and back == 0 and id != "brindlewick":
				var ey: int = 32 if id == "cindrel" else 29
				for x in ([20, 27] if id == "cindrel" else [30, 37]): r.line(im, Vector2i(x, ey + bob), Vector2i(x + 2, ey + bob), 9 if id == "cindrel" else 11)
			atlas.blit_rect(im, Rect2i(0, 0, 48, 48), Vector2i(frame * 48, back * 48))
	return atlas

static func effects() -> Image:
	var r := Base.new()
	var atlas := r.blank(192, 96)
	var old := r.effects()
	atlas.blit_rect(old, Rect2i(0, 16, 192, 16), Vector2i(0, 16))
	atlas.blit_rect(old, Rect2i(0, 32, 192, 16), Vector2i(0, 64))
	for row in [0, 2, 3, 5]:
		for frame in range(4):
			var im := r.blank(48, 16)
			for particle in range(5):
				var x := 12 + particle * 5 + (particle - 2) * frame
				var y := 8 + (particle % 2 * 2 - 1) * frame
				if row == 0:
					r.line(im, Vector2i(24, 8), Vector2i(x, y), 13)
				elif row == 2:
					r.poly(im, [Vector2i(x, y + 3), Vector2i(x - 2, y), Vector2i(x + 1, y - 4), Vector2i(x + 3, y + 1)], 12)
					r.pixel(im, x, y, 13)
				elif row == 3:
					r.line(im, Vector2i(x, y + 2), Vector2i(x + 2, y - 2), 11)
					r.pixel(im, x + 2, y - 2, 3)
				else:
					r.line(im, Vector2i(x - 2, y), Vector2i(x + 2, y), 6)
					r.line(im, Vector2i(x, y - 2), Vector2i(x, y + 2), 6)
			atlas.blit_rect(im, Rect2i(0, 0, 48, 16), Vector2i(frame * 48, row * 16))
	return atlas

static func background() -> Image:
	var r := Base.new()
	var im := r.blank(320, 106)
	r.box(im, 0, 0, 320, 106, 4)
	var tree := r.objects().get_region(Rect2i(0, 0, 48, 64))
	for x in range(-20, 340, 52):
		im.blend_rect(tree, Rect2i(0, 0, 48, 64), Vector2i(x, -12))
	r.poly(im, [Vector2i(0, 73), Vector2i(98, 63), Vector2i(197, 72), Vector2i(319, 58), Vector2i(319, 105), Vector2i(0, 105)], 5)
	for x in range(4, 319, 13):
		var y := 74 + (x * 7) % 28
		r.line(im, Vector2i(x, y), Vector2i(x - 2, y - 4), 4)
		r.line(im, Vector2i(x, y), Vector2i(x + 3, y - 5), 6)
	for center: Vector2i in [Vector2i(65, 97), Vector2i(258, 60)]:
		r.oval(im, center.x, center.y, 33, 6, 4)
		r.oval(im, center.x, center.y - 1, 28, 4, 9)
		r.line(im, center + Vector2i(-19, -1), center + Vector2i(-8, -2), 8)
	return im

static func images() -> Dictionary:
	var result := {"brindlewick": monster("brindlewick"), "cindrel": monster("cindrel"), "rillume": monster("rillume"), "effects": effects(), "arena": background()}
	var r := Base.new()
	var icons := r.blank(80, 16)
	for index in range(3):
		var image: Image = result[IDS[index]].get_region(Rect2i(0, 0, 48, 48))
		image.resize(16, 16, Image.INTERPOLATE_NEAREST)
		icons.blit_rect(image, Rect2i(0, 0, 16, 16), Vector2i(index * 16, 0))
	icons.blit_rect(r.ui(), Rect2i(110, 0, 12, 12), Vector2i(50, 2))
	r.box(icons, 68, 3, 8, 11, 0)
	r.box(icons, 69, 4, 6, 9, 5)
	r.box(icons, 69, 2, 6, 2, 9)
	r.box(icons, 71, 5, 2, 6, 3)
	r.box(icons, 69, 7, 6, 2, 3)
	result.icons = icons
	return result
