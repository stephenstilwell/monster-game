extends Node
const Session = preload("res://scripts/core/run_session.gd")
const Encounters = preload("res://scripts/world/encounter_controller.gd")
const WorldScene = preload("res://scenes/world/exploration.tscn")
const BattleScene = preload("res://scenes/battle/battle.tscn")
const SaveService = preload("res://scripts/save/save_service.gd")
const SaveCodec = preload("res://scripts/save/save_codec.gd")
const Menu = preload("res://scripts/ui/field_menu.gd")
var saves := SaveService.new()
var field_menu: Node2D
var session: RefCounted
var encounters := Encounters.new()
var world: Node2D
var battle: Node
func _ready() -> void:
	session = Session.new()
	world = WorldScene.instantiate()
	add_child(world)
	world.completed_step.connect(_world_step)
	world.hud.show_menu_hint = true

func _world_step(_map_id: String, cell: Vector2i) -> void:
	var encounter := encounters.step(world.current_map, cell)
	if not encounter.is_empty(): start_battle(encounter.species, encounter.level)

func start_battle(species: String, level: int) -> bool:
	if battle != null or world.mode != world.Mode.EXPLORE or world.movement.moving: return false
	var state: RefCounted = session.begin(species, level)
	if state == null: return false
	world.mode = world.Mode.BATTLE
	world.movement.locked = true
	world.set_physics_process(false)
	world.set_process_unhandled_input(false)
	world.visible = false
	world.get_node("HUD").visible = false
	battle = BattleScene.instantiate()
	battle.configure(state, session)
	battle.closed.connect(_battle_closed)
	add_child(battle)
	return true

func _battle_closed(state: RefCounted) -> void:
	if battle == null or state.id != battle.state.id or state.outcome.is_empty() or not session.claimed.has(state.id): return
	remove_child(battle)
	battle.queue_free()
	battle = null
	if state.outcome == "defeat": world._mount_map("town", world.maps.town.start)
	world.mode = world.Mode.EXPLORE
	world.movement.locked = false
	world.require_neutral = true
	world.visible = true
	world.get_node("HUD").visible = true
	world.set_physics_process(true)
	world.set_process_unhandled_input(true)
	world.camera.force_update_scroll()
	encounters.returned()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("field_menu", false) and field_menu == null:
		if open_menu(): get_viewport().set_input_as_handled()

func open_menu() -> bool:
	if battle != null or field_menu != null or world.mode != world.Mode.EXPLORE or world.movement.moving: return false
	world.mode = world.Mode.MENU
	world.movement.locked = true
	world.set_physics_process(false)
	world.set_process_unhandled_input(false)
	field_menu = Menu.new()
	field_menu.app = self
	var layer := CanvasLayer.new()
	layer.name = "FieldMenu"
	layer.layer = 3
	add_child(layer)
	layer.add_child(field_menu)
	field_menu.closed.connect(close_menu)
	return true

func close_menu() -> void:
	if field_menu == null: return
	field_menu.visible = false
	field_menu.set_process_input(false)
	field_menu.get_parent().queue_free()
	field_menu = null
	world.mode = world.Mode.EXPLORE
	world.movement.locked = false
	world.require_neutral = true
	world.set_physics_process(true)
	world.set_process_unhandled_input(true)

func save_run() -> String:
	if field_menu == null or battle != null or world.mode != world.Mode.MENU: return "SAVE FROM THE FIELD MENU."
	return saves.save_game(SaveCodec.snapshot(self), world.maps)

func load_run() -> String:
	if field_menu == null or battle != null or world.mode != world.Mode.MENU: return "LOAD FROM THE FIELD MENU."
	var result := saves.load_game(world.maps)
	if result.has("error"): return result.error
	session = result.session
	world._mount_map(result.map, result.cell)
	world.movement.facing = result.facing
	world._sync_visuals()
	encounters.rng.state = result.encounters.state.to_int()
	encounters.cooldown = int(result.encounters.cooldown)
	encounters.grass_steps = int(result.encounters.grass)
	world.movement.locked = true
	world.require_neutral = true
	field_menu.party_slot = 0
	return "RECOVERED FROM " + result.recovered.to_upper() if result.has("recovered") else "LOADED."
