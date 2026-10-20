extends RefCounted
const Previous = preload("res://scripts/save/expedition_codec.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Old = preload("res://scripts/save/save_codec.gd")
const Model = preload("res://scripts/progression/expedition_service.gd")
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
		migrated.profile.settings.music = 2
		migrated.profile.settings.sfx = 2
		for m: RefCounted in legacy.session.party + legacy.session.storage:
			migrated.profile.roster.append(Model.record(m.id, m.species_id, str(m.appearance_seed)))
			if not m.species_id in migrated.profile.discovered: migrated.profile.discovered.append(m.species_id)
		Meta.install(migrated)
		return {"data": migrated, "legacy": true}
	if int(raw.version) == 3:
		var previous := Previous.decode(raw, _maps)
		if previous.has("error"): return previous
		var migrated: Dictionary = previous.data
		migrated.version = 4
		migrated.content = "m6.1"
		if not migrated.profile.last.is_empty():
			migrated.profile.last.secured = 0
			migrated.profile.last.bonus = 0
			migrated.profile.last.net_marks = 0
		Meta.install(migrated)
		if not migrated.run.is_empty():
			var r: Dictionary = migrated.run
			r.rules = Meta.snapshot(migrated.profile)
			r.rules.growth = []
			r.rules.legacy = true
			r.rules.xp_multiplier = 1
			r.events = []
			r.secured = 0
			r.marks_start = migrated.profile.meta.marks
			for source: Dictionary in migrated.profile.roster:
				if source.id == r.source: r.source_species = source.species
		return {"data": migrated, "migrated": true}
	if raw.version != 4: return {"error": "UNSUPPORTED SAVE VERSION."}
	if raw.get("content") != "m6.1": return {"error": "UNSUPPORTED CONTENT VERSION."}
	var d: Dictionary = normalize(raw)
	var catalog := Catalog.new()
	if not d.get("profile") is Dictionary or not d.get("run") is Dictionary: return {"error": "INVALID PROFILE OR RUN."}
	var p: Dictionary = d.profile
	if not p.get("roster") is Array or p.roster.is_empty() or p.roster.size() > 20000: return {"error": "INVALID SANCTUARY."}
	var ids: Array = []
	for e: Variant in p.roster:
		if not identity(e, ids, catalog) or not e.species in Meta.BASES: return {"error": "INVALID SANCTUARY IDENTITY."}
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
	if r.is_empty():
		var error := meta_valid(d)
		return {"data": d} if error.is_empty() else {"error": error}
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
	if not unique_list(r.get("relics"), Model.RELICS.keys(), 3) or not unique_list(r.get("offers"), Model.RELICS.keys(), 3) or r.relics.size() > r.rewards.size(): return {"error": "INVALID RELICS."}
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
		if not Old.integer(r.inventory.get(id), 0, 5 if id == "balm" else 5): return {"error": "INVALID SUPPLY COUNT."}
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
	var meta_error := meta_valid(d)
	if not meta_error.is_empty(): return {"error": meta_error}
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
	if r.phase == "reward" and (r.offers.size() > 3 or r.offers.is_empty()): return "INCOMPLETE REWARD OFFER."
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
	if r.source_species != source.species: return "SOURCE SPECIES DOES NOT MATCH SANCTUARY."
	for e: Dictionary in r.party + r.reserve:
		if e.id == "run_%s_starter" % int(r.id):
			if Meta.base(e.species) != source.species or e.appearance != source.appearance or e.level < 5: return "STARTER DOES NOT MATCH SANCTUARY."
		else:
			var suffix: String = e.id.trim_prefix("run_%s_capture_" % int(r.id))
			if str(suffix.to_int()) != suffix or suffix.to_int() < 1 or suffix.to_int() > 6: return "INVALID CAPTURE ORIGIN."
	return ""
static func meta_valid(d: Dictionary) -> String:
	var p: Dictionary = d.profile
	if not p.last.is_empty():
		for key: String in ["secured", "bonus", "net_marks"]:
			if not Old.integer(p.last.get(key), 0, 13): return "INVALID RESULT MARKS."
	var m: Variant = p.get("meta")
	if not m is Dictionary or not m.get("grants") is Dictionary or m.grants.size() > 1000000: return "INVALID META LEDGER."
	if not Old.integer(m.get("marks"), 0, 10000000) or not unique_list(m.get("projects"), Meta.PROJECTS.keys(), 3) or not unique_list(m.get("medals"), Meta.BASES, 3) or not unique_list(m.get("tiers"), [1, 2], 2) or not m.get("pin") in Meta.PROJECTS: return "INVALID META COUNTERS."
	if 2 in m.tiers and not 1 in m.tiers: return "MISSING CHALLENGE PREREQUISITE."
	if (not m.medals.is_empty() or not m.tiers.is_empty()) and p.completed == 0: return "MEDAL WITHOUT VICTORY."
	if not m.get("study") is Dictionary or m.study.size() != 3: return "INVALID STUDY."
	var used: Array = []
	for id: String in Meta.BASES:
		if not m.study.get(id) is Array or m.study[id].size() > 3: return "INVALID STUDY COUNT."
		for event: Variant in m.study[id]:
			if not event is String or event in used or not valid_event(event, "battle_", int(p.next_run), 6): return "INVALID STUDY EVENT."
			used.append(event)
		for kind: String in ["discover", "shelter", "study"]:
			var complete: bool = id in p.discovered if kind == "discover" else Meta.sheltered(p, id) if kind == "shelter" else m.study[id].size() == 3
			if complete != m.grants.has("research/" + id + "/" + kind): return "RESEARCH GRANT MISMATCH."
	var total := 0
	for id: Variant in m.grants:
		if not id is String or not Old.integer(m.grants[id], 1, 1): return "INVALID GRANT."
		if id.begins_with("research/"):
			var parts: PackedStringArray = id.split("/")
			if parts.size() != 3 or not parts[1] in Meta.BASES or not parts[2] in ["discover", "shelter", "study"]: return "UNKNOWN RESEARCH GRANT."
		elif not valid_event(id, "stage_", int(p.next_run), 2) and not valid_event(id, "victory", int(p.next_run), 0): return "UNKNOWN RUN GRANT."
		total += 1
	for id: String in m.projects: total -= int(Meta.PROJECTS[id].cost)
	if m.marks != total: return "MARK BALANCE DOES NOT MATCH LEDGER."
	if not p.get("preparation") is Dictionary: return "INVALID PREPARATION."
	var clone: Dictionary = p.duplicate(true)
	for key: String in ["loadout", "survey", "pool", "tier"]:
		if not p.preparation.has(key) or not Meta.prepare(clone, key, p.preparation[key]).is_empty(): return "INVALID PREPARATION CHOICE."
	for key: String in ["music", "sfx"]:
		if not Old.integer(p.settings.get(key), 0, 3): return "INVALID AUDIO SETTING."
	if d.run.is_empty(): return ""
	var r: Dictionary = d.run
	if not r.get("rules") is Dictionary: return "MISSING DEPARTURE RULES."
	var rules: Dictionary = r.rules
	if not Meta.LOADOUTS.has(rules.get("loadout")) or not rules.get("survey") in Meta.BASES + ["mixed"] or not Meta.POOLS.has(rules.get("pool")) or not Old.integer(rules.get("tier"), 0, 2): return "INVALID DEPARTURE RULES."
	if not unique_list(rules.get("growth"), Meta.BASES, 3) or not unique_list(rules.get("relic_pool"), Meta.RELICS.keys(), 6) or rules.relic_pool.size() < 3: return "INVALID UNLOCK SNAPSHOT."
	if rules.get("xp_multiplier") != (1 if rules.get("legacy", false) else 2): return "INVALID XP RULE."
	if not typeof(rules.get("camp_fraction")) in [TYPE_INT, TYPE_FLOAT]: return "INVALID CAMP RULE TYPE."
	if rules.get("guardian_bonus") != (4 if rules.tier > 0 else 0) or float(rules.get("camp_fraction", 0)) != (0.5 if rules.tier == 2 else 1.0): return "INVALID CHALLENGE RULES."
	if rules.tier > 0 and p.completed == 0: return "LOCKED CHALLENGE SNAPSHOT."
	if rules.tier == 2 and not 1 in m.tiers: return "MISSING CHALLENGE UNLOCK."
	if rules.loadout != "standard" and not "packing" in m.projects: return "UNOWNED LOADOUT."
	if rules.survey != "mixed" and not "trail" in m.projects: return "UNOWNED SURVEY."
	if rules.relic_pool != ["thorn", "shell", "hearth"] and (not "workshop" in m.projects or rules.relic_pool != Meta.POOLS[rules.pool]): return "UNOWNED RELIC POOL."
	for id: String in rules.growth:
		if not id in Meta.growth(p): return "UNOWNED GROWTH."
	if not r.get("source_species") in Meta.BASES or not Old.integer(r.get("marks_start"), 0, 10000000) or not Old.integer(r.get("secured"), 0, 3): return "INVALID RUN META."
	if m.grants.has("run_%s/victory" % int(r.id)): return "ACTIVE RUN ALREADY HAS VICTORY BONUS."
	for stage in range(3):
		if m.grants.has("run_%s/stage_%s" % [int(r.id), stage]):
			if stage > int(r.stage) or (stage == int(r.stage) and r.cleared.size() != 2) or (stage == 2 and r.outcome != "victory"): return "STAGE GRANT WITHOUT COMPLETION."
	if r.secured != Meta.earned(p, int(r.id)): return "SECURED MARKS DO NOT MATCH LEDGER."
	if not unique_list(r.get("events"), [0, 1, 2], 3): return "INVALID FINITE EVENTS."
	for stage: int in r.events:
		if stage > int(r.get("stage", -1)): return "FUTURE TRAIL EVENT."
	for id: String in r.get("relics", []) + r.get("offers", []):
		if not id in rules.relic_pool: return "RELIC OUTSIDE SNAPSHOT."
	for entry: Variant in r.get("party", []) + r.get("reserve", []):
		if entry is Dictionary and entry.get("species") in Meta.FORMS.values():
			if not Meta.base(entry.species) in rules.growth or not Old.integer(entry.get("level"), Meta.GROW_LEVEL, 20): return "LOCKED GROWTH FORM."
	return ""

static func valid_event(id: String, kind: String, next_run: int, maximum: int) -> bool:
	var parts := id.split("/")
	if parts.size() != 2 or not parts[0].begins_with("run_"): return false
	var run_id := parts[0].trim_prefix("run_")
	if not run_id.is_valid_int() or str(run_id.to_int()) != run_id or run_id.to_int() < 1 or run_id.to_int() >= next_run: return false
	if kind == "victory": return parts[1] == kind
	var index := parts[1].trim_prefix(kind)
	return parts[1].begins_with(kind) and index.is_valid_int() and str(index.to_int()) == index and index.to_int() >= (1 if kind == "battle_" else 0) and index.to_int() <= maximum
