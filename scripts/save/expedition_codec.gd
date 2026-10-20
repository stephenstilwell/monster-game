extends RefCounted
const Old = preload("res://scripts/save/save_codec.gd")
const Model = preload("res://scripts/expedition/expedition_service.gd")
const Catalog = preload("res://scripts/core/content_catalog.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")

static func unique_list(value: Variant, allowed: Array, maximum: int) -> bool:
	if not value is Array or value.size() > maximum: return false
	var seen: Array = []
	for entry: Variant in value:
		if not entry in allowed or entry in seen: return false
		seen.append(entry)
	return true

static func identity(e: Variant, ids: Array, catalog: RefCounted) -> bool:
	return e is Dictionary and e.get("id") is String and not e.id.is_empty() and e.id.length() <= 100 and not e.id in ids and catalog.species.has(e.get("species")) and Old.decimal(e.get("appearance"))

static func combat(e: Dictionary, catalog: RefCounted) -> bool:
	if not Old.integer(e.get("level"), 1, 20) or not Old.integer(e.get("xp"), 0, 239): return false
	if e.xp >= int(e.level) * 12 or (e.level == 20 and e.xp != 0): return false
	if not e.get("moves") is Array or e.moves != Array(catalog.species[e.species].moves): return false
	var maximum: int = catalog.species[e.species].base_hp + int(e.level) * 4
	return Old.integer(e.get("hp"), 0, maximum)

static func decode(raw: Variant, _maps: Dictionary) -> Dictionary:
	if not raw is Dictionary: return {"error": "SAVE IS NOT AN OBJECT."}
	if not Old.integer(raw.get("version"), 0, 1000000000): return {"error": "INVALID SAVE VERSION."}
	if int(raw.version) in [1, 2]:
		var legacy := Old.decode(raw, {"town": load("res://data/maps/town.tres"), "forest": load("res://data/maps/forest.tres")})
		if legacy.has("error"): return legacy
		var migrated := Model.fresh()
		migrated.profile.roster.clear()
		migrated.profile.settings = legacy.session.settings.duplicate()
		for m: RefCounted in legacy.session.party + legacy.session.storage:
			migrated.profile.roster.append(Model.record(m.id, m.species_id, str(m.appearance_seed)))
			if not m.species_id in migrated.profile.discovered: migrated.profile.discovered.append(m.species_id)
		return {"data": migrated, "legacy": true}
	if raw.version != 3: return {"error": "UNSUPPORTED SAVE VERSION."}
	if raw.get("content") != Routes.CONTENT: return {"error": "UNSUPPORTED CONTENT VERSION."}
	var d: Dictionary = normalize(raw)
	var catalog := Catalog.new()
	if not d.get("profile") is Dictionary or not d.get("run") is Dictionary: return {"error": "INVALID PROFILE OR RUN."}
	var p: Dictionary = d.profile
	if not p.get("roster") is Array or p.roster.is_empty() or p.roster.size() > 20000: return {"error": "INVALID SANCTUARY."}
	var ids: Array = []
	for e: Variant in p.roster:
		if not identity(e, ids, catalog): return {"error": "INVALID SANCTUARY IDENTITY."}
		ids.append(e.id)
	if not unique_list(p.get("discovered"), Routes.SPECIES, 3): return {"error": "INVALID DISCOVERY JOURNAL."}
	if not Old.integer(p.get("completed"), 0, 1000000) or not Old.integer(p.get("next_run"), 1, 1000001): return {"error": "INVALID PROFILE COUNTERS."}
	if not p.get("settled") is Array or p.settled.size() > 1000000: return {"error": "INVALID SETTLEMENT LEDGER."}
	var ledger: Array = []
	for id: Variant in p.settled:
		if not Old.integer(id, 1, int(p.next_run) - 1) or id in ledger: return {"error": "INVALID SETTLED RUN."}
		ledger.append(id)
	if p.completed > ledger.size(): return {"error": "INVALID COMPLETION COUNT."}
	if not p.get("settings") is Dictionary or not Old.integer(p.settings.get("text_speed"), 0, 1): return {"error": "INVALID SETTINGS."}
	if not p.get("last") is Dictionary: return {"error": "INVALID LAST RESULT."}
	if not p.last.is_empty():
		if not p.last.get("id") in ledger or p.last.get("outcome") not in ["victory", "retreat", "defeat", "abandon"] or not p.last.get("recruit") in Routes.SPECIES + [""]: return {"error": "INVALID LAST RESULT."}
	var r: Dictionary = d.run
	if int(p.next_run) != ledger.size() + (1 if r.is_empty() else 2): return {"error": "PROFILE RUN SEQUENCE HAS A GAP."}
	for id in range(1, ledger.size() + 1):
		if not id in ledger: return {"error": "MISSING SETTLED RUN."}
	if r.is_empty(): return {"data": d}
	if not Old.integer(r.get("id"), 1, int(p.next_run) - 1) or r.id in ledger or r.id != int(p.next_run) - 1 or not r.get("source") in ids: return {"error": "INVALID ACTIVE RUN."}
	if not Old.decimal(r.get("seed")) or not Old.integer(r.seed.to_int(), 0, 2147483647): return {"error": "INVALID RUN SEED."}
	if not Old.integer(r.get("stage"), 0, 2) or r.get("phase") not in ["route", "field", "reward", "camp", "settle"]: return {"error": "INVALID RUN PHASE."}
	if not r.get("options") is Array or r.options.size() != 3: return {"error": "INVALID ROUTE PLAN."}
	for options: Variant in r.options:
		if not options is Array or options.size() != 2: return {"error": "INVALID ROUTE CHOICES."}
		for option: Variant in options:
			if not option is Dictionary or not Old.integer(option.get("template"), 0, 2) or not Old.integer(option.get("theme"), 0, 2) or not Old.decimal(option.get("seed")): return {"error": "INVALID ROUTE TEMPLATE."}
	if not r.get("choices") is Array: return {"error": "INVALID CHOSEN ROUTES."}
	var expected: int = int(r.stage) + (0 if r.phase == "route" else 1)
	if r.choices.size() != expected and not (r.phase == "settle" and r.get("outcome", "") == "abandon" and r.choices.size() == int(r.stage)): return {"error": "INVALID CHOSEN ROUTES."}
	for choice: Variant in r.choices:
		if not Old.integer(choice, 0, 1): return {"error": "INVALID ROUTE INDEX."}
	if not unique_list(r.get("cleared"), [0, 1], 2) or not unique_list(r.get("rewards"), [0, 1, 2], 3): return {"error": "INVALID FINITE REWARDS."}
	if not unique_list(r.get("relics"), Model.RELICS.keys(), 3) or not unique_list(r.get("offers"), Model.RELICS.keys(), 3) or r.relics.size() != r.rewards.size(): return {"error": "INVALID RELICS."}
	for id: String in r.offers:
		if id in r.relics: return {"error": "REPEATED RELIC OFFER."}
	if r.phase == "reward" and (r.offers.is_empty() or r.cleared.size() != 2 or int(r.stage) in r.rewards): return {"error": "INVALID REWARD PHASE."}
	if r.phase == "camp" and (r.stage != 1 or r.rewards.size() != 2): return {"error": "INVALID CAMP PHASE."}
	if not r.get("camp_used") is bool: return {"error": "INVALID CAMP BUDGET."}
	if not r.get("outcome") in ["", "victory", "retreat", "defeat", "abandon"] or (r.phase == "settle") != (r.outcome != ""): return {"error": "INVALID OUTCOME."}
	if not Old.integer(r.get("serial"), 0, 100000) or not r.get("claimed") is Array: return {"error": "INVALID BATTLE LEDGER."}
	var claimed: Array = []
	for id: Variant in r.claimed:
		if not Old.integer(id, 1, int(r.serial)) or id in claimed: return {"error": "INVALID CLAIM."}
		claimed.append(id)
	if not r.get("inventory") is Dictionary: return {"error": "INVALID SUPPLIES."}
	for id: String in ["balm", "charm"]:
		if not Old.integer(r.inventory.get(id), 0, 2 if id == "balm" else 4): return {"error": "INVALID SUPPLY COUNT."}
	if not r.get("party") is Array or r.party.is_empty() or r.party.size() > 4 or not r.get("reserve") is Array or r.reserve.size() > 4: return {"error": "INVALID PARTY OR RESERVE."}
	var run_ids: Array = []
	var healthy := false
	for e: Variant in r.party + r.reserve:
		if not identity(e, ids + run_ids, catalog) or not combat(e, catalog): return {"error": "INVALID EXPEDITION MEMBER."}
		if e.id != "run_%s_starter" % int(r.id):
			var prefix := "run_%s_capture_" % int(r.id)
			if not e.id.begins_with(prefix) or not e.id.trim_prefix(prefix).is_valid_int() or not e.id.trim_prefix(prefix).to_int() in claimed: return {"error": "INVALID CAPTURE ID."}
		run_ids.append(e.id)
		if e in r.party and e.hp > 0: healthy = true
	if not "run_%s_starter" % int(r.id) in run_ids: return {"error": "STARTER COPY IS MISSING."}
	if not healthy and not (r.phase == "settle" and r.outcome in ["defeat", "abandon"]): return {"error": "NO HEALTHY PARTY MEMBER."}
	if not r.get("streams") is Dictionary: return {"error": "INVALID RNG STREAMS."}
	for id: String in ["layout", "encounter", "battle", "reward"]:
		if not Old.decimal(r.streams.get(id)): return {"error": "INVALID RNG STATE."}
	for key: String in ["cell", "facing"]:
		if not r.get(key) is Array or r[key].size() != 2: return {"error": "INVALID RUN POSITION."}
		for value: Variant in r[key]:
			if not Old.integer(value, -100, 100): return {"error": "INVALID POSITION VALUE."}
	if absi(int(r.facing[0])) + absi(int(r.facing[1])) != 1: return {"error": "INVALID FACING."}
	if r.choices.size() > int(r.stage):
		var map: Resource = Model.map_for(r)
		if not map.can_enter(Vector2i(int(r.cell[0]), int(r.cell[1]))): return {"error": "UNSAFE RUN POSITION."}
	if not r.get("pending") is Dictionary: return {"error": "INVALID PENDING ENCOUNTER."}
	if not r.pending.is_empty():
		var e: Dictionary = r.pending
		if r.phase != "field" or not e.get("guardian") is bool or not Old.integer(e.get("slot"), 0, 2) or not e.get("species") in Routes.SPECIES or not Old.integer(e.get("level"), 1, 20) or not Old.decimal(e.get("seed")) or e.get("id") != int(r.serial) + 1: return {"error": "INVALID ENCOUNTER DESCRIPTOR."}
		if e.guardian and (r.stage != 2 or r.rewards.size() != 3 or e.slot != 2 or e.species != "brindlewick"): return {"error": "INVALID GUARDIAN."}
		if not e.guardian and (e.slot not in [0, 1] or e.slot in r.cleared): return {"error": "REPEATED ENCOUNTER."}
	var consistency_error := invariants(d, claimed, healthy)
	if not consistency_error.is_empty(): return {"error": consistency_error}
	return {"data": d}

static func normalize(value: Variant) -> Variant:
	# JSON numbers arrive as floats; retain fractional values for rejection.
	if value is float and is_finite(value) and value == floor(value) and absf(value) < 9007199254740992.0: return int(value)
	if value is Array:
		var result: Array = []
		for entry: Variant in value: result.append(normalize(entry))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[key] = normalize(value[key])
		return result
	return value
static func invariants(d: Dictionary, claimed: Array, healthy: bool) -> String:
	var r: Dictionary = d.run
	var p: Dictionary = d.profile
	var plan := Routes.options(r.seed.to_int())
	if r.options != plan.stages or r.streams.layout != plan.state: return "ROUTE PLAN DOES NOT MATCH ITS SEED."
	if r.rewards != range(r.rewards.size()) or r.rewards.size() > int(r.stage) + 1: return "INVALID REWARD CHRONOLOGY."
	if r.phase in ["route", "reward"] and r.rewards.size() != int(r.stage): return "INVALID STAGE REWARDS."
	if r.phase != "reward" and not r.offers.is_empty(): return "UNEXPECTED REWARD OFFER."
	if r.phase == "reward" and r.offers.size() != 3 - r.relics.size(): return "INCOMPLETE REWARD OFFER."
	if r.phase == "field" and r.rewards.size() != int(r.stage) and not (r.stage == 2 and r.rewards.size() == 3 and r.pending.get("guardian", false)): return "INVALID FIELD REWARD STATE."
	if r.phase != "field" and not r.pending.is_empty(): return "UNEXPECTED PENDING ENCOUNTER."
	if r.outcome == "victory" and (r.stage != 2 or r.rewards.size() != 3 or r.cleared.size() != 2): return "VICTORY WITHOUT GUARDIAN PROGRESS."
	if r.outcome == "retreat" and (r.stage != 1 or r.rewards.size() != 2): return "RETREAT OUTSIDE CAMP."
	if r.outcome == "defeat" and healthy: return "DEFEAT WITH A HEALTHY TEAM."
	var wild_claims: int = int(r.stage) * 2 + (r.cleared.size() if r.choices.size() > int(r.stage) else 0)
	var total_claims: int = wild_claims + (1 if r.outcome in ["victory", "defeat"] else 0)
	if r.serial != total_claims or claimed.size() != total_claims: return "BATTLE LEDGER DOES NOT MATCH PROGRESS."
	for id in range(1, total_claims + 1):
		if not id in claimed: return "MISSING BATTLE CLAIM."
	var source: Dictionary = {}
	for e: Dictionary in p.roster:
		if e.id == r.source: source = e
	for e: Dictionary in r.party + r.reserve:
		if e.id == "run_%s_starter" % int(r.id):
			if e.species != source.species or e.appearance != source.appearance or e.level < 5: return "STARTER DOES NOT MATCH SANCTUARY."
		else:
			var suffix: String = e.id.trim_prefix("run_%s_capture_" % int(r.id))
			if str(suffix.to_int()) != suffix or suffix.to_int() < 1 or suffix.to_int() > 6: return "INVALID CAPTURE ORIGIN."
	return ""