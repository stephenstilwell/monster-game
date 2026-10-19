extends Node
const Session = preload("res://scripts/core/run_session.gd")
const Encounters = preload("res://scripts/world/encounter_controller.gd")
const WorldScene = preload("res://scenes/world/exploration.tscn")
const BattleScene = preload("res://scenes/battle/battle.tscn")
var session: RefCounted
var encounters := Encounters.new()
var world: Node2D
var battle: Node
func _ready() -> void:
	session = Session.new()
	world = WorldScene.instantiate()
	add_child(world)
	world.completed_step.connect(_world_step)

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
