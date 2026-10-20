extends Node
const Model = preload("res://scripts/progression/expedition_service.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")
const Codec = preload("res://scripts/progression/save_codec.gd")
const Saves = preload("res://scripts/save/save_service.gd")
const Session = preload("res://scripts/progression/expedition_session.gd")
const World = preload("res://scenes/world/exploration.tscn")
const Battle = preload("res://scenes/battle/battle.tscn")
const Menu = preload("res://scripts/progression/expedition_menu.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
var audio: Node
var data: Dictionary = Model.fresh()
var saves := Saves.new()
var world: Node2D
var battle: Node
var field_menu: Node2D
var session: RefCounted
var awaiting_continue: bool = false
var save_blocked: bool = false
var last_error: String = ""

func _ready() -> void:
	audio = preload("res://scripts/progression/audio_director.gd").new()
	add_child(audio)
	saves.codec = Codec
	world = World.instantiate()
	world.environment_polish = true
	add_child(world)
	world.maps.town = Routes.hub()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/m5/manifest.json"))
	for id: String in manifest.regions:
		var spec: Dictionary = manifest.regions[id].duplicate(true)
		spec.texture_path = "res://assets/generated/m5/" + spec.asset + ".png"
		world.regions[id] = spec
	var extra: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/m6/manifest.json"))
	for id: String in extra.regions:
		var spec: Dictionary = extra.regions[id].duplicate(true)
		spec.texture_path = "res://assets/generated/m6/" + spec.asset + ".png"
		world.regions[id] = spec
	world.completed_step.connect(_world_step)
	world.action_requested.connect(_world_action)
	world.hud.show_menu_hint = true
	var loaded := saves.load_game(world.maps)
	if not loaded.has("error"):
		data = loaded.data
		awaiting_continue = not data.run.is_empty()
		if loaded.has("recovered"): last_error = "RECOVERED " + loaded.recovered.to_upper()
		if loaded.get("migrated", false): last_error = "RESEARCH BACKFILLED. ACTIVE RUN PRESERVED."
		if loaded.get("legacy", false): last_error = "LEGACY COLLECTION READY TO MIGRATE."
	elif loaded.error != "NO SAVE FOUND.":
		last_error = loaded.error
		save_blocked = true
	mount_hub()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("field_menu", false) and field_menu == null and battle == null:
		if open_menu(): get_viewport().set_input_as_handled()

func lock_world() -> void:
	world.mode = world.Mode.MENU
	world.movement.locked = true
	world.set_physics_process(false)
	world.set_process_unhandled_input(false)

func unlock_world() -> void:
	world.mode = world.Mode.EXPLORE
	world.movement.locked = false
	world.require_neutral = true
	world.set_physics_process(true)
	world.set_process_unhandled_input(true)

func dispose_menu() -> void:
	if field_menu == null: return
	field_menu.visible = false
	field_menu.set_process_input(false)
	field_menu.get_parent().queue_free()
	field_menu = null

func show_menu(screen: String) -> void:
	dispose_menu()
	lock_world()
	var layer := CanvasLayer.new()
	layer.layer = 3
	layer.name = "ExpeditionJournal"
	add_child(layer)
	field_menu = Menu.new()
	field_menu.app = self
	field_menu.screen = screen
	field_menu.message = "" if last_error == "CHECKPOINT SAVED." else last_error
	layer.add_child(field_menu)

func open_menu() -> bool:
	if battle != null or field_menu != null or world.mode != world.Mode.EXPLORE or world.movement.moving: return false
	show_menu("hub" if data.run.is_empty() or awaiting_continue else "camp" if data.run.phase == "camp" else "field")
	return true

func close_menu() -> void:
	if field_menu == null: return
	dispose_menu()
	unlock_world()

func position(candidate: Dictionary) -> void:
	if not candidate.run.is_empty() and not awaiting_continue and world.current_map.id == "expedition":
		candidate.run.cell = [world.movement.cell.x, world.movement.cell.y]
		candidate.run.facing = [world.movement.facing.x, world.movement.facing.y]

func commit(candidate: Dictionary) -> bool:
	if save_blocked:
		last_error = "EXISTING SAVE NEEDS RECOVERY."
		return false
	var result := saves.save_game(candidate, world.maps)
	if result != "SAVED.":
		last_error = result
		return false
	data = candidate
	audio.apply(data.profile.settings)
	last_error = "CHECKPOINT SAVED."
	update_hud()
	return true

func perform(action: String, args: Dictionary = {}) -> bool:
	if battle != null: last_error = "FINISH THE BATTLE FIRST."; return false
	if world.movement.moving or world.mode != world.Mode.MENU: last_error = "OPEN THE JOURNAL AT AN IDLE CELL."; return false
	var candidate := data.duplicate(true)
	position(candidate)
	var error := ""
	match action:
		"depart": error = Model.depart(candidate, int(args.get("index", -1)))
		"route": error = Model.choose_route(candidate, int(args.get("index", -1)))
		"relic": error = Model.relic(candidate, args.get("id", ""))
		"camp": error = Model.camp(candidate, args.get("action", ""))
		"end": error = Model.request_end(candidate, args.get("outcome", ""))
		"settle": error = Model.settle(candidate, args.get("id", ""))
		"balm", "deposit", "withdraw", "lead", "release_party", "release_reserve": error = Model.field_action(candidate, action, int(args.get("index", -1)), int(args.get("target", 0)))
		"settings":
			var key: String = args.get("key", "text_speed")
			if not key in ["text_speed", "music", "sfx"]: return false
			candidate.profile.settings[key] = (int(candidate.profile.settings[key]) + 1) % (2 if key == "text_speed" else 4)
		"buy": error = Meta.buy(candidate, args.get("id", ""))
		"prepare":
			if not candidate.run.is_empty(): error = "PREPARATION IS HUB ONLY."
			else: error = Meta.prepare(candidate.profile, args.get("key", ""), args.get("value", ""))
		"pin":
			if not args.get("id", "") in Meta.PROJECTS: error = "UNKNOWN PROJECT."
			else: candidate.profile.meta.pin = args.id
		"event": error = Model.trail_event(candidate, args.get("choice", ""))
		"checkpoint": pass
		_: error = "UNKNOWN ACTION."
	if not error.is_empty(): last_error = error; return false
	return commit(candidate)

func mount_hub() -> void:
	world.visible = true
	world.get_node("HUD").visible = true
	world.maps.town = Routes.hub()
	world.maps.town.npcs[0].pages = ["RESEARCH AND STAGE MARKS STAY AFTER EVERY RUN. VISIT PROJECTS IN YOUR JOURNAL.", "SHELTER A SPECIES AND WIN THREE FIELD STUDIES TO UNLOCK ITS LEVEL SEVEN GROWTH."]
	world.maps.town.npcs[1].pages = ["THE TRAIL DESK SURVEYS STAGE TWO. PREPARE SUPPLIES AND RELIC POOLS BEFORE DEPARTURE.", "CHALLENGES ARE OPTIONAL. NORMAL RUNS ALWAYS STAY FREE. PIN A PROJECT FOR YOUR NEXT GOAL."]
	world.maps.town.props = world.maps.town.props.filter(func(p: Dictionary) -> bool: return not (p.region == "tree" and p.origin in [Vector2i(3, 20), Vector2i(15, 19)]))
	for index in range(3):
		var id: String = Meta.PROJECTS.keys()[index]
		var state: int = 2 if id in data.profile.meta.projects else 1 if data.profile.meta.marks >= Meta.PROJECTS[id].cost else 0
		world.maps.town.props.append({"region": "m6_" + id + "_%s" % state, "origin": Vector2i([3, 11, 17][index], 18)})
	for index in range(3):
		var x: int = [3, 11, 17][index]
		for dx in range(3): world.maps.town.blocked_cells.append(Vector2i(x + dx, 20))
		world.maps.town.interactions.append({"id": "project_%s" % index, "cell": Vector2i(x + 1, 20), "action": "project_%s" % index})
	for index in range(3):
		if Meta.sheltered(data.profile, Meta.BASES[index]): world.maps.town.props.append({"region": "shelter_" + Meta.BASES[index], "origin": Vector2(12.0 + index * 1.25, 16.5)})
	for index in range(data.profile.meta.medals.size()):
		world.maps.town.props.append({"region": "medal_%s" % index, "origin": Vector2i(22 + index * 2, 14)})
	if not data.profile.meta.tiers.is_empty(): world.maps.town.props.append({"region": "tier_%s" % int(data.profile.meta.tiers.max()), "origin": Vector2i(28, 14)})
	world._mount_map("town", world.maps.town.start)
	audio.apply(data.profile.settings)
	audio.play_theme("hub")
	unlock_world()
	update_hud()

func render_state() -> void:
	dispose_menu()
	awaiting_continue = false
	audio.play_theme("forest")
	world.visible = true
	world.get_node("HUD").visible = true
	if data.run.is_empty(): mount_hub(); return
	var r: Dictionary = data.run
	if r.choices.size() > int(r.stage):
		world.maps.expedition = Model.map_for(r)
		world._mount_map("expedition", Vector2i(int(r.cell[0]), int(r.cell[1])))
		world.movement.facing = Vector2i(int(r.facing[0]), int(r.facing[1]))
		world._sync_visuals()
	update_hud()
	match r.phase:
		"route": show_menu("route")
		"reward": show_menu("reward")
		"camp": show_menu("camp")
		"settle": show_menu("settle")
		"field":
			unlock_world()
			if not r.pending.is_empty(): spawn_battle()

func continue_run() -> bool:
	if battle != null or not awaiting_continue: return false
	var loaded := saves.load_game(world.maps)
	if loaded.has("error"): last_error = loaded.error; return false
	data = loaded.data
	render_state()
	return true

func update_hud() -> void:
	if world == null: return
	if data.run.is_empty() or awaiting_continue:
		world.hud.health_text = ""
		world.hud.status_relics = []
		world.hud.status_text = "MARKS %s  CLEARS %s  TAB JOURNAL" % [data.profile.meta.marks, data.profile.completed]
	else:
		var r: Dictionary = data.run
		var hp := 0
		var maximum := 0
		for m: Dictionary in r.party:
			hp += int(m.hp)
			var individual := Model.monster(m)
			maximum += individual.max_hp(Model.Catalog.new().species[m.species])
		world.hud.health_text = "TEAM %s/%s HP  RESERVE %s/4" % [hp, maximum, r.reserve.size()]
		world.hud.status_relics = r.relics.duplicate()
		world.hud.status_text = "STAGE %s/3  LIGHTS %s/2  CHARMS %s  BALMS %s" % [int(r.stage) + 1, r.cleared.size(), r.inventory.charm, r.inventory.balm]
	world.hud.queue_redraw()

func _world_step(_map_id: String, cell: Vector2i) -> void:
	if data.run.is_empty() or awaiting_continue or data.run.phase != "field" or battle != null: return
	for slot in range(2):
		if cell == world.current_map.landmarks["encounter_%s" % slot] and not slot in data.run.cleared:
			encounter(slot)
			return

func _world_action(action: String) -> void:
	if battle != null or field_menu != null: return
	if action.begins_with("project_") and data.run.is_empty():
		show_menu("project")
		field_menu.project_index = action.trim_prefix("project_").to_int()
		return
	if action == "departure": open_menu(); return
	if action == "trail_event" and not data.run.is_empty(): show_menu("event"); return
	if data.run.is_empty() or awaiting_continue: return
	if action.begins_with("encounter_"):
		encounter(action.trim_prefix("encounter_").to_int())
	elif action == "stage_exit":
		if data.run.phase == "camp": show_menu("camp"); return
		var candidate := data.duplicate(true)
		position(candidate)
		var error := Model.exit_stage(candidate)
		if not error.is_empty(): last_error = error; show_menu("field"); return
		if commit(candidate): render_state()
		else: show_menu("field")

func encounter(slot: int) -> bool:
	if data.run.is_empty() or battle != null or world.movement.moving: return false
	var candidate := data.duplicate(true)
	position(candidate)
	var error := Model.prepare(candidate, slot)
	if not error.is_empty(): last_error = error; return false
	if not commit(candidate): show_menu("field"); return false
	spawn_battle()
	return true

func spawn_battle() -> void:
	if battle != null or data.run.is_empty() or data.run.pending.is_empty(): return
	dispose_menu()
	session = Session.new()
	session.configure(data)
	var e: Dictionary = data.run.pending
	var state: RefCounted = session.begin(e.species, int(e.level))
	if state == null: last_error = "NO HEALTHY PARTY MEMBER."; return
	lock_world()
	world.mode = world.Mode.BATTLE
	world.visible = false
	world.get_node("HUD").visible = false
	battle = Battle.instantiate()
	battle.configure(state, session)
	audio.play_theme("battle")
	battle.closed.connect(_battle_closed)
	add_child(battle)

func _battle_closed(state: RefCounted) -> void:
	if battle == null or state.id != battle.state.id or state.outcome.is_empty() or not session.claimed.has(state.id) or data.run.is_empty() or data.run.pending.get("id", -1) != state.id: return
	var candidate := data.duplicate(true)
	if not session.apply_to(candidate, state): return
	if not commit(candidate):
		battle.phase = battle.Phase.RESULT
		battle.message = last_error + " E: RETRY CHECKPOINT."
		return
	audio.cue("victory" if state.guardian and state.outcome == "victory" else "defeat" if state.outcome == "defeat" else "growth" if session.grew else "capture" if state.outcome == "capture" else "confirm")
	remove_child(battle)
	battle.queue_free()
	battle = null
	render_state()
func _process(_delta: float) -> void:
	if battle == null: return
	var id: String = "%s/%s/%s" % [battle.state.id, battle.state.turn, battle.event.get("kind", "")]
	if id != audio.last_event and battle.event.get("kind", "") == "hit": audio.cue("hit")
	audio.last_event = id