extends "res://scripts/core/run_session.gd"
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
var rules: Dictionary = {}
var grew: bool = false
var run_id: int = 0
var relics: Array = []
var descriptor: Dictionary = {}
var expedition: bool = true

func configure(data: Dictionary) -> void:
	var r: Dictionary = data.run
	run_id = int(r.id)
	rules = r.rules.duplicate(true)
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
	state.foe_damage_bonus = int(rules.guardian_bonus) if state.guardian else 0
	state.risk_bonus = 7 if "emberglass" in relics else 0
	state.opening_bonus = 6 if "swift" in relics else 0
	state.capture_bonus = 0.15 if "charmleaf" in relics else 0.0
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
	if state.outcome in ["victory", "capture"]:
		# Expedition-local growth must be usable before the guardian, not only after it.
		var bonus: int = int(result.xp) * (int(rules.xp_multiplier) - 1)
		var recipient: int = state.active
		if party[recipient].hp <= 0:
			for i in range(party.size()):
				if party[i].hp > 0: recipient = i; break
		result.levels += party[recipient].gain_experience(bonus, catalog.species[party[recipient].species_id])
		result.xp += bonus
		for m: RefCounted in party + storage:
			if m.species_id in rules.growth and m.level >= Meta.GROW_LEVEL:
				var old_max: int = m.max_hp(catalog.species[m.species_id])
				m.species_id = Meta.FORMS[m.species_id]
				m.moves.assign(catalog.species[m.species_id].moves)
				if m.hp > 0: m.hp += m.max_hp(catalog.species[m.species_id]) - old_max
				result.grew = true
				grew = true
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
	Meta.battle(data, state.outcome, state.party[state.active].species_id, descriptor.guardian, state.id)
	r.pending.clear()
	return true
