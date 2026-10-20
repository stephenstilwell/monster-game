extends RefCounted
const Base = preload("res://tools/art/art_recipes.gd")
const Battle = preload("res://tools/art/battle_recipes.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Pipeline = preload("res://tools/art/asset_pipeline.gd")
const Stable = preload("res://tools/art/stable_resource.gd")

static func form(id: String) -> Image:
	var index: int = Meta.FORMS.values().find(id)
	var image: Image = Battle.monster(Meta.BASES[index])
	var r := Base.new()
	for back in range(2):
		for frame in range(8):
			var im: Image = image.get_region(Rect2i(frame * 48, back * 48, 48, 48))
			var bob: int = [0, 0, -1, 0, 0, -2, -1, 0][frame]
			if index == 0:
				# Mature bark guardian: broad moss mantle and branching crown, no royal crest.
				for side in [-1, 1]:
					r.poly(im, [Vector2i(24 + side * 6, 27 + bob), Vector2i(24 + side * 21, 17 + bob), Vector2i(24 + side * 19, 31 + bob), Vector2i(24 + side * 8, 35 + bob)], 4)
					for leaf in range(3):
						r.line(im, Vector2i(24 + side * 8, 16 + bob), Vector2i(24 + side * (12 + leaf * 4), 3 + leaf * 3 + bob), 8)
						r.oval(im, 24 + side * (12 + leaf * 4), 4 + leaf * 3 + bob, 3, 2, 6)
				for x in [14, 21, 28, 35]: r.line(im, Vector2i(x, 24 + bob), Vector2i(x - 2, 30 + bob), 9)
			elif index == 1:
				# Adult ember moth: scalloped outer wings and a lit abdomen.
				for side in [-1, 1]:
					r.poly(im, [Vector2i(24 + side * 8, 29 + bob), Vector2i(24 + side * 21, 8 + bob), Vector2i(24 + side * 22, 34 + bob), Vector2i(24 + side * 15, 39 + bob)], 0)
					r.poly(im, [Vector2i(24 + side * 10, 28 + bob), Vector2i(24 + side * 20, 12 + bob), Vector2i(24 + side * 20, 32 + bob), Vector2i(24 + side * 15, 36 + bob)], 14)
					r.line(im, Vector2i(24 + side * 18, 16 + bob), Vector2i(24 + side * 13, 33 + bob), 12)
					r.oval(im, 24 + side * 16, 27 + bob, 3, 4, 13)
					r.oval(im, 24 + side * 16, 27 + bob, 1, 2, 8)
				r.box(im, 22, 18 + bob, 4, 12, 12)
				r.box(im, 23, 19 + bob, 2, 10, 13)
			else:
				# Brook ray: translucent-looking stepped fins, long paired ribbon tails.
				for side in [-1, 1]:
					r.poly(im, [Vector2i(24 + side * 5, 26 + bob), Vector2i(24 + side * 19, 9 + bob), Vector2i(24 + side * 22, 28 + bob), Vector2i(24 + side * 12, 34 + bob)], 0)
					r.poly(im, [Vector2i(24 + side * 7, 25 + bob), Vector2i(24 + side * 18, 13 + bob), Vector2i(24 + side * 20, 27 + bob), Vector2i(24 + side * 12, 31 + bob)], 10)
					r.line(im, Vector2i(24 + side * 18, 16 + bob), Vector2i(24 + side * 11, 28 + bob), 11)
					r.line(im, Vector2i(24 + side * 10, 33 + bob), Vector2i(24 + side * 17, 41 + bob), 11)
					r.line(im, Vector2i(24 + side * 17, 41 + bob), Vector2i(24 + side * 21, 38 + bob), 3)
				r.oval(im, 24, 24 + bob, 3, 4, 3)
			image.blit_rect(im, Rect2i(0, 0, 48, 48), Vector2i(frame * 48, back * 48))
	return image

static func fixtures() -> Image:
	var r := Base.new()
	var im := r.blank(432, 48)
	for project in range(3):
		for state in range(3):
			var x := (project * 3 + state) * 48
			var wood := 8 if state == 2 else 7
			r.oval(im, x + 24, 43, 21, 3, 1)
			for post in [8, 37]:
				r.box(im, x + post, 27, 3, 16, 0)
				r.box(im, x + post + 1, 28, 1, 14, wood)
			r.box(im, x + 6, 24, 36, 8, 0)
			r.box(im, x + 7, 25, 34, 5, wood)
			r.line(im, Vector2i(x + 8, 26), Vector2i(x + 39, 26), 9)
			if project == 0:
				r.box(im, x + 12, 14, 25, 13, 0)
				r.box(im, x + 13, 15, 23, 10, 9)
				r.line(im, Vector2i(x + 15, 22), Vector2i(x + 22, 17), 5)
				r.line(im, Vector2i(x + 22, 17), Vector2i(x + 33, 21), 5)
			elif project == 1:
				r.oval(im, x + 16, 19, 6, 8, 0)
				r.oval(im, x + 16, 18, 4, 6, 12 if state == 2 else 8)
				r.box(im, x + 27, 15, 8, 11, 0)
				r.box(im, x + 28, 16, 6, 8, 5)
				r.box(im, x + 29, 13, 4, 4, 9)
			else:
				r.box(im, x + 9, 4, 31, 4, 0)
				r.box(im, x + 10, 5, 29, 2, wood)
				for lantern in [14, 24, 34]:
					r.line(im, Vector2i(x + lantern, 7), Vector2i(x + lantern, 12), 9)
					r.oval(im, x + lantern, 18, 4, 6, 0)
					r.oval(im, x + lantern, 17, 2, 4, 13 if state == 2 else 2)
			if state == 0:
				for y in [14, 20]: r.line(im, Vector2i(x + 8, y), Vector2i(x + 39, y + 10), 7)
			if state == 1: r.oval(im, x + 39, 10, 3, 4, 13)
			if state == 2:
				r.box(im, x + 19, 32, 10, 8, 5)
				r.line(im, Vector2i(x + 21, 35), Vector2i(x + 23, 37), 13)
				r.line(im, Vector2i(x + 23, 37), Vector2i(x + 27, 33), 13)
	return im

static func tokens() -> Image:
	var r := Base.new()
	var im := r.blank(240, 32)
	for i in range(7):
		var x := i * 32 + 16
		r.oval(im, x, 17, 11, 12, 0)
		r.oval(im, x, 16, 9, 10, 9 if i < 4 else 5)
		r.oval(im, x, 16, 7, 8, 8 if i < 4 else 4)
		if i == 0:
			for side in [-1, 1]: r.line(im, Vector2i(x, 23), Vector2i(x + side * 5, 10), 13)
			r.box(im, x - 1, 9, 3, 15, 13)
		elif i == 1:
			r.poly(im, [Vector2i(x - 6, 16), Vector2i(x + 4, 8), Vector2i(x + 5, 18), Vector2i(x - 2, 24)], 6)
			r.line(im, Vector2i(x - 3, 21), Vector2i(x + 3, 11), 13)
		elif i == 2:
			r.poly(im, [Vector2i(x - 6, 20), Vector2i(x - 2, 8), Vector2i(x + 2, 15), Vector2i(x + 5, 11), Vector2i(x + 6, 21), Vector2i(x, 25)], 12)
			r.line(im, Vector2i(x, 22), Vector2i(x, 15), 13)
		elif i == 3:
			for y in [13, 18]:
				r.line(im, Vector2i(x - 6, y), Vector2i(x - 1, y - 2), 11)
				r.line(im, Vector2i(x - 1, y - 2), Vector2i(x + 6, y + 1), 11)
		elif i == 4:
			r.line(im, Vector2i(x - 4, 16), Vector2i(x - 1, 20), 13)
			r.line(im, Vector2i(x - 1, 20), Vector2i(x + 5, 11), 13)
		else:
			r.box(im, x - 9, 3, 3, 27, 9)
			r.poly(im, [Vector2i(x - 6, 5), Vector2i(x + 10, 5), Vector2i(x + 6, 13), Vector2i(x + 10, 22), Vector2i(x - 6, 22)], 0)
			r.poly(im, [Vector2i(x - 5, 6), Vector2i(x + 8, 6), Vector2i(x + 4, 13), Vector2i(x + 8, 20), Vector2i(x - 5, 20)], 5 if i == 5 else 14)
			for stripe in range(i - 4): r.box(im, x - 2 + stripe * 4, 9, 2, 9, 13)
	return im

static func springs() -> Image:
	var r := Base.new()
	var im := r.blank(192, 32)
	for i in range(6):
		var x := i * 32 + 16
		r.oval(im, x, 24, 14, 7, 0)
		r.oval(im, x, 22, 12, 6, 7)
		r.oval(im, x, 21, 9, 4, 10 if i % 2 == 0 else 2)
		r.line(im, Vector2i(x - 5, 20), Vector2i(x + 3, 20), 11 if i % 2 == 0 else 7)
		for side in [-1, 1]:
			r.line(im, Vector2i(x + side * 11, 23), Vector2i(x + side * 9, 10), 5)
			r.line(im, Vector2i(x + side * 9, 17), Vector2i(x + side * 5, 13), 6)
		if i / 2 == 1:
			for side in [-1, 1]:
				r.poly(im, [Vector2i(x, 23), Vector2i(x + side * 10, 10), Vector2i(x + side * 8, 23)], 5 if i % 2 else 6)
				r.line(im, Vector2i(x, 23), Vector2i(x + side * 8, 13), 9)
		elif i / 2 == 2:
			r.box(im, x - 5, 2, 10, 21, 0)
			r.box(im, x - 4, 3, 8, 17, 8)
			r.oval(im, x, 11, 3, 6, 13 if i % 2 == 0 else 2)
			r.box(im, x - 7, 1, 14, 3, 9)
	return im

static func relics() -> Image:
	var r := Base.new()
	var im := r.blank(144, 24)
	var old := Image.new()
	old.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/m5/relics.png"))
	im.blit_rect(old, Rect2i(0, 0, 72, 24), Vector2i.ZERO)
	r.poly(im, [Vector2i(84, 2), Vector2i(92, 10), Vector2i(88, 21), Vector2i(78, 18), Vector2i(76, 8)], 0)
	r.poly(im, [Vector2i(84, 4), Vector2i(90, 10), Vector2i(87, 19), Vector2i(80, 17), Vector2i(78, 9)], 14)
	r.line(im, Vector2i(84, 5), Vector2i(82, 17), 13)
	for offset in range(5):
		r.line(im, Vector2i(101 + offset * 2, 21 - offset * 3), Vector2i(110 + offset, 13 - offset * 2), 13 if offset % 2 else 9)
	r.line(im, Vector2i(101, 22), Vector2i(116, 2), 8)
	r.oval(im, 132, 13, 8, 10, 0)
	r.oval(im, 132, 12, 6, 8, 6)
	r.line(im, Vector2i(128, 18), Vector2i(135, 5), 13)
	for y in [9, 13]: r.line(im, Vector2i(131, y + 3), Vector2i(136, y), 5)
	return im

static func tone(path: String, notes: Array, beat: float, looped: bool) -> Dictionary:
	var pcm := PackedByteArray()
	var count := int(notes.size() * beat * 22050)
	pcm.resize(count * 2)
	var peak := 0
	for i in range(count):
		var t := float(i) / 22050.0
		var note: int = notes[mini(int(t / beat), notes.size() - 1)]
		var f := 440.0 * pow(2.0, (note - 69) / 12.0)
		var local := fmod(t, beat)
		var envelope := minf(local / 0.012, 1.0) * maxf(0.0, 1.0 - local / beat)
		var wave := sin(TAU * f * t) * 0.16 + sin(TAU * f * 2 * t) * 0.04 + sin(TAU * f * 0.5 * t) * 0.06
		var value := int(clampf(wave * envelope, -0.95, 0.95) * 32767)
		peak = maxi(peak, absi(value))
		pcm.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = pcm
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	assert(wav.save_to_wav(path) == OK)
	return {"samples": count, "rate": 22050, "peak": peak, "loop": looped, "sha256": Pipeline.digest(pcm)}

static func generate(folder: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(folder)
	var manifest := {"version": "m6.1", "seed": 842031, "palette": "woodland16", "assets": {}, "regions": {}, "audio": {}, "animations": {}}
	var portraits := Base.new().blank(72, 24)
	for i in range(3):
		var resting := Battle.monster(Meta.BASES[i]).get_region(Rect2i(0, 0, 48, 48))
		resting.resize(24, 24, Image.INTERPOLATE_NEAREST)
		portraits.blit_rect(resting, Rect2i(0, 0, 24, 24), Vector2i(i * 24, 0))
	var images := {"shelter": portraits, "fixtures": fixtures(), "tokens": tokens(), "springs": springs(), "relics": relics()}
	for id: String in Meta.FORMS.values():
		images[id] = form(id)
		for back in range(2):
			for react in range(2):
				var name := id + ("_back_" if back else "_front_") + ("react" if react else "idle")
				manifest.animations[name] = {"asset": id, "frames": 4, "fps": 10 if react else 4, "size": [48, 48], "anchor": [24, 43], "row": back, "first": react * 4}
	for id: String in images:
		var im: Image = images[id]
		assert(im.save_png(folder + "/" + id + ".png") == OK)
		manifest.assets[id] = {"size": [im.get_width(), im.get_height()], "sha256": Pipeline.digest(im.get_data())}
	for i in range(3): manifest.regions["shelter_" + Meta.BASES[i]] = {"asset": "shelter", "rect": [i * 24, 0, 24, 24], "anchor": [12, 23]}
	for project in range(3):
		for state in range(3): manifest.regions["m6_" + Meta.PROJECTS.keys()[project] + "_%s" % state] = {"asset": "fixtures", "rect": [(project * 3 + state) * 48, 0, 48, 48], "anchor": [24, 47]}
	for i in range(6): manifest.regions["m6_stop_%s" % (i / 2) + ("_spent" if i % 2 else "")] = {"asset": "springs", "rect": [i * 32, 0, 32, 32], "anchor": [16, 31]}
	for i in range(6): manifest.regions[Meta.RELICS.keys()[i]] = {"asset": "relics", "rect": [i * 24, 0, 24, 24], "anchor": [0, 0]}
	for i in range(7): manifest.regions[["mark", "medal_0", "medal_1", "medal_2", "stamp", "tier_1", "tier_2"][i]] = {"asset": "tokens", "rect": [i * 32, 0, 32, 32], "anchor": [0, 0]}
	var tunes := {"hub": [60, 64, 67, 72, 67, 64, 62, 67, 59, 62, 67, 71, 67, 62, 64, 60], "forest": [57, 64, 60, 67, 59, 64, 62, 69, 57, 60, 64, 67, 55, 62, 59, 64], "battle": [57, 57, 64, 60, 59, 59, 65, 62, 57, 64, 69, 67, 65, 62, 59, 64], "confirm": [72, 79], "capture": [60, 64, 67, 72], "victory": [60, 64, 67, 72, 76, 79], "hit": [48, 43], "growth": [60, 62, 64, 67, 72, 76], "defeat": [60, 55, 52, 48]}
	for id: String in tunes: manifest.audio[id] = tone(folder + "/" + id + ".wav", tunes[id], 0.5 if id in ["hub", "forest", "battle"] else 0.09, id in ["hub", "forest", "battle"])
	assert(Pipeline.write_text(folder + "/manifest.json", JSON.stringify(manifest, "\t", true) + "\n") == OK)
	return manifest

static func assemble(folder: String) -> void:
	for id: String in Meta.FORMS.values():
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for back in range(2):
			for react in range(2):
				var name := id + ("_back_" if back else "_front_") + ("react" if react else "idle")
				frames.add_animation(name)
				frames.set_animation_speed(name, 10 if react else 4)
				frames.set_animation_loop(name, not react)
				for i in range(4):
					var tex := AtlasTexture.new()
					tex.atlas = load(folder + "/" + id + ".png")
					tex.region = Rect2((i + react * 4) * 48, back * 48, 48, 48)
					frames.add_frame(name, tex)
		assert(Stable.save(frames, folder + "/" + id + "_frames.tres") == OK)
