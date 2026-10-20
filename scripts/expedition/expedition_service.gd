extends RefCounted
## Pure state mutations. App applies them to a candidate and persists before publishing.
const Catalog = preload("res://scripts/core/content_catalog.gd")
const Monster = preload("res://scripts/monsters/monster_state.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")
const Field = preload("res://scripts/core/field_service.gd")
const RELICS := {
	"thorn": {"title": "THORN LANTERN", "detail": "+3 DAMAGE ON YOUR ATTACKS.", "attack": 3, "guard": 0, "heal": 0},
	"shell": {"title": "RIVER SHELL", "detail": "TAKE 3 LESS DAMAGE PER HIT.", "attack": 0, "guard": 3, "heal": 0},
	"hearth": {"title": "HEARTH SEED", "detail": "LIVING TEAM HEALS 6 AFTER WINS.", "attack": 0, "guard": 0, "heal": 6}}

static func member(m: RefCounted) -> Dictionary:
	return {"id": m.id, "species": m.species_id, "appearance": str(m.appearance_seed), "level": m.level, "xp": m.experience, "hp": m.hp, "moves": Array(m.moves)}

static func monster(e: Dictionary) -> RefCounted:
	var m := Monster.create(e.id, Catalog.new().species[e.species], int(e.level), e.appearance.to_int())
	m.experience = int(e.xp)
	m.hp = int(e.hp)
	return m

static func record(id: String, species: String, appearance: String = "0") -> Dictionary:
	return {"id": id, "species": species, "appearance": appearance}

static func fresh() -> Dictionary:
	return {"version": 3, "content": Routes.CONTENT, "profile": {"roster": [record("starter_1", "brindlewick"), record("starter_2", "cindrel")], "discovered": [], "completed": 0, "settled": [], "next_run": 1, "settings": {"text_speed": 0}, "last": {}}, "run": {}}

static func depart(d: Dictionary, index: int, seed_value: int = -1) -> String:
	if not d.run.is_empty(): return "CONTINUE OR ABANDON YOUR ACTIVE RUN."
	if index < 0 or index >= d.profile.roster.size(): return "CHOOSE A SANCTUARY PARTNER."
	var source: Dictionary = d.profile.roster[index]
	var id: int = d.profile.next_run
	var seed_number: int = (20261019 + id * 7919) % 2147483647 if seed_value < 0 else seed_value
	var plan := Routes.options(seed_number)
	var streams := {}
	for key: String in ["encounter", "battle", "reward"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_number + {"encounter": 202, "battle": 303, "reward": 404}[key]
		streams[key] = str(rng.state)
	streams.layout = plan.state
	var m := Monster.create("run_%s_starter" % id, Catalog.new().species[source.species], 5, source.appearance.to_int())
	d.run = {"id": id, "seed": str(seed_number), "source": source.id, "options": plan.stages, "choices": [], "stage": 0, "phase": "route", "party": [member(m)], "reserve": [], "inventory": {"charm": 4, "balm": 2}, "relics": [], "cleared": [], "rewards": [], "offers": [], "camp_used": false, "serial": 0, "claimed": [], "pending": {}, "streams": streams, "cell": [3, 14], "facing": [0, 1], "outcome": ""}
	d.profile.next_run = id + 1
	return ""

static func choose_route(d: Dictionary, index: int) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase != "route" or index not in [0, 1]: return "CHOOSE AN AVAILABLE ROUTE."
	r.choices.append(index)
	r.phase = "field"
	r.cleared.clear()
	r.cell = [3, 14]
	r.facing = [0, 1]
	return ""

static func map_for(r: Dictionary) -> Resource:
	return Routes.build(r.options[int(r.stage)][int(r.choices[int(r.stage)])], int(r.stage), r.cleared)

static func prepare(d: Dictionary, slot: int, guardian: bool = false) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase != "field" or not r.pending.is_empty(): return "ENCOUNTER IS NOT AVAILABLE."
	if guardian:
		if r.stage != 2 or r.cleared.size() != 2 or r.rewards.size() != 3: return "THE GUARDIAN IS NOT READY."
	elif slot not in [0, 1] or slot in r.cleared: return "THIS FERN LIGHT IS ALREADY CLEAR."
	var rng := RandomNumberGenerator.new()
	rng.state = r.streams.encounter.to_int()
	var theme: int = r.options[int(r.stage)][int(r.choices[int(r.stage)])].theme
	var species: String = "brindlewick" if guardian else Routes.SPECIES[(theme + slot) % 3]
	var level: int = 7 if guardian else 2 + int(r.stage) + rng.randi_range(0, 1)
	r.streams.encounter = str(rng.state)
	rng.state = r.streams.battle.to_int()
	var battle_seed := str(rng.randi())
	r.streams.battle = str(rng.state)
	r.pending = {"slot": slot, "guardian": guardian, "species": species, "level": level, "seed": battle_seed, "id": int(r.serial) + 1}
	return ""

static func exit_stage(d: Dictionary) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase != "field" or not r.pending.is_empty(): return "FINISH THE CURRENT ENCOUNTER."
	if r.cleared.size() != 2: return "CLEAR BOTH MARKED FERN LIGHTS FIRST."
	if not int(r.stage) in r.rewards:
		r.phase = "reward"
		r.offers.clear()
		var rng := RandomNumberGenerator.new()
		rng.state = r.streams.reward.to_int()
		var pool: Array = RELICS.keys()
		while not pool.is_empty():
			var chosen: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			if not chosen in r.relics: r.offers.append(chosen)
		r.streams.reward = str(rng.state)
		return ""
	if r.stage == 0:
		r.stage = 1
		r.phase = "route"
	elif r.stage == 1: r.phase = "camp"
	else: return prepare(d, 2, true)
	return ""

static func relic(d: Dictionary, id: String) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase != "reward" or not id in r.offers or id in r.relics: return "CHOOSE AN OFFERED RELIC."
	r.relics.append(id)
	r.rewards.append(int(r.stage))
	r.offers.clear()
	r.phase = "field"
	return exit_stage(d)

static func camp(d: Dictionary, action: String) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase != "camp": return "RESERVE AND REST ARE CAMP ONLY."
	if action == "rest":
		if r.camp_used: return "CAMP REST IS ALREADY SPENT."
		for entry: Dictionary in r.party + r.reserve:
			var m := monster(entry)
			entry.hp = m.max_hp(Catalog.new().species[m.species_id])
		r.camp_used = true
	elif action == "continue":
		r.stage = 2
		r.phase = "route"
	else: return "UNKNOWN CAMP ACTION."
	return ""

static func request_end(d: Dictionary, outcome: String) -> String:
	if d.run.is_empty() or d.run.phase == "settle": return "NO RUN TO SETTLE."
	if outcome == "retreat" and d.run.phase != "camp": return "RETREAT IS CAMP ONLY."
	if outcome not in ["retreat", "abandon"]: return "INVALID RETURN REQUEST."
	d.run.phase = "settle"
	d.run.outcome = outcome
	d.run.pending.clear()
	return ""

static func eligible(r: Dictionary) -> Array:
	var result: Array = []
	if r.is_empty() or r.outcome not in ["victory", "retreat"]: return result
	for m: Dictionary in r.party + r.reserve:
		if m.id != "run_%s_starter" % int(r.id) and m.hp > 0: result.append(m)
	return result

static func settle(d: Dictionary, recruit_id: String) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase != "settle" or r.id in d.profile.settled: return "THIS RUN CANNOT SETTLE AGAIN."
	var recruit: Dictionary = {}
	if not recruit_id.is_empty():
		for m: Dictionary in eligible(r):
			if m.id == recruit_id: recruit = m
		if recruit.is_empty(): return "THAT PARTNER CANNOT RETURN."
	if not recruit.is_empty(): d.profile.roster.append(record(recruit.id, recruit.species, recruit.appearance))
	d.profile.settled.append(int(r.id))
	if r.outcome == "victory": d.profile.completed += 1
	d.profile.last = {"id": int(r.id), "outcome": r.outcome, "recruit": recruit.get("species", "")}
	d.run = {}
	return ""

static func field_action(d: Dictionary, action: String, index: int, target: int = 0) -> String:
	var r: Dictionary = d.run
	if r.is_empty() or r.phase not in ["field", "camp"] or not r.pending.is_empty(): return "FIELD ACTION IS NOT AVAILABLE."
	if action in ["release_party", "release_reserve"]:
		if r.phase != "camp": return "RELEASE IS CAMP ONLY."
		var group: Array = r.party if action == "release_party" else r.reserve
		if index < 0 or index >= group.size(): return "INVALID COMPANION SLOT."
		if group[index].id == "run_%s_starter" % int(r.id): return "YOUR STARTER MUST STAY WITH THE RUN."
		if action == "release_party":
			var healthy := false
			for i in range(group.size()):
				if i != index and group[i].hp > 0: healthy = true
			if not healthy: return "KEEP A HEALTHY PARTNER."
		group.remove_at(index)
		return ""
	if action in ["deposit", "withdraw"] and r.phase != "camp": return "RESERVE EXCHANGES ARE CAMP ONLY."
	if action == "deposit" and r.reserve.size() >= 4: return "THE FOUR RESERVE SLOTS ARE FULL."
	var session := preload("res://scripts/core/run_session.gd").new()
	session.party.clear()
	session.storage.clear()
	for m: Dictionary in r.party: session.party.append(monster(m))
	for m: Dictionary in r.reserve: session.storage.append(monster(m))
	session.inventory = r.inventory.duplicate()
	var message: String
	match action:
		"balm": message = Field.balm(session, index)
		"deposit": message = Field.deposit(session, index)
		"withdraw": message = Field.withdraw(session, index, target)
		"lead":
			if index < 0 or index >= session.party.size(): return "INVALID PARTY SLOT."
			var m: RefCounted = session.party.pop_at(index)
			session.party.push_front(m)
			message = "PARTY ORDER UPDATED."
		_: return "UNKNOWN FIELD ACTION."
	if not message in ["BALM RESTORED HEALTH.", "MOVED TO STORAGE.", "JOINED THE PARTY.", "PARTY ORDER UPDATED."] and not message.begins_with("EXCHANGED WITH"): return message
	r.party.clear()
	r.reserve.clear()
	for m: RefCounted in session.party: r.party.append(member(m))
	for m: RefCounted in session.storage: r.reserve.append(member(m))
	r.inventory = session.inventory.duplicate()
	return ""