extends RefCounted
## Permanent progression; callers mutate only unpublished save candidates.
const BASES := ["brindlewick", "cindrel", "rillume"]
const FORMS := {"brindlewick": "briarwarden", "cindrel": "pyrelace", "rillume": "tideveil"}
const PROJECTS := {"trail": {"title": "TRAIL DESK", "cost": 4, "detail": "SURVEY A SPECIES IN STAGE TWO."}, "packing": {"title": "PACKING BENCH", "cost": 5, "detail": "CHOOSE CATCHER OR CARE SUPPLIES."}, "workshop": {"title": "LANTERN WORKSHOP", "cost": 6, "detail": "SIX RELICS. OPTIONAL FOCUS POOL."}}
const LOADOUTS := {"standard": {"charm": 4, "balm": 2}, "catcher": {"charm": 5, "balm": 1}, "care": {"charm": 2, "balm": 3}}
const RELICS := {
	"thorn": {"title": "THORN LANTERN", "detail": "+3 DAMAGE ON ALL YOUR ATTACKS.", "attack": 3, "guard": 0, "heal": 0},
	"shell": {"title": "RIVER SHELL", "detail": "TAKE 3 LESS DAMAGE. MINIMUM 1.", "attack": 0, "guard": 3, "heal": 0},
	"hearth": {"title": "HEARTH SEED", "detail": "LIVING TEAM HEALS 6 AFTER WINS.", "attack": 0, "guard": 0, "heal": 6},
	"emberglass": {"title": "EMBER GLASS", "detail": "+7 DAMAGE AT HALF HEALTH OR LESS.", "attack": 0, "guard": 0, "heal": 0},
	"swift": {"title": "DAWN FEATHER", "detail": "+6 DAMAGE ON YOUR FIRST TURN.", "attack": 0, "guard": 0, "heal": 0},
	"charmleaf": {"title": "CHARM LEAF", "detail": "+15 PERCENT CAPTURE CHANCE. MAX 95.", "attack": 0, "guard": 0, "heal": 0}}
const POOLS := {"mixed": ["thorn", "shell", "hearth", "emberglass", "swift", "charmleaf"], "focus": ["emberglass", "swift", "charmleaf"]}
const GROW_LEVEL := 7

static func base(id: String) -> String:
	for key: String in FORMS:
		if FORMS[key] == id: return key
	return id

static func install(d: Dictionary) -> void:
	var p: Dictionary = d.profile
	p.meta = {"marks": 0, "projects": [], "grants": {}, "study": {}, "medals": [], "tiers": [], "pin": "trail"}
	p.preparation = {"loadout": "standard", "survey": "mixed", "pool": "mixed", "tier": 0}
	p.settings.music = 2
	p.settings.sfx = 2
	for id: String in BASES: p.meta.study[id] = []
	sync_research(p)

static func grant(p: Dictionary, id: String, amount: int = 1) -> bool:
	if p.meta.grants.has(id): return false
	p.meta.grants[id] = amount
	p.meta.marks += amount
	return true

static func sheltered(p: Dictionary, id: String) -> bool:
	for m: Dictionary in p.roster:
		if base(m.species) == id: return true
	return false

static func sync_research(p: Dictionary) -> void:
	for id: String in BASES:
		if id in p.discovered: grant(p, "research/" + id + "/discover")
		if sheltered(p, id): grant(p, "research/" + id + "/shelter")
		if p.meta.study[id].size() == 3: grant(p, "research/" + id + "/study")

static func growth(p: Dictionary) -> Array:
	var result: Array = []
	for id: String in BASES:
		if sheltered(p, id) and p.meta.study[id].size() == 3: result.append(id)
	return result

static func battle(d: Dictionary, outcome: String, active_species: String, guardian: bool, encounter: int) -> void:
	var p: Dictionary = d.profile
	var r: Dictionary = d.run
	if outcome == "victory" and not guardian:
		var id := base(active_species)
		var event := "run_%s/battle_%s" % [int(r.id), encounter]
		if p.meta.study[id].size() < 3 and not event in p.meta.study[id]: p.meta.study[id].append(event)
	sync_research(p)
	if guardian and outcome == "victory":
		grant(p, "run_%s/stage_2" % int(r.id))
		r.secured = earned(p, int(r.id))

static func earned(p: Dictionary, run_id: int) -> int:
	var total := 0
	for id: String in p.meta.grants:
		if id.begins_with("run_%s/" % run_id): total += int(p.meta.grants[id])
	return total

static func buy(d: Dictionary, id: String) -> String:
	if not d.run.is_empty(): return "PROJECTS ARE HUB ONLY."
	if not PROJECTS.has(id): return "UNKNOWN PROJECT."
	var m: Dictionary = d.profile.meta
	if id in m.projects: return "PROJECT ALREADY BUILT."
	if m.marks < PROJECTS[id].cost: return "NOT ENOUGH RESEARCH MARKS."
	m.marks -= PROJECTS[id].cost
	m.projects.append(id)
	return ""

static func prepare(p: Dictionary, key: String, value: Variant) -> String:
	var choices: Dictionary = p.preparation
	match key:
		"loadout":
			if not LOADOUTS.has(value) or (value != "standard" and not "packing" in p.meta.projects): return "BUILD THE PACKING BENCH FIRST."
		"survey":
			if not value in BASES + ["mixed"] or (value != "mixed" and not "trail" in p.meta.projects): return "BUILD THE TRAIL DESK FIRST."
		"pool":
			if not POOLS.has(value) or (value != "mixed" and not "workshop" in p.meta.projects): return "BUILD THE LANTERN WORKSHOP FIRST."
		"tier":
			if not value is int or value < 0 or value > 2 or (value == 1 and p.completed == 0) or (value == 2 and not 1 in p.meta.tiers): return "COMPLETE THE PREVIOUS CHALLENGE FIRST."
		_: return "UNKNOWN PREPARATION."
	choices[key] = value
	return ""

static func snapshot(p: Dictionary) -> Dictionary:
	var spec: Dictionary = p.preparation.duplicate(true)
	spec.growth = growth(p)
	spec.xp_multiplier = 2
	spec.relic_pool = POOLS[spec.pool].duplicate() if "workshop" in p.meta.projects else ["thorn", "shell", "hearth"]
	spec.guardian_bonus = 4 if spec.tier > 0 else 0
	spec.camp_fraction = 0.5 if spec.tier == 2 else 1
	return spec

static func goals(p: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var pin: String = p.meta.pin
	if pin in p.meta.projects:
		for id: String in PROJECTS:
			if not id in p.meta.projects: pin = id; break
	if not pin in p.meta.projects: result.append("%s: %s/%s MARKS" % [PROJECTS[pin].title, p.meta.marks, PROJECTS[pin].cost])
	for id: String in BASES:
		if not sheltered(p, id): result.append("BRING " + id.to_upper() + " HOME")
		elif p.meta.study[id].size() < 3: result.append("STUDY " + id.to_upper() + ": %s/3 WINS" % p.meta.study[id].size())
		if result.size() == 3: return result
	if result.size() < 3:
		for id: String in BASES:
			if sheltered(p, id) and not id in p.meta.medals: result.append("NORMAL CLEAR WITH " + id.to_upper())
			if result.size() == 3: return result
	if result.size() < 3 and not 2 in p.meta.tiers: result.append("COMPLETE CHALLENGE " + ("2" if 1 in p.meta.tiers else "1") if p.completed > 0 else "DEFEAT THE GUARDIAN")
	if result.is_empty(): result.append("SANCTUARY COMPLETE. TRY ANOTHER BUILD.")
	return result
