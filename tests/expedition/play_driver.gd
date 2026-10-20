extends RefCounted
const Resolver = preload("res://scripts/battle/battle_resolver.gd")
var steps: int = 0
var turns: int = 0
var battles: int = 0
var captures: int = 0

func path(map: Resource, start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var parents := {start: start}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty() and not parents.has(target):
		var cell: Vector2i = pending.pop_front()
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]:
			var next := cell + direction
			if map.can_enter(next) and not parents.has(next): parents[next] = cell; pending.append(next)
	var result: Array[Vector2i] = []
	if not parents.has(target): return result
	var current := target
	while current != start: result.push_front(current); current = parents[current]
	return result

func walk(app: Node, target: Vector2i) -> bool:
	var cells := path(app.world.current_map, app.world.movement.cell, target)
	if cells.is_empty() and app.world.movement.cell != target: return false
	app.world.set_physics_process(false)
	for cell: Vector2i in cells:
		if app.battle != null or app.field_menu != null: return false
		if not app.world.movement.try_step(cell - app.world.movement.cell, app.world.current_map.can_enter): return false
		app.world.movement.advance(0.16)
		app.world._sync_visuals()
		steps += 1
	return app.world.movement.cell == target

func command(session: RefCounted, state: RefCounted, catch_new: bool = true) -> Dictionary:
	var active: RefCounted = state.party[state.active]
	if active.hp <= 0: return {"kind": "switch", "index": state.first_healthy()}
	var species: Resource = session.catalog.species[active.species_id]
	var enemy_affinity: String = session.catalog.species[state.enemy.species_id].affinity
	var current_match: float = Resolver.affinity_multiplier(species.affinity, enemy_affinity)
	for i in range(state.party.size()):
		var alternative: RefCounted = state.party[i]
		if i != state.active and alternative.hp >= 20:
			var affinity: String = session.catalog.species[alternative.species_id].affinity
			if Resolver.affinity_multiplier(affinity, enemy_affinity) > current_match + 0.4: return {"kind": "switch", "index": i}
	if state.inventory.balm > 0 and active.hp < 20 and active.max_hp(species) - active.hp >= 18: return {"kind": "item", "item": "balm"}
	var duplicate := false
	for m: RefCounted in state.party: duplicate = duplicate or m.species_id == state.enemy.species_id
	var capture: bool = catch_new and not duplicate and not state.guardian and state.capture_allowed and state.inventory.charm > 0 and state.party.size() < 2
	if capture and state.enemy.hp <= state.enemy.max_hp(session.catalog.species[state.enemy.species_id]) * 0.6: return {"kind": "item", "item": "charm"}
	if capture: return {"kind": "move", "move": "nudge"}
	var best: String = active.moves[0]
	var score: float = -1.0
	for id: String in active.moves:
		var move: Resource = session.catalog.moves[id]
		var value: float = (move.power + active.attack(species) * 0.7 - state.enemy.defense(session.catalog.species[state.enemy.species_id]) * 0.45) * Resolver.affinity_multiplier(move.affinity, session.catalog.species[state.enemy.species_id].affinity) * (1.15 if move.affinity == species.affinity else 1.0)
		if value > score: score = value; best = id
	return {"kind": "move", "move": best}

func fight(app: Node, catch_new: bool = true) -> String:
	if app.battle == null: return "missing"
	var battle: Node = app.battle
	battle.set_process(false)
	if battle.phase == battle.Phase.ENTRY: battle.confirm()
	for iteration in range(100):
		if battle.phase == battle.Phase.RESULT:
			var result: String = battle.state.outcome
			battles += 1
			if result == "capture": captures += 1
			battle.confirm()
			app.world.set_physics_process(false)
			return result
		if battle.phase == battle.Phase.COMMAND:
			if not battle.submit(command(battle.session, battle.state, catch_new)): return "invalid"
			turns += 1
		else: battle.advance(0.6)
	return "timeout"

func route_index(app: Node) -> int:
	var r: Dictionary = app.data.run
	var species: String = r.party[0].species
	# Prefer a favorable affinity for the opening light.
	var preferred: int = {"brindlewick": 2, "cindrel": 0, "rillume": 1}[species]
	for i in range(2):
		if r.options[int(r.stage)][i].theme == preferred: return i
	return 0