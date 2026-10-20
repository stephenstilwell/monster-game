extends Node2D
signal completed_step(map_id: String, cell: Vector2i)
signal action_requested(action: String)
const Map = preload("res://scripts/world/map_definition.gd")
const Movement = preload("res://scripts/world/grid_movement.gd")
const Dialogue = preload("res://scripts/world/dialogue_state.gd")
const Bindings = preload("res://scripts/world/exploration_input.gd")
const ActorScene = preload("res://scenes/actors/field_actor.tscn")
enum Mode { EXPLORE, DIALOGUE, TRANSITION, BATTLE, MENU }
var mode: Mode = Mode.EXPLORE
var maps: Dictionary = {}
var current_map: Map
var movement: Movement
var dialogue := Dialogue.new()
var player: Node2D
var npc_actors: Dictionary = {}
var regions: Dictionary = {}
var environment_polish: bool = false
var environment_style: RefCounted
var textures: Dictionary = {}
var require_neutral: bool = false
var transition_elapsed: float = 0.0
var pending_map: String = ""
var pending_spawn := Vector2i.ZERO
var transition_swapped: bool = false
@onready var terrain: TileMapLayer = $Terrain
@onready var objects: Node2D = $Objects
@onready var camera: Camera2D = $Camera
@onready var hud: Node2D = $HUD/Overlay

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if environment_polish: environment_style = preload("res://scripts/world/environment_style.gd").new()
	Bindings.install()
	for id in ["town", "forest"]:
		maps[id] = load("res://data/maps/" + id + ".tres")
	for folder in ["res://assets/generated", "res://assets/generated/m2"]:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "/manifest.json"))
		for id: String in manifest.regions:
			var spec: Dictionary = manifest.regions[id].duplicate()
			spec.texture_path = folder + "/" + spec.asset + ".png"
			regions[id] = spec
	movement = Movement.new()
	movement.name = "GridMovement"
	add_child(movement)
	movement.step_completed.connect(_step_completed)
	terrain.tile_set = load("res://assets/generated/m2/exploration_tileset.tres")
	terrain.collision_enabled = false # Grid rules own movement; no competing physics solver.
	hud.world = self
	_mount_map("town", maps.town.start)

func _mount_map(id: String, at: Vector2i) -> void:
	current_map = maps[id]
	terrain.clear()
	for child in objects.get_children():
		objects.remove_child(child)
		child.queue_free()
	npc_actors.clear()
	for y in range(current_map.size.y):
		for x in range(current_map.size.x):
			var tile: int = current_map.tile_at(Vector2i(x, y))
			terrain.set_cell(Vector2i(x, y), 0 if tile < 32 else 1, Vector2i(tile % 8, tile / 8) if tile < 32 else Vector2i(tile - 32, 0))
	var scenery_seed: int = environment_style.map_seed(current_map) if environment_style != null else 0
	var house_index := 0
	for prop: Dictionary in current_map.props:
		if environment_style != null:
			var id_override: String = environment_style.variant(prop, current_map, house_index, scenery_seed)
			if prop.region == "waystation": house_index += 1
			if not id_override.is_empty():
				objects.add_child(environment_style.sprite(id_override, Vector2(prop.origin), environment_style.stable(str(prop.origin))))
				continue
		var spec: Dictionary = regions[prop.region]
		var rect: Array = spec.rect
		var anchor := Vector2(spec.anchor[0], spec.anchor[1])
		var sprite := Sprite2D.new()
		if not textures.has(spec.texture_path):
			textures[spec.texture_path] = load(spec.texture_path)
		sprite.texture = textures[spec.texture_path]
		sprite.region_enabled = true
		sprite.region_rect = Rect2(rect[0], rect[1], rect[2], rect[3])
		sprite.centered = false
		sprite.offset = -anchor
		sprite.position = Vector2(prop.origin) * 16 + anchor
		objects.add_child(sprite)
	if environment_style != null:
		for prop: Dictionary in environment_style.scatter(current_map, regions, scenery_seed):
			objects.add_child(environment_style.sprite(prop.region, Vector2(prop.origin), int(prop.seed)))
	for npc: Dictionary in current_map.npcs:
		var actor := ActorScene.instantiate()
		objects.add_child(actor)
		actor.configure(load("res://assets/generated/m2/" + npc.id + "_frames.tres"), npc.id)
		actor.position = Vector2(npc.cell) * 16 + Vector2(8, 15)
		npc_actors[npc.id] = actor
	player = ActorScene.instantiate()
	objects.add_child(player)
	player.configure(load("res://assets/generated/player_frames.tres"), "player")
	movement.place(at)
	player.position = movement.foot_position()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = current_map.size.x * 16
	camera.limit_bottom = current_map.size.y * 16
	_sync_visuals()
	camera.reset_smoothing()
	camera.force_update_scroll()

func _physics_process(delta: float) -> void:
	if mode == Mode.TRANSITION:
		transition_elapsed += delta
		if transition_elapsed >= 0.14 and not transition_swapped:
			transition_swapped = true
			_mount_map(pending_map, pending_spawn)
		if transition_elapsed >= 0.28:
			mode = Mode.EXPLORE
			movement.locked = false
			pending_map = ""
			require_neutral = true
	else:
		movement.advance(delta)
		if mode == Mode.EXPLORE and not movement.moving:
			var direction := Bindings.held_direction()
			if direction == Vector2i.ZERO:
				require_neutral = false
			elif not require_neutral:
				movement.try_step(direction, current_map.can_enter)
	_sync_visuals()

func _sync_visuals() -> void:
	if player == null:
		return
	player.position = movement.foot_position()
	player.show_state(movement.facing, movement.moving)
	camera.position = (player.position + Vector2(0, -24)).round()
	hud.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact", false):
		if mode == Mode.DIALOGUE:
			dialogue.advance()
			if not dialogue.active:
				end_dialogue()
		elif mode == Mode.EXPLORE and not movement.moving:
			interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("close_dialogue", false) and mode == Mode.DIALOGUE:
		end_dialogue()
		get_viewport().set_input_as_handled()

func interact() -> bool:
	if mode != Mode.EXPLORE or movement.moving:
		return false
	var entry := current_map.interaction_at(movement.cell + movement.facing)
	if entry.is_empty():
		return false
	if entry.has("action"):
		action_requested.emit(entry.action)
		return true
	dialogue.open(entry)
	if not dialogue.active:
		return false
	mode = Mode.DIALOGUE
	movement.locked = true
	if npc_actors.has(entry.id):
		npc_actors[entry.id].show_state(-movement.facing, false)
	hud.queue_redraw()
	return true

func end_dialogue() -> void:
	if mode != Mode.DIALOGUE:
		return
	dialogue.close()
	mode = Mode.EXPLORE
	movement.locked = false
	require_neutral = true
	hud.queue_redraw()

func begin_travel(id: String, requested: Vector2i) -> bool:
	if mode != Mode.EXPLORE or movement.moving or not maps.has(id):
		return false
	var target: Map = maps[id]
	var spawn := target.safe_spawn(requested)
	if spawn == Vector2i(-1, -1):
		return false
	pending_map = id
	pending_spawn = spawn
	transition_elapsed = 0.0
	transition_swapped = false
	mode = Mode.TRANSITION
	movement.locked = true
	return true

func _step_completed(cell: Vector2i) -> void:
	var portal := current_map.portal_at(cell)
	if not portal.is_empty():
		if portal.has("action"): action_requested.emit(portal.action)
		else: begin_travel(portal.map, portal.spawn)
	else:
		completed_step.emit(current_map.id, cell)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action in ["walk_up", "walk_down", "walk_left", "walk_right", "interact", "close_dialogue", "field_menu"]:
			Input.action_release(action)
		require_neutral = true
