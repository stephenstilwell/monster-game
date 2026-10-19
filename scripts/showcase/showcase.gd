extends Node2D
## M1 visual viewer only. No movement, battle rules, inventory or save state.

const PAGE_NAMES := ["FIELD", "CREATURE", "BATTLE", "PARTY"]
const DIRECTIONS := ["south", "north", "west", "east"]
var page: int = 0
var variant: int = 0
var facing: int = 0
var paused: bool = false
var calm: bool = false
var reacting: bool = false
var walking: bool = true
var clock: float = 0.0
var reaction_clock: float = 0.0
var capture_mode: bool = false
var palette: Array[Color] = []
var textures: Dictionary = {}
var animations: Dictionary = {}
var manifest: Dictionary = {}
var font: Font
var panel_style: StyleBox

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	for value: String in manifest.palette:
		palette.append(Color.html(value))
	for id: String in manifest.assets:
		if id == "font":
			continue # BMFont importer embeds this mask and marks its PNG as skipped.
		textures[id] = load("res://assets/generated/" + manifest.assets[id].file)
	for id in ["player", "brindlewick", "effects"]:
		animations[id] = load("res://assets/generated/" + id + "_frames.tres")
	var theme: Theme = load("res://assets/generated/woodland_theme.tres")
	font = theme.default_font
	panel_style = theme.get_stylebox("panel", "Panel")
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	if capture_mode:
		call_deferred("_capture_sequence")

func _process(delta: float) -> void:
	if not paused:
		clock += delta
		if reacting:
			reaction_clock += delta
			if reaction_clock >= 0.4:
				reacting = false
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4: page = event.keycode - KEY_1
			KEY_TAB: page = posmod(page + (-1 if event.shift_pressed else 1), 4)
			KEY_SPACE: paused = not paused
			KEY_V: variant = 1 - variant
			KEY_R: calm = not calm
			KEY_A:
				reacting = true
				reaction_clock = 0.0
			KEY_I: walking = not walking
			KEY_DOWN: facing = 0
			KEY_UP: facing = 1
			KEY_LEFT: facing = 2
			KEY_RIGHT: facing = 3
			KEY_ESCAPE: get_tree().quit()
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_RIGHT_SHOULDER: page = (page + 1) % 4
			JOY_BUTTON_LEFT_SHOULDER: page = posmod(page - 1, 4)
			JOY_BUTTON_A: variant = 1 - variant
			JOY_BUTTON_B: walking = not walking
			JOY_BUTTON_X:
				reacting = true
				reaction_clock = 0.0
			JOY_BUTTON_Y: calm = not calm
			JOY_BUTTON_START: paused = not paused
			JOY_BUTTON_DPAD_DOWN: facing = 0
			JOY_BUTTON_DPAD_UP: facing = 1
			JOY_BUTTON_DPAD_LEFT: facing = 2
			JOY_BUTTON_DPAD_RIGHT: facing = 3

func fill(rect: Rect2, color: int) -> void:
	draw_rect(rect, palette[color])

func text(value: String, x: int, y: int, color: int = 3) -> void:
	for character: String in value:
		assert(character in manifest.glyphs, "Missing glyph: " + character)
	assert(x >= 0 and y >= 0 and x + value.length() * 6 <= 320 and y + 7 <= 180, "Text outside viewport: " + value)
	draw_string(font, Vector2(x, y + 7), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, palette[color])

func panel(x: int, y: int, w: int, h: int) -> void:
	draw_style_box(panel_style, Rect2(x, y, w, h))

func region(id: String, at: Vector2, scale_factor: int = 1) -> void:
	var spec: Dictionary = manifest.regions[id]
	var rect: Array = spec.rect
	draw_texture_rect_region(textures[spec.asset], Rect2(at, Vector2(rect[2], rect[3]) * scale_factor), Rect2(rect[0], rect[1], rect[2], rect[3]))

func frame(group: String, id: String, at: Vector2, scale_factor: int = 1, fixed: int = -1) -> void:
	var frames: SpriteFrames = animations[group]
	var tick: int = int(floor(clock * frames.get_animation_speed(id))) % frames.get_frame_count(id)
	if fixed >= 0:
		tick = fixed % frames.get_frame_count(id)
	var texture := frames.get_frame_texture(id, tick)
	draw_texture_rect(texture, Rect2(at, texture.get_size() * scale_factor), false)

func creature(at: Vector2, scale_factor: int = 1, color_variant: int = -1) -> void:
	var chosen: int = variant if color_variant < 0 else color_variant
	var state := "react" if reacting else "idle"
	frame("brindlewick", "brindlewick_%s_%s" % [chosen, state], at, scale_factor, mini(int(reaction_clock * 10), 3) if reacting else -1)

func tile(id: int, x: int, y: int) -> void:
	draw_texture_rect_region(textures.terrain, Rect2(x, y, 16, 16), Rect2(id % 8 * 16, id / 8 * 16, 16, 16))

func effect(id: String, x: int, y: int) -> void:
	frame("effects", id, Vector2(x, y), 1, 1 if calm else -1)

func health(x: int, y: int, width: int, ratio: float) -> void:
	fill(Rect2(x, y, width, 5), 0)
	fill(Rect2(x + 1, y + 1, width - 2, 3), 4)
	fill(Rect2(x + 1, y + 1, floori((width - 2) * ratio), 3), 6)
	fill(Rect2(x + 1, y + 1, floori((width - 2) * ratio), 1), 3)

func _draw() -> void:
	if font == null:
		return
	fill(Rect2(0, 0, 320, 180), 0)
	match page:
		0: draw_field()
		1: draw_creature()
		2: draw_battle()
		3: draw_party()
	# Persistent tab strip and concise controls stay outside page content.
	fill(Rect2(0, 0, 320, 19), 0)
	for index in range(4):
		var x := index * 80
		if page == index:
			fill(Rect2(x + 2, 2, 76, 14), 1)
			fill(Rect2(x + 2, 16, 76, 1), 13)
		text("%s %s" % [index + 1, PAGE_NAMES[index]], x + 5, 5, 13 if page == index else 2)
	fill(Rect2(0, 168, 320, 12), 0)
	text("TAB VIEW  SPACE " + ("PLAY" if paused else "PAUSE") + "  V COLOR  4 HELP", 5, 171, 9)
	if calm:
		text("CALM", 288, 171, 13)

func draw_field() -> void:
	for y in range(7):
		for x in range(20):
			var id: int = (x * 7 + y * 3) % 2
			if y >= 4 and (x >= 4 and x <= 10):
				id = 2 + (x + y) % 2
			if x > 10 and y in [4, 5]:
				id = 4 + x % 2
			if x >= 14 and x <= 18 and y >= 1 and y <= 5:
				var mask: int = (1 if y == 1 else 0) | (2 if x == 18 else 0) | (4 if y == 5 else 0) | (8 if x == 14 else 0)
				id = 8 + mask if mask else 6 + (x + y) % 2
			tile(id, x * 16, 19 + y * 16)
	region("waystation", Vector2(28, 26))
	for x in [98, 121]:
		region("fence", Vector2(x, 49))
	region("tree", Vector2(-9, 22))
	region("tree", Vector2(172, 17))
	region("tree", Vector2(279, 18))
	region("rock", Vector2(193, 100))
	for p in [Vector2(14, 103), Vector2(95, 91), Vector2(152, 110), Vector2(298, 102)]:
		region("flowers", p)
	frame("player", "player_%s_%s" % ["walk" if walking else "idle", DIRECTIONS[facing]], Vector2(119, 89))
	creature(Vector2(153, 78))
	effect("lantern", 92, 84)
	panel(5, 128, 310, 37)
	text("LANTERNWILD / WAYSTATION 01", 13, 135, 13)
	text("THE FOREST KEEPS A LITTLE LIGHT.", 13, 147)
	region("dialogue", Vector2(295, 149))
	text("VISUAL STUDY", 234, 22, 0)

func draw_creature() -> void:
	fill(Rect2(0, 19, 320, 149), 4)
	for x in range(0, 320, 16):
		tile((x / 16) % 2, x, 110)
	region("tree", Vector2(1, 24))
	region("tree", Vector2(126, 29))
	creature(Vector2(40, 30), 2)
	effect("leaf", 63, 115)
	panel(174, 27, 139, 94)
	text("BRINDLEWICK", 182, 35, 13)
	region("grove", Vector2(182, 48))
	text("GROVE / BARKLING", 195, 50, 6)
	text("6 FEET. 1 WARM HEART.", 182, 67)
	text("COLOR: " + ("MOSS" if variant else "AMBER"), 182, 80, 9)
	text("A REACT   V COLOR", 182, 94)
	text("R REDUCED FLASHING", 182, 106, 2)
	panel(5, 128, 310, 37)
	text("CREATURE STUDY / SAMPLE JOURNAL", 13, 135, 13)
	text("FERN FEELERS GLOW NEAR OLD TRAILS.", 13, 147)

func draw_battle() -> void:
	fill(Rect2(0, 19, 320, 105), 4)
	for x in [12, 101, 174, 268]:
		region("tree", Vector2(x, 20))
	fill(Rect2(0, 81, 320, 43), 5)
	for x in range(0, 320, 16):
		tile(x / 16 % 2, x, 108)
	panel(7, 26, 142, 37)
	text("WILD BRINDLEWICK", 15, 33, 13)
	text("GROVE", 15, 46, 6)
	text("LV 05", 105, 46)
	health(54, 48, 43, 0.74)
	creature(Vector2(224, 31))
	creature(Vector2(40, 75), 1, 1 - variant)
	effect("charm", 224, 68)
	panel(157, 86, 156, 37)
	text("BRINDLEWICK  LV 06", 165, 93)
	text("HP 28/32", 165, 106, 6)
	health(224, 108, 80, 0.875)
	panel(5, 127, 310, 38)
	text("SAMPLE BATTLE", 13, 135, 13)
	text("CHOOSE A COMMAND.", 13, 148)
	fill(Rect2(159, 133, 1, 25), 9)
	region("cursor", Vector2(166, 134))
	text("MOVES", 178, 135)
	text("CHARM", 248, 135)
	text("PARTY", 178, 149)
	text("LEAVE", 248, 149)

func draw_party() -> void:
	fill(Rect2(0, 19, 320, 149), 4)
	panel(5, 25, 310, 97)
	creature(Vector2(15, 30))
	text("01 BRINDLEWICK", 74, 34, 13)
	text("LV 06  GROVE", 74, 47, 6)
	health(74, 62, 135, 0.875)
	text("HP 28/32", 221, 61)
	text("02  OPEN COMPANION SLOT", 19, 82, 2)
	text("03  OPEN COMPANION SLOT", 19, 96, 2)
	text("04  OPEN COMPANION SLOT", 19, 110, 2)
	panel(5, 128, 310, 37)
	text("SHOWCASE ONLY / NO GAMEPLAY", 13, 135, 13)
	text("ARROWS FACE  I IDLE  A REACT  R CALM", 13, 147)

func _capture_sequence() -> void:
	var output := "res://artifacts/visual"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	paused = true
	clock = 0.0
	for index in range(4):
		page = index
		await capture(output.path_join("%s_%s.png" % [index + 1, PAGE_NAMES[index].to_lower()]))
	page = 1
	variant = 1
	await capture(output.path_join("5_moss_variant.png"))
	variant = 0
	reacting = true
	reaction_clock = 0.1
	await capture(output.path_join("6_reaction.png"))
	# Contact sheets preserve all frames for visual anchor/animation review.
	var sheet := Image.create(384, 336, false, Image.FORMAT_RGBA8)
	sheet.fill(palette[0])
	for entry: Array in [["player", Vector2i(8, 8)], ["brindlewick", Vector2i(0, 112)], ["terrain", Vector2i(8, 220)], ["objects", Vector2i(144, 220)], ["effects", Vector2i(192, 8)], ["ui", Vector2i(192, 68)], ["font", Vector2i(8, 288)], ["icon", Vector2i(128, 288)]]:
		var image := Image.new()
		image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/generated/" + entry[0] + ".png"))
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), entry[1])
	assert(sheet.save_png(output.path_join("contact_sheet.png")) == OK)
	sheet.resize(1152, 1008, Image.INTERPOLATE_NEAREST)
	assert(sheet.save_png(output.path_join("contact_sheet_3x.png")) == OK)
	await capture_motion_sheet(output)
	print("CAPTURE PASS: 6 native/3x views, atlas contact sheets and rendered animation sheet")
	get_tree().quit()

func capture(path: String) -> void:
	queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.get_size() == Vector2i(320, 180), "Capture must use native viewport")
	assert(image.save_png(path) == OK)
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(image.save_png(path.trim_suffix(".png") + "_3x.png") == OK)

func render_image() -> Image:
	queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func capture_motion_sheet(output: String) -> void:
	var motion := Image.create(344, 312, false, Image.FORMAT_RGBA8)
	motion.fill(palette[0])
	paused = true
	walking = true
	calm = false
	for row in range(4):
		for index in range(4):
			page = 0
			facing = row
			reacting = false
			clock = index / 8.0
			var walk_image: Image = await render_image()
			motion.blit_rect(walk_image, Rect2i(119, 89, 16, 24), Vector2i(8 + index * 24, 8 + row * 56))
			variant = row % 2
			reacting = row >= 2
			reaction_clock = index / 10.0
			clock = index / 4.0
			var creature_image: Image = await render_image()
			motion.blit_rect(creature_image, Rect2i(153, 78, 48, 48), Vector2i(112 + index * 56, 8 + row * 56))
	for effect_index in range(3):
		for index in range(4):
			page = [0, 1, 2][effect_index]
			reacting = false
			clock = (index + 0.01) / 6.0
			var snapshot: Image = await render_image()
			var positions := [Vector2i(92, 84), Vector2i(63, 115), Vector2i(224, 68)]
			motion.blit_rect(snapshot, Rect2i(positions[effect_index], Vector2i(48, 16)), Vector2i(112 + index * 56, 240 + effect_index * 20))
	assert(motion.save_png(output.path_join("animation_playback.png")) == OK)
	motion.resize(1032, 936, Image.INTERPOLATE_NEAREST)
	assert(motion.save_png(output.path_join("animation_playback_3x.png")) == OK)