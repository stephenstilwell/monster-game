extends "res://scripts/core/run_session.gd"
const Model = preload("res://scripts/expedition/expedition_service.gd")
var run_id: int = 0
var relics: Array = []
var descriptor: Dictionary = {}
var expedition: bool = true

func configure(data: Dictionary) -> void:
	var r: Dictionary = data.run
	run_id = int(r.id)
	party.clear()
	storage.clear()
	for m: Dictionary in r.party: party.append(Model.monster(m))
	for m: Dictionary in r.reserve: storage.append(Model.monster(m))
	inventory = r.inventory.duplicate()
	settings = data.profile.settings.duplicate()
	claimed.clear()
	for id: Variant in r.claimed: claimed[int(id)] = true
	battle_serial = int(r.serial)
	relics = r.relics.duplicate()
	descriptor = r.pending.duplicate(true)

func begin(species_id: String, level: int) -> RefCounted:
	var state: RefCounted = super.begin(species_id, level)
	if state == null: return null
	state.rng.seed = descriptor.seed.to_int()
	state.enemy.id = "run_%s_capture_%s" % [run_id, state.id]
	state.guardian = descriptor.guardian
	state.capture_allowed = party.size() + storage.size() < 8 and not state.guardian
	for id: String in relics:
		state.ally_damage_bonus += Model.RELICS[id].attack
		state.foe_damage_reduction += Model.RELICS[id].guard
	return state

func claim(state: RefCounted) -> Dictionary:
	if claimed.has(state.id) or state.outcome.is_empty(): return {}
	var result: Dictionary
	if state.outcome == "defeat":
		claimed[state.id] = true
		party.clear()
		for m: RefCounted in state.party: party.append(m.clone())
		inventory = state.inventory.duplicate()
		result = {"placement": "", "xp": 0, "levels": 0}
	else:
		result = super.claim(state)
		if state.outcome == "capture" and storage.size() > 0: result.placement = "PARTY OR CAMP RESERVE UPDATED."
	if state.outcome in ["victory", "capture"] and "hearth" in relics:
		for m: RefCounted in party:
			if m.hp > 0: m.hp = mini(m.max_hp(catalog.species[m.species_id]), m.hp + 6)
		result.field_heal = 6
	return result

func apply_to(data: Dictionary, state: RefCounted) -> bool:
	if data.run.is_empty() or int(data.run.id) != run_id or data.run.pending.get("id", -1) != state.id or not claimed.has(state.id) or state.outcome.is_empty(): return false
	var r: Dictionary = data.run
	r.party.clear()
	r.reserve.clear()
	for m: RefCounted in party: r.party.append(Model.member(m))
	for m: RefCounted in storage: r.reserve.append(Model.member(m))
	r.inventory = inventory.duplicate()
	r.serial = battle_serial
	r.claimed = claimed.keys()
	if state.outcome == "capture" and not state.enemy.species_id in data.profile.discovered: data.profile.discovered.append(state.enemy.species_id)
	if state.outcome == "defeat" or descriptor.guardian:
		r.phase = "settle"
		r.outcome = "defeat" if state.outcome == "defeat" else "victory"
	else:
		r.cleared.append(int(descriptor.slot))
	r.pending.clear()
	return true
