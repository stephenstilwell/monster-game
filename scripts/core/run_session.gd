extends RefCounted
const Catalog = preload("res://scripts/core/content_catalog.gd")
const Monster = preload("res://scripts/monsters/monster_state.gd")
const Battle = preload("res://scripts/battle/battle_state.gd")
const PARTY_LIMIT := 4
var catalog := Catalog.new()
var party: Array = []
var storage: Array = []
var inventory := {"charm": 12, "balm": 6}
var claimed: Dictionary = {}
var battle_serial: int = 0
func _init() -> void:
	party = [Monster.create("starter_1", catalog.species.brindlewick, 5), Monster.create("starter_2", catalog.species.cindrel, 4)]

func begin(species_id: String, level: int) -> RefCounted:
	if not catalog.species.has(species_id) or party.is_empty(): return null
	var healthy := false
	for monster: RefCounted in party: healthy = healthy or monster.hp > 0
	if not healthy: return null
	var state := Battle.new()
	battle_serial += 1
	state.id = battle_serial
	state.rng.seed = 74103 + battle_serial * 19537
	for monster: RefCounted in party: state.party.append(monster.clone())
	state.active = state.first_healthy()
	state.inventory = inventory.duplicate()
	state.enemy = Monster.create("wild_%s" % battle_serial, catalog.species[species_id], level, battle_serial)
	return state

func claim(state: RefCounted) -> Dictionary:
	if state.outcome.is_empty() or claimed.has(state.id): return {}
	claimed[state.id] = true
	party.clear()
	for monster: RefCounted in state.party: party.append(monster.clone())
	inventory = state.inventory.duplicate()
	var result := {"placement": "", "xp": 0, "levels": 0}
	if state.outcome == "capture":
		var caught: RefCounted = state.enemy.clone()
		if party.size() < PARTY_LIMIT:
			party.append(caught)
			result.placement = "JOINED THE PARTY."
		else:
			storage.append(caught)
			result.placement = "SENT TO FIELD STORAGE."
	if state.outcome in ["victory", "capture"]:
		result.xp = 8 + state.enemy.level * 4
		var recipient: int = state.active if party[state.active].hp > 0 else state.first_healthy()
		if recipient >= 0:
			result.levels = party[recipient].gain_experience(result.xp, catalog.species[party[recipient].species_id])
	if state.outcome == "defeat":
		for monster: RefCounted in party: monster.hp = monster.max_hp(catalog.species[monster.species_id])
	return result
