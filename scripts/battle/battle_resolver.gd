extends RefCounted
## Scene-independent, seeded rules. Invalid commands change neither state nor RNG.
var catalog: RefCounted
func _init(content: RefCounted) -> void:
	catalog = content

static func affinity_multiplier(attack: String, defense: String) -> float:
	if {"grove": "brook", "brook": "ember", "ember": "grove"}.get(attack, "") == defense:
		return 1.5
	if {"brook": "grove", "ember": "brook", "grove": "ember"}.get(attack, "") == defense:
		return 0.75
	return 1.0

func validate(state: RefCounted, command: Dictionary) -> String:
	if not state.outcome.is_empty(): return "THIS BATTLE HAS ENDED."
	if state.active < 0 or state.active >= state.party.size(): return "NO ACTIVE COMPANION."
	if state.enemy.hp <= 0: return "NO WILD COMPANION REMAINS."
	if typeof(command.get("kind", null)) != TYPE_STRING: return "CHOOSE A VALID COMMAND."
	var ally: RefCounted = state.party[state.active]
	var kind: String = command.get("kind", "")
	if ally.hp <= 0 and kind != "switch": return "CHOOSE A HEALTHY COMPANION."
	match kind:
		"move":
			if not command.get("move", "") in ally.moves or not catalog.moves.has(command.get("move", "")): return "THAT MOVE IS NOT AVAILABLE."
		"switch":
			if typeof(command.get("index", null)) != TYPE_INT: return "THAT SLOT IS EMPTY."
			var index: int = command.get("index", -1)
			if index < 0 or index >= state.party.size(): return "THAT SLOT IS EMPTY."
			if index == state.active: return "ALREADY IN THE FIELD."
			if state.party[index].hp <= 0: return "THAT COMPANION NEEDS REST."
		"item":
			if typeof(command.get("item", null)) != TYPE_STRING: return "THAT ITEM IS NOT AVAILABLE."
			var item: String = command.get("item", "")
			if not catalog.items.has(item): return "THAT ITEM IS NOT AVAILABLE."
			if state.inventory.get(item, 0) <= 0: return "NONE LEFT IN THE BAG."
			if item == "balm" and ally.hp >= ally.max_hp(catalog.species[ally.species_id]): return "HEALTH IS ALREADY FULL."
		"flee": pass
		_: return "CHOOSE A VALID COMMAND."
	return ""

func resolve(state: RefCounted, command: Dictionary) -> Dictionary:
	var error := validate(state, command)
	if not error.is_empty(): return {"valid": false, "message": error, "events": []}
	var events: Array[Dictionary] = []
	if state.party[state.active].hp <= 0:
		state.active = int(command.index)
		events.append({"kind": "switch", "index": state.active, "message": "GO, %s!" % title(state.party[state.active])})
		return {"valid": true, "events": events}
	state.turn += 1
	var enemy_move: String = state.enemy.moves[state.rng.randi_range(0, state.enemy.moves.size() - 1)]
	var priority: int = 0
	if command.kind == "move": priority = catalog.moves[command.move].priority
	elif command.kind == "switch": priority = 5
	elif command.kind == "item": priority = catalog.items[command.item].priority
	elif command.kind == "flee": priority = 7
	var enemy_priority: int = catalog.moves[enemy_move].priority
	var ally: RefCounted = state.party[state.active]
	var ally_speed: int = ally.speed(catalog.species[ally.species_id])
	var enemy_speed: int = state.enemy.speed(catalog.species[state.enemy.species_id])
	var first: bool = priority > enemy_priority or (priority == enemy_priority and ally_speed > enemy_speed)
	if priority == enemy_priority and ally_speed == enemy_speed:
		first = state.rng.randi_range(0, 1) == 0
	for side: String in (["ally", "foe"] if first else ["foe", "ally"]):
		if not state.outcome.is_empty(): break
		if side == "foe":
			attack(state, state.enemy, state.party[state.active], enemy_move, "foe", events)
		else:
			if state.party[state.active].hp <= 0: break
			apply_command(state, command, events)
		check_end(state, events)
	return {"valid": true, "events": events}

func title(monster: RefCounted) -> String:
	return catalog.species[monster.species_id].title

func capture_chance(state: RefCounted) -> float:
	var species: Resource = catalog.species[state.enemy.species_id]
	var missing: float = 1.0 - float(state.enemy.hp) / state.enemy.max_hp(species)
	return clampf(species.catch_rate + missing * 0.6 + (0.10 if state.habitat == "forest" and species.affinity in ["grove", "brook"] else 0.0), 0.1, 0.95)

func apply_command(state: RefCounted, command: Dictionary, events: Array[Dictionary]) -> void:
	var ally: RefCounted = state.party[state.active]
	match command.kind:
		"move":
			if ally.hp > 0: attack(state, ally, state.enemy, command.move, "ally", events)
		"switch":
			state.active = int(command.index)
			events.append({"kind": "switch", "index": state.active, "message": "GO, %s!" % title(state.party[state.active])})
		"item":
			state.inventory[command.item] -= 1
			if command.item == "balm":
				ally.hp = mini(ally.max_hp(catalog.species[ally.species_id]), ally.hp + catalog.items.balm.value)
				events.append({"kind": "heal", "index": state.active, "hp": ally.hp, "effect": "heal", "message": "TRAIL BALM RESTORED HEALTH."})
			else:
				var caught: bool = state.rng.randf() < capture_chance(state)
				events.append({"kind": "capture", "effect": "charm", "message": "THE CHARM HELD ITS LIGHT!" if caught else "THE WILD LIGHT SLIPPED FREE."})
				if caught: state.outcome = "capture"
		"flee":
			state.flee_attempts += 1
			var delta: int = ally.speed(catalog.species[ally.species_id]) - state.enemy.speed(catalog.species[state.enemy.species_id])
			var escaped: bool = state.rng.randf() < clampf(0.6 + delta * 0.025 + (state.flee_attempts - 1) * 0.12, 0.15, 0.95)
			events.append({"kind": "flee", "message": "YOU FOUND A QUIET WAY OUT." if escaped else "THE TRAIL WAS CUT OFF!"})
			if escaped: state.outcome = "flee"

func attack(state: RefCounted, attacker: RefCounted, defender: RefCounted, move_id: String, side: String, events: Array[Dictionary]) -> void:
	if attacker.hp <= 0 or defender.hp <= 0: return
	var move: Resource = catalog.moves[move_id]
	if state.rng.randf() >= move.accuracy:
		events.append({"kind": "miss", "side": side, "message": "%s MISSED!" % move.title})
		return
	var a: Resource = catalog.species[attacker.species_id]
	var d: Resource = catalog.species[defender.species_id]
	var multiplier := affinity_multiplier(move.affinity, d.affinity)
	var damage := maxi(1, floori((move.power + attacker.attack(a) * 0.7 - defender.defense(d) * 0.45) * multiplier * (1.15 if move.affinity == a.affinity else 1.0) * state.rng.randf_range(0.9, 1.05)))
	defender.hp = maxi(0, defender.hp - damage)
	events.append({"kind": "hit", "side": side, "index": state.active, "hp": defender.hp, "effect": move.effect, "message": "%s USED %s. %s DAMAGE!" % [title(attacker), move.title, damage]})

func check_end(state: RefCounted, events: Array[Dictionary]) -> void:
	if not state.outcome.is_empty(): return
	if state.enemy.hp <= 0:
		state.outcome = "victory"
		events.append({"kind": "end", "message": "THE WILD COMPANION WITHDREW."})
	elif state.first_healthy() < 0:
		state.outcome = "defeat"
		events.append({"kind": "end", "message": "YOUR COMPANIONS NEED REST."})
	elif state.party[state.active].hp <= 0:
		events.append({"kind": "faint", "message": "CHOOSE A HEALTHY COMPANION."})
