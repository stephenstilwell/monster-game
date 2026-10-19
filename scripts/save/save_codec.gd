extends RefCounted
const Session = preload("res://scripts/core/run_session.gd")
const Monster = preload("res://scripts/monsters/monster_state.gd")
const VERSION := 2

static func snapshot(app: Node) -> Dictionary:
	var members: Array = []
	for group: Array in [app.session.party, app.session.storage]:
		var entries: Array = []
		for m: RefCounted in group:
			entries.append({"id": m.id, "species": m.species_id, "level": m.level, "xp": m.experience, "hp": m.hp, "moves": Array(m.moves), "appearance": str(m.appearance_seed)})
		members.append(entries)
	return {"version": VERSION, "members": members, "inventory": app.session.inventory.duplicate(), "serial": app.session.battle_serial, "claimed": app.session.claimed.keys(), "settings": app.session.settings.duplicate(), "location": {"map": app.world.current_map.id, "cell": [app.world.movement.cell.x, app.world.movement.cell.y], "facing": [app.world.movement.facing.x, app.world.movement.facing.y]}, "encounters": {"state": str(app.encounters.rng.state), "cooldown": app.encounters.cooldown, "grass": app.encounters.grass_steps}}

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func decimal(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(value.to_int()) == value

static func decode(raw: Variant, maps: Dictionary) -> Dictionary:
	if not raw is Dictionary: return {"error": "SAVE IS NOT AN OBJECT."}
	var d: Dictionary = raw.duplicate(true)
	if not integer(d.get("version"), 0, 1000000000): return {"error": "INVALID SAVE VERSION."}
	if d.version < 1 or d.version > VERSION: return {"error": "UNSUPPORTED SAVE VERSION."}
	# Version 1 predates settings; defaults are the explicit migration.
	if d.version == 1: d.settings = {"text_speed": 0}
	if not d.get("members") is Array or d.members.size() != 2: return {"error": "INVALID COLLECTIONS."}
	var session := Session.new()
	session.party.clear()
	session.storage.clear()
	var ids: Dictionary = {}
	for group in range(2):
		var entries: Variant = d.members[group]
		if not entries is Array or entries.size() > (4 if group == 0 else 10000) or (group == 0 and entries.is_empty()): return {"error": "INVALID COLLECTION SIZE."}
		for entry: Variant in entries:
			if not entry is Dictionary: return {"error": "INVALID MONSTER."}
			var e: Dictionary = entry
			if not e.get("id") is String or e.id.is_empty() or e.id.length() > 80 or ids.has(e.id) or not session.catalog.species.has(e.get("species")): return {"error": "INVALID MONSTER ID."}
			if not integer(e.get("level"), 1, 20) or not integer(e.get("xp"), 0, 239) or not decimal(e.get("appearance")): return {"error": "INVALID MONSTER PROGRESSION."}
			if e.xp >= (int(e.level) * 12) or (e.level == 20 and e.xp != 0): return {"error": "INVALID EXPERIENCE."}
			var m := Monster.create(e.id, session.catalog.species[e.species], int(e.level), e.appearance.to_int())
			if not integer(e.get("hp"), 0, m.max_hp(session.catalog.species[e.species])) or not e.get("moves") is Array or e.moves != Array(m.moves): return {"error": "INVALID HEALTH OR MOVES."}
			m.hp = int(e.hp)
			m.experience = int(e.xp)
			ids[e.id] = true
			(session.party if group == 0 else session.storage).append(m)
	var healthy := false
	for m: RefCounted in session.party: healthy = healthy or m.hp > 0
	if not healthy: return {"error": "NO HEALTHY PARTY MEMBER."}
	if not d.get("inventory") is Dictionary: return {"error": "INVALID INVENTORY."}
	for key: String in ["balm", "charm"]:
		if not integer(d.inventory.get(key), 0, 1000000): return {"error": "INVALID ITEM COUNT."}
		session.inventory[key] = int(d.inventory[key])
	if not integer(d.get("serial"), 0, 1000000000) or not d.get("claimed") is Array: return {"error": "INVALID BATTLE LEDGER."}
	session.battle_serial = int(d.serial)
	for claim: Variant in d.claimed:
		if not integer(claim, 1, session.battle_serial): return {"error": "INVALID CLAIM."}
		session.claimed[int(claim)] = true
	for id: String in ids:
		if id.begins_with("wild_") and (not id.substr(5).is_valid_int() or id.substr(5).to_int() > session.battle_serial): return {"error": "INVALID CAPTURE SERIAL."}
	if not d.get("settings") is Dictionary or not integer(d.settings.get("text_speed"), 0, 1): return {"error": "INVALID SETTINGS."}
	session.settings.text_speed = int(d.settings.text_speed)
	if not d.get("location") is Dictionary or not maps.has(d.location.get("map")): return {"error": "INVALID LOCATION."}
	var loc: Dictionary = d.location
	if not loc.get("cell") is Array or loc.cell.size() != 2 or not loc.get("facing") is Array or loc.facing.size() != 2: return {"error": "INVALID COORDINATES."}
	for value: Variant in loc.cell + loc.facing:
		if not integer(value, -10000, 10000): return {"error": "INVALID COORDINATE."}
	var cell := Vector2i(int(loc.cell[0]), int(loc.cell[1]))
	var facing := Vector2i(int(loc.facing[0]), int(loc.facing[1]))
	if absi(facing.x) + absi(facing.y) != 1 or not maps[loc.map].can_enter(cell) or not maps[loc.map].portal_at(cell).is_empty(): return {"error": "UNSAFE LOCATION."}
	if not d.get("encounters") is Dictionary: return {"error": "INVALID ENCOUNTER STREAM."}
	var enc: Dictionary = d.encounters
	if not decimal(enc.get("state")) or not integer(enc.get("cooldown"), 0, 6) or not integer(enc.get("grass"), 0, 4): return {"error": "INVALID ENCOUNTER STREAM."}
	return {"session": session, "map": loc.map, "cell": cell, "facing": facing, "encounters": enc}
