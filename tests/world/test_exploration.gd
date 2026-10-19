extends SceneTree
const Maps = preload("res://tools/art/map_recipes.gd")
const Map = preload("res://scripts/world/map_definition.gd")
const Movement = preload("res://scripts/world/grid_movement.gd")
const Bindings = preload("res://scripts/world/exploration_input.gd")
const UI = preload("res://scripts/ui/pixel_ui.gd")
const Pipeline = preload("res://tools/art/exploration_pipeline.gd")
const Hash = preload("res://tools/art/asset_pipeline.gd")
const Scene = preload("res://scenes/world/exploration.tscn")
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func path_to(map: Map, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var pending: Array[Vector2i] = [start]
	var previous := {start: start}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if cell == goal:
			var path: Array[Vector2i] = []
			while cell != start:
				path.push_front(cell)
				cell = previous[cell]
			return path
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next := cell + direction
			if map.can_enter(next) and not previous.has(next) and (next == goal or map.portal_at(next).is_empty()):
				previous[next] = cell
				pending.append(next)
	return []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_generated_art()
	test_maps()
	test_movement()
	await test_scene()
	if failures.is_empty():
		print("M2 TEST PASS: %s assertions; deterministic art/maps, collision/connectivity, inputs, dialogue locks, bidirectional travel and safe recovery" % checks)
		quit()
	else:
		print("M2 TEST FAIL: %s of %s assertions" % [failures.size(), checks])
		quit(1)

func test_generated_art() -> void:
	var a := "res://.godot/m2_validation/a"
	var b := "res://.godot/m2_validation/b"
	check(not Pipeline.generate(a + "/assets", a + "/maps").has("error"), "Clean build A")
	check(not Pipeline.generate(b + "/assets", b + "/maps").has("error"), "Clean build B")
	var generated := FileAccess.get_file_as_string(a + "/assets/manifest.json")
	check(generated == FileAccess.get_file_as_string(b + "/assets/manifest.json"), "Clean manifests byte match")
	check(generated == FileAccess.get_file_as_string("res://assets/generated/m2/manifest.json"), "Persisted M2 manifest matches generator")
	var manifest: Dictionary = JSON.parse_string(generated)
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	var palette: Array[Color] = []
	for hex: String in base.palette:
		palette.append(Color.html(hex))
	var images := {}
	for id: String in manifest.assets:
		var bytes := FileAccess.get_file_as_bytes(a + "/assets/" + id + ".png")
		check(bytes == FileAccess.get_file_as_bytes(b + "/assets/" + id + ".png"), "Byte-identical generated art: " + id)
		check(bytes == FileAccess.get_file_as_bytes("res://assets/generated/m2/" + id + ".png"), "Baked art matches: " + id)
		var image := Image.new()
		check(image.load_png_from_buffer(bytes) == OK, "Decode " + id)
		images[id] = image
		check(Hash.digest(image.get_data()) == manifest.assets[id].pixel_sha256, "Digest " + id)
		var bad := false
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				if color.a != 0 and (color.a != 1 or not color in palette):
					bad = true
		check(not bad, "Palette and alpha " + id)
	for name: String in manifest.animations:
		var spec: Dictionary = manifest.animations[name]
		var frames: SpriteFrames = load("res://assets/generated/m2/" + spec.asset + "_frames.tres")
		check(frames.has_animation(name) and frames.get_frame_count(name) == spec.rects.size(), "NPC animation " + name)
		check(frames.get_animation_speed(name) == spec.fps, "NPC speed " + name)
		var image: Image = images[spec.asset]
		for rect: Array in spec.rects:
			var region := Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))
			check(Rect2i(Vector2i.ZERO, image.get_size()).encloses(region) and not image.get_region(region).is_invisible(), "NPC frame bounds " + name)
			check(image.get_pixel(region.position.x + 8, region.position.y + 23) == palette[1], "NPC stable anchor " + name)
	check(images.mara.get_data() != images.ivo.get_data(), "NPC designs differ")
	for id in ["town", "forest"]:
		var bytes := FileAccess.get_file_as_bytes(a + "/maps/" + id + ".tres")
		check(bytes == FileAccess.get_file_as_bytes(b + "/maps/" + id + ".tres"), "Map resources repeat byte-identically " + id)
		check(bytes == FileAccess.get_file_as_bytes("res://data/maps/" + id + ".tres"), "Baked map matches " + id)

func test_maps() -> void:
	var maps := {}
	var tiles: TileSet = load("res://assets/generated/m2/exploration_tileset.tres")
	var source: TileSetAtlasSource = tiles.get_source(1)
	check(source.get_tiles_count() == 2, "Bridge tiles assembled")
	for map in Maps.maps():
		maps[map.id] = map
		check(map.tiles.size() == map.size.x * map.size.y, "Map cell count " + map.id)
		check(map.can_enter(map.start) and map.portal_at(map.start).is_empty(), "Safe initial spawn " + map.id)
		for name: String in map.landmarks:
			check(not path_to(map, map.start, map.landmarks[name]).is_empty(), "Reachable " + map.id + "/" + name)
		for y in range(map.size.y):
			for x in range(map.size.x):
				var cell := Vector2i(x, y)
				var tile: int = map.tile_at(cell)
				check(tile >= 0 and tile < 34, "Terrain reference %s/%s" % [map.id, cell])
				var terrain_source: TileSetAtlasSource = tiles.get_source(0 if tile < 32 else 1)
				var coords := Vector2i(tile % 8, tile / 8) if tile < 32 else Vector2i(tile - 32, 0)
				if terrain_source.get_tile_data(coords, 0).get_collision_polygons_count(0) > 0:
					check(not map.can_enter(cell), "Grid and TileSet collision agree")
				if x == 0 or y == 0 or x == map.size.x - 1 or y == map.size.y - 1:
					check(not map.can_enter(cell) or not map.portal_at(cell).is_empty(), "Boundary has no unintended exit")
		check(not map.can_enter(Vector2i(-1, 5)) and not map.can_enter(map.size), "Out-of-map collision")
		for npc: Dictionary in map.npcs:
			check(not map.can_enter(npc.cell), "NPC occupies a cell")
		for entry: Dictionary in map.npcs + map.interactions:
			check(entry.name.length() <= 46, "Speaker label fits")
			for page: String in entry.pages:
				var lines := UI.wrap_lines(page)
				check(lines.size() <= 2, "Dialogue page fits " + entry.id)
				for line: String in lines:
					check(line.length() <= 46, "Dialogue line fits")
		var fallback := map.safe_spawn(Vector2i(-100, -100))
		check(map.can_enter(fallback) and map.portal_at(fallback).is_empty(), "Out-of-bounds spawn recovers")
	for map: Map in maps.values():
		for portal: Dictionary in map.portals:
			check(maps.has(portal.map), "Portal resolves map")
			var target: Map = maps[portal.map]
			check(target.can_enter(portal.spawn) and target.portal_at(portal.spawn).is_empty(), "Portal target is valid and cannot bounce")
	var wrapped := UI.wrap_lines("ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5)
	check(wrapped.size() == 6 and wrapped[0] == "ABCDE", "Long words cannot overflow UI")

func test_movement() -> void:
	var movement := Movement.new()
	movement.place(Vector2i(2, 2))
	var can_enter := func(cell: Vector2i) -> bool: return cell.x >= 0 and cell.x < 5 and cell.y >= 0 and cell.y < 5
	check(not movement.try_step(Vector2i.ONE, can_enter), "No diagonal movement")
	check(movement.try_step(Vector2i.RIGHT, can_enter), "Valid step reserves destination")
	check(not movement.try_step(Vector2i.DOWN, can_enter), "Cannot reserve second step mid-move")
	check(movement.cell == Vector2i(2, 2) and movement.destination == Vector2i(3, 2), "Cell not committed early")
	movement.advance(Movement.STEP_SECONDS / 2)
	check(movement.foot_position() == Vector2(48, 47), "Midstep stays pixel aligned")
	movement.locked = true
	movement.advance(100)
	check(movement.moving and movement.cell == Vector2i(2, 2), "Lock freezes pending movement")
	movement.locked = false
	movement.advance(100)
	check(movement.cell == Vector2i(3, 2) and not movement.moving, "Long frame commits exactly one cell")
	movement.place(Vector2i(4, 2))
	check(not movement.try_step(Vector2i.RIGHT, can_enter) and movement.facing == Vector2i.RIGHT, "Blocked step still faces obstacle")
	check(Bindings.direction(Vector2(0.1, 0.1)) == Vector2i.ZERO, "Stick deadzone")
	check(Bindings.direction(Vector2(0.9, 0.5)) == Vector2i.RIGHT, "Dominant stick axis")
	movement.free()

func action(world: Node, name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	world._unhandled_input(event)

func walk(world: Node, goal: Vector2i) -> void:
	var path := path_to(world.current_map, world.movement.cell, goal)
	check(not path.is_empty() or world.movement.cell == goal, "Integration route exists to %s" % goal)
	for cell: Vector2i in path:
		var direction: Vector2i = cell - world.movement.cell
		var name: String = {Vector2i.UP: "walk_up", Vector2i.DOWN: "walk_down", Vector2i.LEFT: "walk_left", Vector2i.RIGHT: "walk_right"}[direction]
		Input.action_press(name)
		world._physics_process(0.0)
		check(world.movement.moving, "Input begins expected step")
		Input.action_release(name)
		world._physics_process(Movement.STEP_SECONDS)
		check(world.movement.cell == cell, "Input arrives at expected cell")

func test_scene() -> void:
	var world := Scene.instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	await process_frame
	check(world.current_map.id == "town", "Starts in town")
	var event_count := InputMap.action_get_events("walk_right").size()
	Bindings.install()
	check(InputMap.action_get_events("walk_right").size() == event_count, "Bindings install once across scene loads")
	check(world.current_map.interaction_at(Vector2i(6, 10)).get("id", "") == "town_door", "Both visible door cells are interactive")
	check(world.movement.try_step(Vector2i.RIGHT, world.current_map.can_enter), "Start midstep guard check")
	world.movement.advance(0.08)
	check(not world.interact() and not world.begin_travel("forest", Vector2i(2, 14)), "Midstep cannot open dialogue or start travel")
	world._physics_process(0.08)
	walk(world, Vector2i(13, 12))
	world.movement.facing = Vector2i.UP
	action(world, "interact")
	check(world.mode == world.Mode.DIALOGUE and world.dialogue.active, "Facing NPC opens dialogue")
	var before: Vector2i = world.movement.cell
	Input.action_press("walk_right")
	world._physics_process(1.0)
	check(world.movement.cell == before and not world.movement.moving, "Held movement is locked during dialogue")
	check(not world.movement.try_step(Vector2i.RIGHT, world.current_map.can_enter), "Direct movement is also locked")
	check(not world.begin_travel("forest", Vector2i(2, 14)), "Cannot travel during dialogue")
	action(world, "interact")
	check(world.dialogue.index == 1, "Dialogue advances one page")
	action(world, "interact")
	world._physics_process(0.0)
	check(world.mode == world.Mode.EXPLORE and not world.movement.moving, "Held key cannot move on dialogue close")
	Input.action_release("walk_right")
	world._physics_process(0.0)
	check(not world.require_neutral, "Releasing direction rearms movement")
	action(world, "interact")
	action(world, "close_dialogue")
	check(not world.dialogue.active and not world.movement.locked, "Cancel closes and unlocks")
	world._physics_process(0.0)
	walk(world, Vector2i(23, 11))
	world.movement.facing = Vector2i.UP
	action(world, "interact")
	check(world.dialogue.speaker == "FERNGLASS WOOD", "Sign interaction")
	action(world, "close_dialogue")
	world._physics_process(0.0)
	for loop in range(3):
		walk(world, Vector2i(31, 12))
		check(world.mode == world.Mode.TRANSITION and world.movement.locked, "Portal locks input")
		world.end_dialogue()
		check(world.mode == world.Mode.TRANSITION and world.movement.locked, "Stale dialogue close cannot unlock travel")
		check(not world.begin_travel("town", Vector2i(10, 12)), "No duplicate transition")
		world._physics_process(0.28)
		check(world.current_map.id == "forest" and world.movement.cell == Vector2i(2, 14), "Forest arrival is correct")
		world._physics_process(0.0)
		if loop == 0:
			walk(world, Vector2i(12, 14))
			world.movement.facing = Vector2i.UP
			action(world, "interact")
			check(world.dialogue.speaker == "IVO / BRIDGE WARDEN", "Second NPC talks")
			action(world, "close_dialogue")
			world._physics_process(0.0)
			walk(world, Vector2i(24, 6))
			walk(world, Vector2i(27, 22))
			world.movement.facing = Vector2i.UP
			action(world, "interact")
			check(world.dialogue.speaker == "MOSSY DOOR", "Old waystation is reachable and readable")
			action(world, "close_dialogue")
			world._physics_process(0.0)
		walk(world, Vector2i(0, 14))
		world._physics_process(0.28)
		check(world.current_map.id == "town" and world.movement.cell == Vector2i(29, 12), "Town return is correct")
		world._physics_process(0.0)
		check(world.npc_actors.size() == 1, "Travel does not duplicate NPCs")
	check(not world.begin_travel("missing", Vector2i.ZERO), "Missing map rejected without state change")
	check(world.mode == world.Mode.EXPLORE and world.current_map.id == "town", "Invalid travel leaves current map intact")
	var closed: Map = world.current_map.duplicate(true)
	closed.id = "closed"
	closed.blocked_cells.clear()
	for y in range(closed.size.y):
		for x in range(closed.size.x):
			closed.blocked_cells.append(Vector2i(x, y))
	world.maps.closed = closed
	check(not world.begin_travel("closed", Vector2i(2, 2)), "Map with no safe spawn is rejected")
	world.maps.erase("closed")
	check(world.begin_travel("forest", Vector2i(21, 12)), "Invalid water spawn can recover")
	world._physics_process(0.28)
	check(world.current_map.can_enter(world.movement.cell) and world.current_map.portal_at(world.movement.cell).is_empty(), "Recovered spawn is walkable and not an exit")
	world._physics_process(0.0)
	await test_input_events(world)
	await test_gamepad_travel(world)
	world.queue_free()
	await process_frame

func test_input_events(world: Node) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(Bindings.held_direction() == Vector2i.RIGHT, "Keyboard event reaches movement action")
	key.pressed = false
	Input.parse_input_event(key)
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_DPAD_LEFT
	button.pressed = true
	Input.parse_input_event(button)
	await process_frame
	check(Bindings.held_direction() == Vector2i.LEFT, "Virtual gamepad D-pad reaches movement action")
	button.pressed = false
	Input.parse_input_event(button)
	var axis := InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0.9
	Input.parse_input_event(axis)
	await process_frame
	check(Bindings.held_direction() == Vector2i.RIGHT, "Virtual gamepad stick reaches movement action")
	axis.axis_value = 0.4
	Input.parse_input_event(axis)
	await process_frame
	check(Bindings.held_direction() == Vector2i.RIGHT, "Stick responds just above one 35-percent deadzone")
	axis.axis_value = 0.1
	Input.parse_input_event(axis)
	await process_frame
	check(Bindings.held_direction() == Vector2i.ZERO, "Virtual stick respects deadzone")
	axis.axis_value = 0.0
	Input.parse_input_event(axis)
	world._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(Bindings.held_direction() == Vector2i.ZERO and world.require_neutral, "Focus loss clears movement input")
	world.camera.force_update_scroll()
	var center: Vector2 = world.camera.get_screen_center_position()
	check(center.x >= 160 and center.x <= world.current_map.size.x * 16 - 160 and center.y >= 90 and center.y <= world.current_map.size.y * 16 - 90, "Camera remains within map limits")

func pad(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func walk_pad(world: Node, goal: Vector2i) -> void:
	world._physics_process(0.0)
	var path := path_to(world.current_map, world.movement.cell, goal)
	check(not path.is_empty() or world.movement.cell == goal, "Gamepad route exists")
	for cell: Vector2i in path:
		var direction: Vector2i = cell - world.movement.cell
		var button: JoyButton = {Vector2i.UP: JOY_BUTTON_DPAD_UP, Vector2i.DOWN: JOY_BUTTON_DPAD_DOWN, Vector2i.LEFT: JOY_BUTTON_DPAD_LEFT, Vector2i.RIGHT: JOY_BUTTON_DPAD_RIGHT}[direction]
		await pad(button, true)
		world._physics_process(0.0)
		check(world.movement.moving, "Virtual gamepad starts grid step")
		await pad(button, false)
		world._physics_process(Movement.STEP_SECONDS)
		check(world.movement.cell == cell, "Virtual gamepad completes grid step")

func test_gamepad_travel(world: Node) -> void:
	await walk_pad(world, Vector2i(12, 14))
	await pad(JOY_BUTTON_DPAD_UP, true)
	world._physics_process(0.0)
	await pad(JOY_BUTTON_DPAD_UP, false)
	await pad(JOY_BUTTON_A, true)
	check(world.dialogue.active and world.dialogue.speaker == "IVO / BRIDGE WARDEN", "Virtual gamepad A opens NPC dialogue through the viewport")
	await pad(JOY_BUTTON_A, false)
	await pad(JOY_BUTTON_B, true)
	check(not world.dialogue.active, "Virtual gamepad B closes dialogue through the viewport")
	await pad(JOY_BUTTON_B, false)
	await walk_pad(world, Vector2i(0, 14))
	world._physics_process(0.28)
	check(world.current_map.id == "town", "Virtual gamepad traverses forest exit")
	await walk_pad(world, Vector2i(31, 12))
	world._physics_process(0.28)
	check(world.current_map.id == "forest", "Virtual gamepad traverses town exit")
	world._physics_process(0.0)
	world.camera.force_update_scroll()
	check(is_equal_approx(world.camera.get_screen_center_position().x, 160.0), "Camera clamps at the forest west edge")