extends RefCounted
## Pure, seeded raster recipes. All positions are native-resolution integer pixels.
const VERSION := "m1.3"
const SEED := 842031
const HEX := ["20283d", "344052", "647577", "edf0d5", "294f46", "47785a", "80a568", "6b493f", "a16c4d", "cca878", "365c83", "66a6b4", "d99145", "f4d47e", "975779", "d58c93"]
const GLYPHS := {
" ":"00000/00000/00000/00000/00000/00000/00000",
"A":"01110/10001/10001/11111/10001/10001/10001", "B":"11110/10001/10001/11110/10001/10001/11110",
"C":"01111/10000/10000/10000/10000/10000/01111", "D":"11110/10001/10001/10001/10001/10001/11110",
"E":"11111/10000/10000/11110/10000/10000/11111", "F":"11111/10000/10000/11110/10000/10000/10000",
"G":"01111/10000/10000/10111/10001/10001/01111", "H":"10001/10001/10001/11111/10001/10001/10001",
"I":"111/010/010/010/010/010/111", "J":"00111/00010/00010/00010/10010/10010/01100",
"K":"10001/10010/10100/11000/10100/10010/10001", "L":"10000/10000/10000/10000/10000/10000/11111",
"M":"10001/11011/10101/10101/10001/10001/10001", "N":"10001/11001/10101/10011/10001/10001/10001",
"O":"01110/10001/10001/10001/10001/10001/01110", "P":"11110/10001/10001/11110/10000/10000/10000",
"Q":"01110/10001/10001/10001/10101/10010/01101", "R":"11110/10001/10001/11110/10100/10010/10001",
"S":"01111/10000/10000/01110/00001/00001/11110", "T":"11111/00100/00100/00100/00100/00100/00100",
"U":"10001/10001/10001/10001/10001/10001/01110", "V":"10001/10001/10001/10001/10001/01010/00100",
"W":"10001/10001/10001/10101/10101/10101/01010", "X":"10001/10001/01010/00100/01010/10001/10001",
"Y":"10001/10001/01010/00100/00100/00100/00100", "Z":"11111/00001/00010/00100/01000/10000/11111",
"0":"01110/10001/10011/10101/11001/10001/01110", "1":"00100/01100/00100/00100/00100/00100/01110",
"2":"01110/10001/00001/00010/00100/01000/11111", "3":"11110/00001/00001/01110/00001/00001/11110",
"4":"00010/00110/01010/10010/11111/00010/00010", "5":"11111/10000/10000/11110/00001/00001/11110",
"6":"01110/10000/10000/11110/10001/10001/01110", "7":"11111/00001/00010/00100/01000/01000/01000",
"8":"01110/10001/10001/01110/10001/10001/01110", "9":"01110/10001/10001/01111/00001/00001/01110",
".":"000/000/000/000/000/000/010", ",":"000/000/000/000/000/010/100",
":":"000/010/000/000/010/000/000", "!":"010/010/010/010/010/000/010",
"?":"01110/10001/00001/00010/00100/00000/00100", "-":"00000/00000/00000/11111/00000/00000/00000",
"/":"00001/00001/00010/00100/01000/10000/10000", "+":"00000/00100/00100/11111/00100/00100/00000",
"<":"00010/00100/01000/10000/01000/00100/00010", ">":"01000/00100/00010/00001/00010/00100/01000",
"'":"010/010/100/000/000/000/000", "[":"110/100/100/100/100/100/110", "]":"011/001/001/001/001/001/011"
}
var palette: Array[Color] = []
var rng := RandomNumberGenerator.new()

func _init() -> void:
	for value: String in HEX:
		palette.append(Color.html(value))
	rng.seed = SEED

func blank(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

func pixel(im: Image, x: int, y: int, color: int) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, palette[color])

func box(im: Image, x: int, y: int, w: int, h: int, color: int) -> void:
	var area := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, im.get_width(), im.get_height()))
	if area.has_area():
		im.fill_rect(area, palette[color])

func line(im: Image, a: Vector2i, b: Vector2i, color: int) -> void:
	var steps: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(steps + 1):
		var p: Vector2i = a if steps == 0 else Vector2i(Vector2(a).lerp(Vector2(b), float(i) / steps).round())
		pixel(im, p.x, p.y, color)

func oval(im: Image, cx: int, cy: int, rx: int, ry: int, color: int) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if float((x - cx) * (x - cx)) / (rx * rx) + float((y - cy) * (y - cy)) / (ry * ry) <= 1.0:
				pixel(im, x, y, color)

func poly(im: Image, points: Array, color: int) -> void:
	var polygon := PackedVector2Array()
	for p: Vector2i in points:
		polygon.append(Vector2(p))
	for y in range(im.get_height()):
		for x in range(im.get_width()):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				pixel(im, x, y, color)
	for i in range(points.size()):
		line(im, points[i], points[(i + 1) % points.size()], color)

func player() -> Image:
	var atlas := blank(80, 96)
	for facing in range(4):
		for frame in range(5):
			var im := blank(16, 24)
			var step: int = [0, -1, 0, 1, 0][frame]
			oval(im, 8, 22, 5, 1, 1)
			box(im, 5, 17, 3, 5 + mini(step, 0), 0)
			box(im, 9, 17, 3, 5 - maxi(step, 0), 0)
			box(im, 5, 20 + mini(step, 0), 3, 2, 7)
			box(im, 9, 20 - maxi(step, 0), 3, 2, 7)
			poly(im, [Vector2i(5, 9), Vector2i(10, 9), Vector2i(13, 18), Vector2i(3, 18)], 0)
			poly(im, [Vector2i(5, 10), Vector2i(9, 10), Vector2i(11, 17), Vector2i(4, 17)], 14)
			box(im, 5, 10, 2, 6, 15)
			box(im, 3, 11 - step, 2, 5, 7)
			box(im, 11, 11 + step, 2, 5, 9)
			box(im, 6, 8, 4, 3, 9)
			oval(im, 8, 6, 4, 4, 0)
			oval(im, 8, 6, 3, 3, 9)
			box(im, 5, 3, 6, 2, 7)
			box(im, 4, 2, 7, 2, 0)
			box(im, 5, 2, 5, 1, 8)
			if facing == 0:
				pixel(im, 6, 6, 0)
				pixel(im, 9, 6, 0)
				box(im, 6, 9, 4, 2, 13)
			elif facing == 1:
				box(im, 5, 4, 6, 5, 7)
				box(im, 6, 4, 3, 3, 8)
				box(im, 6, 11, 4, 5, 8)
				box(im, 6, 11, 4, 1, 9)
			else:
				var eye_x: int = 5 if facing == 2 else 10
				pixel(im, eye_x, 6, 0)
				pixel(im, eye_x, 5, 3)
				box(im, 9 if facing == 2 else 4, 11, 3, 5, 8)
				box(im, 9 if facing == 2 else 4, 11, 3, 1, 9)
			line(im, Vector2i(10, 10), Vector2i(5, 16), 9)
			box(im, 10, 14, 3, 4, 0)
			box(im, 11, 15, 2, 2, 13)
			atlas.blit_rect(im, Rect2i(0, 0, 16, 24), Vector2i(frame * 16, facing * 24))
	return atlas

func creature() -> Image:
	var atlas := blank(384, 96)
	for variant in range(2):
		for frame in range(8):
			var im := blank(48, 48)
			var bob: int = [0, 0, -1, 0, 0, -2, -1, 0][frame]
			var bark: int = 8 if variant == 0 else 5
			var light: int = 9 if variant == 0 else 6
			oval(im, 24, 43, 18, 2, 1)
			# Six distinct articulated feet remain on the same baseline.
			for foot in range(6):
				var fx: int = 7 + foot * 6
				poly(im, [Vector2i(fx, 33 + bob), Vector2i(fx + 4, 33 + bob), Vector2i(fx + 4, 42), Vector2i(fx - 1, 42), Vector2i(fx - 2, 40)], 0)
				box(im, fx, 36 + bob, 3, 5 - bob, bark)
				box(im, fx, 41, 3, 1, light)
			# Fern fans: individual vanes, branching stalks and highlights.
			for side in [-1, 1]:
				var base := Vector2i(24 + side * 10, 20 + bob)
				for leaf in range(4):
					var tip := Vector2i(24 + side * (12 + leaf * 3), 4 + leaf * 3 + bob)
					poly(im, [base, tip, tip + Vector2i(-side * 4, 6)], 0)
					line(im, base, tip + Vector2i(-side, 2), 6)
				line(im, base, Vector2i(24 + side * 11, 6 + bob), 5)
			oval(im, 24, 28 + bob, 19, 13, 0)
			oval(im, 23, 27 + bob, 17, 11, bark)
			oval(im, 20, 24 + bob, 13, 8, light)
			# Layered mantle plates with asymmetric grain, not a plain ellipse.
			for plate in range(5):
				var px: int = 8 + plate * 6
				poly(im, [Vector2i(px, 23 + bob), Vector2i(px + 4, 19 + bob), Vector2i(px + 8, 26 + bob), Vector2i(px + 3, 33 + bob), Vector2i(px - 1, 29 + bob)], 7 if variant == 0 else 4)
				line(im, Vector2i(px + 1, 23 + bob), Vector2i(px + 4, 22 + bob), light)
				line(im, Vector2i(px + 2, 25 + bob), Vector2i(px + 3, 29 + bob), bark)
			oval(im, 26, 33 + bob, 11, 8, 0)
			oval(im, 26, 32 + bob, 10, 7, 4)
			oval(im, 24, 30 + bob, 8, 5, 5)
			for eye_x in [21, 31]:
				oval(im, eye_x, 31 + bob, 2, 2, 0)
				pixel(im, eye_x - 1, 30 + bob, 3)
			if frame == 2:
				line(im, Vector2i(19, 31 + bob), Vector2i(23, 31 + bob), 6)
				line(im, Vector2i(29, 31 + bob), Vector2i(33, 31 + bob), 6)
			oval(im, 26, 37 + bob, 3, 2, 12)
			box(im, 24, 36 + bob, 4, 2, 13)
			pixel(im, 25, 36 + bob, 3)
			pixel(im, 26, 33 + bob, 9)
			if frame >= 4:
				line(im, Vector2i(39, 14), Vector2i(42, 11), 13)
				line(im, Vector2i(40, 10), Vector2i(40, 15), 13)
			atlas.blit_rect(im, Rect2i(0, 0, 48, 48), Vector2i(frame * 48, variant * 48))
	return atlas

func terrain() -> Image:
	var atlas := blank(128, 64)
	for tile in range(32):
		var im := blank(16, 16)
		var base: int = 5
		if tile in [2, 3]:
			base = 9
		elif tile >= 6:
			base = 10
		box(im, 0, 0, 16, 16, base)
		# Each tile owns its own stream; adding a tile cannot perturb others.
		rng.seed = SEED + tile * 101
		for cluster in range(4):
			var x := rng.randi_range(1, 13)
			var y := rng.randi_range(1, 14)
			if base == 5:
				line(im, Vector2i(x, y), Vector2i(x + 1, y - 1), 6 if cluster % 3 == 0 else 4)
			elif base == 9:
				box(im, x, y, 2, 1, 8 if cluster % 3 == 0 else 9)
			else:
				box(im, x, y, 3, 1, 11 if cluster % 3 == 0 else 10)
		if tile in [4, 5]:
			for tuft in range(4):
				var x := 2 + tuft * 4
				var y := 8 + (tuft % 2) * 6
				line(im, Vector2i(x, y), Vector2i(x - 1, y - 4), 4)
				line(im, Vector2i(x, y), Vector2i(x + 2, y - 5), 6)
		if tile >= 8 and tile < 24:
			var mask := tile - 8 # N E S W exposed bank edges.
			if mask & 1:
				box(im, 0, 0, 16, 2, 5)
				box(im, 0, 2, 16, 1, 9)
				box(im, 0, 3, 16, 1, 1)
			if mask & 4:
				box(im, 0, 14, 16, 2, 5)
				box(im, 0, 13, 16, 1, 9)
				box(im, 0, 12, 16, 1, 1)
			if mask & 8:
				box(im, 0, 0, 2, 16, 5)
				box(im, 2, 0, 1, 16, 9)
				box(im, 3, 0, 1, 16, 1)
			if mask & 2:
				box(im, 14, 0, 2, 16, 5)
				box(im, 13, 0, 1, 16, 9)
				box(im, 12, 0, 1, 16, 1)
		if tile >= 24 and tile <= 27:
			var cx: int = 0 if tile % 2 == 0 else 15
			var cy: int = 0 if tile < 26 else 15
			oval(im, cx, cy, 4, 4, 1)
			oval(im, cx, cy, 3, 3, 9)
			oval(im, cx, cy, 2, 2, 5)
		if tile >= 28:
			box(im, 0, 0, 16, 16, 5)
			box(im, 0, 5, 16, 6, 9)
			box(im, 0, 5, 16, 1, 8)
			box(im, 0, 10, 16, 1, 7)
			for x in range(0, 16, 4):
				box(im, x, 6, 1, 4, 8)
		atlas.blit_rect(im, Rect2i(0, 0, 16, 16), Vector2i(tile % 8 * 16, tile / 8 * 16))
	return atlas

func objects() -> Image:
	var atlas := blank(192, 96)
	var tree := blank(48, 64)
	oval(tree, 24, 59, 18, 3, 4)
	poly(tree, [Vector2i(20, 33), Vector2i(28, 33), Vector2i(29, 57), Vector2i(35, 60), Vector2i(14, 60), Vector2i(20, 55)], 0)
	box(tree, 21, 34, 6, 23, 7)
	box(tree, 21, 35, 2, 20, 8)
	line(tree, Vector2i(25, 40), Vector2i(25, 54), 9)
	for crown: Vector3i in [Vector3i(24, 16, 13), Vector3i(13, 29, 11), Vector3i(32, 29, 13), Vector3i(23, 37, 12)]:
		oval(tree, crown.x, crown.y, crown.z, 12, 0)
		oval(tree, crown.x, crown.y - 1, crown.z - 1, 10, 4)
		oval(tree, crown.x - 2, crown.y - 4, crown.z - 3, 7, 5)
		oval(tree, crown.x - 3, crown.y - 6, crown.z - 6, 3, 6)
		line(tree, Vector2i(crown.x - 6, crown.y + 4), Vector2i(crown.x - 2, crown.y + 6), 5)
	atlas.blit_rect(tree, Rect2i(0, 0, 48, 64), Vector2i.ZERO)
	var house := blank(64, 64)
	box(house, 7, 26, 50, 34, 0)
	box(house, 9, 26, 46, 31, 9)
	for y in range(30, 55, 7):
		box(house, 10, y, 44, 1, 8)
	for x in [10, 49]:
		box(house, x, 26, 4, 32, 7)
		box(house, x, 27, 1, 30, 8)
	poly(house, [Vector2i(1, 28), Vector2i(30, 4), Vector2i(62, 28)], 0)
	poly(house, [Vector2i(5, 26), Vector2i(30, 7), Vector2i(58, 26)], 4)
	for row in range(4):
		var y := 13 + row * 4
		var half := (y - 6)
		line(house, Vector2i(30 - half, y), Vector2i(30 + half, y), 5)
		for x in range(30 - half + 2, 30 + half - 1, 6):
			pixel(house, x, y - 1, 6)
	box(house, 26, 37, 13, 22, 0)
	box(house, 28, 38, 9, 19, 7)
	box(house, 29, 39, 2, 17, 8)
	pixel(house, 35, 49, 13)
	for x in [16, 43]:
		box(house, x, 36, 8, 10, 7)
		box(house, x + 1, 37, 6, 7, 10)
		box(house, x + 1, 37, 2, 3, 11)
		box(house, x + 3, 37, 1, 8, 9)
	box(house, 24, 58, 17, 3, 2)
	box(house, 24, 58, 17, 1, 3)
	line(house, Vector2i(40, 30), Vector2i(46, 30), 7)
	box(house, 44, 31, 5, 7, 0)
	box(house, 45, 32, 3, 4, 12)
	pixel(house, 46, 32, 13)
	atlas.blit_rect(house, Rect2i(0, 0, 64, 64), Vector2i(48, 0))
	var rock := blank(24, 16)
	oval(rock, 12, 13, 10, 2, 4)
	poly(rock, [Vector2i(3, 12), Vector2i(6, 5), Vector2i(14, 2), Vector2i(21, 9), Vector2i(19, 14), Vector2i(5, 14)], 0)
	poly(rock, [Vector2i(5, 11), Vector2i(8, 6), Vector2i(14, 4), Vector2i(19, 9), Vector2i(18, 12)], 2)
	line(rock, Vector2i(8, 6), Vector2i(13, 5), 3)
	line(rock, Vector2i(14, 6), Vector2i(13, 11), 1)
	atlas.blit_rect(rock, Rect2i(0, 0, 24, 16), Vector2i(112, 0))
	for x in range(3):
		var fx := 114 + x * 5
		line(atlas, Vector2i(fx, 33), Vector2i(fx + 1, 23 + x % 2 * 3), 4)
		box(atlas, fx - 1, 23 + x % 2 * 3, 4, 2, 15)
		pixel(atlas, fx, 23 + x % 2 * 3, 13)
	for x in [139, 153]:
		box(atlas, x, 10, 3, 18, 0)
		box(atlas, x, 10, 2, 17, 8)
		pixel(atlas, x, 10, 9)
	box(atlas, 137, 15, 22, 3, 7)
	box(atlas, 137, 15, 22, 1, 9)
	box(atlas, 137, 22, 22, 2, 8)
	return atlas

func ui() -> Image:
	var im := blank(128, 32)
	# 12x12 nine-slice panel with double border and corner studs.
	box(im, 0, 0, 12, 12, 0)
	box(im, 1, 1, 10, 10, 9)
	box(im, 2, 2, 8, 8, 1)
	box(im, 3, 3, 6, 6, 0)
	for x in [1, 10]:
		for y in [1, 10]:
			pixel(im, x, y, 13)
	poly(im, [Vector2i(18, 1), Vector2i(23, 5), Vector2i(18, 9)], 13)
	box(im, 28, 1, 32, 6, 0)
	box(im, 29, 2, 30, 4, 4)
	box(im, 29, 2, 24, 3, 6)
	box(im, 29, 2, 24, 1, 3)
	# Grove, ember, brook, status, lantern and dialogue icons.
	poly(im, [Vector2i(66, 8), Vector2i(65, 3), Vector2i(72, 0), Vector2i(73, 6)], 6)
	line(im, Vector2i(66, 9), Vector2i(71, 3), 4)
	poly(im, [Vector2i(80, 9), Vector2i(77, 5), Vector2i(81, 0), Vector2i(84, 6)], 12)
	pixel(im, 80, 6, 13)
	poly(im, [Vector2i(91, 0), Vector2i(87, 6), Vector2i(89, 9), Vector2i(93, 9), Vector2i(95, 6)], 11)
	pixel(im, 89, 6, 3)
	line(im, Vector2i(100, 1), Vector2i(106, 7), 15)
	line(im, Vector2i(106, 1), Vector2i(100, 7), 15)
	box(im, 112, 2, 7, 8, 9)
	box(im, 113, 3, 5, 5, 12)
	box(im, 114, 3, 2, 4, 13)
	poly(im, [Vector2i(2, 19), Vector2i(8, 19), Vector2i(5, 22)], 13)
	return im

func effects() -> Image:
	var atlas := blank(192, 48)
	for effect in range(3):
		for frame in range(4):
			var im := blank(48, 16)
			if effect == 0:
				var rad := 3 + frame
				for side in [-1, 1]:
					line(im, Vector2i(24 + side * rad, 5), Vector2i(24 + side * (rad + 2), 3), 13)
				box(im, 22, 5, 5, 7, 0)
				box(im, 23, 6, 3, 4, 12)
				pixel(im, 24, 6, 13)
			elif effect == 1:
				for leaf in range(4):
					var x := 12 + leaf * 6 + frame * (leaf - 1)
					var y := 5 + (leaf + frame) % 3
					poly(im, [Vector2i(x, y), Vector2i(x + 4, y - 2), Vector2i(x + 3, y + 2)], 6)
			else:
				oval(im, 24, 8, 6 + frame * 3, 2 + frame, 13)
				# Transparent interior, using an independent mask.
				for y in range(16):
					for x in range(48):
						if pow(float(x - 24) / (5 + frame * 3), 2) + pow(float(y - 8) / (1 + frame), 2) <= 1:
							im.set_pixel(x, y, Color.TRANSPARENT)
			atlas.blit_rect(im, Rect2i(0, 0, 48, 16), Vector2i(frame * 48, effect * 16))
	return atlas

func font_image() -> Image:
	var im := blank(96, 48)
	var chars: Array = GLYPHS.keys()
	chars.sort()
	for index in range(chars.size()):
		var rows: PackedStringArray = GLYPHS[chars[index]].split("/")
		for y in range(7):
			for x in range(rows[y].length()):
				if rows[y][x] == "1":
					im.set_pixel(index % 16 * 6 + x, index / 16 * 8 + y, Color.WHITE)
	return im

func icon_image() -> Image:
	var im := blank(32, 32)
	box(im, 2, 2, 28, 28, 0)
	box(im, 1, 4, 30, 24, 0)
	line(im, Vector2i(12, 8), Vector2i(12, 5), 9)
	line(im, Vector2i(12, 5), Vector2i(19, 5), 9)
	line(im, Vector2i(19, 5), Vector2i(19, 8), 9)
	poly(im, [Vector2i(9, 9), Vector2i(22, 9), Vector2i(24, 12), Vector2i(22, 25), Vector2i(9, 25), Vector2i(7, 12)], 7)
	box(im, 11, 11, 9, 12, 12)
	box(im, 12, 12, 3, 9, 13)
	box(im, 12, 12, 2, 4, 3)
	box(im, 8, 9, 16, 2, 9)
	box(im, 9, 24, 14, 2, 9)
	poly(im, [Vector2i(6, 22), Vector2i(3, 15), Vector2i(7, 17), Vector2i(9, 24)], 6)
	poly(im, [Vector2i(24, 24), Vector2i(25, 16), Vector2i(29, 13), Vector2i(28, 22)], 5)
	pixel(im, 27, 16, 6)
	return im

func images() -> Dictionary:
	return {"player": player(), "brindlewick": creature(), "terrain": terrain(), "objects": objects(), "ui": ui(), "effects": effects(), "font": font_image(), "icon": icon_image()}
