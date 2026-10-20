extends SceneTree
const Model = preload("res://scripts/expedition/expedition_service.gd")
const Session = preload("res://scripts/expedition/expedition_session.gd")
const Rules = preload("res://scripts/battle/battle_resolver.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var driver := Driver.new()
var victories: Array[int] = [0, 0]
var total_turns: int = 0
var failures: int = 0
func battle(d: Dictionary) -> void:
	var session := Session.new(); session.configure(d)
	var state: RefCounted = session.begin(d.run.pending.species, int(d.run.pending.level))
	var resolver := Rules.new(session.catalog)
	for turn in range(80):
		if not state.outcome.is_empty(): break
		var result := resolver.resolve(state, driver.command(session, state))
		if not result.valid: failures += 1; return
		total_turns += 1
	if state.outcome.is_empty(): failures += 1; return
	session.claim(state)
	if not session.apply_to(d, state): failures += 1
func _initialize() -> void:
	for starter in range(2):
		for seed_value in range(16):
			var d := Model.fresh()
			Model.depart(d, starter, seed_value)
			for stage in range(3):
				var preferred: int = 2 if starter == 0 else 0
				var route: int = 0
				for i in range(2):
					if d.run.options[stage][i].theme == preferred: route = i
				Model.choose_route(d, route)
				for slot in range(2):
					Model.prepare(d, slot); battle(d)
					if d.run.phase == "settle": break
				if d.run.phase == "settle": break
				Model.exit_stage(d)
				var offers: Array = d.run.offers
				Model.relic(d, "hearth" if "hearth" in offers else "shell" if "shell" in offers else offers[0])
				if stage == 1: Model.camp(d, "rest"); Model.camp(d, "continue")
				if stage == 2: battle(d)
			if d.run.outcome == "victory": victories[starter] += 1
			var eligible := Model.eligible(d.run)
			var source: Array = d.profile.roster.duplicate(true)
			if Model.settle(d, "" if eligible.is_empty() else eligible[0].id) != "": failures += 1
			if d.profile.roster.slice(0, 2) != source or Model.depart(d, starter) != "": failures += 1
	if victories[0] == 0 or victories[1] == 0: failures += 1
	print("M5 BALANCE PASS: seeds 0-15 x both starters; Brindlewick %s/16, Cindrel %s/16 wins; %s commands; %s failures (fixed bot, not human balance)" % [victories[0], victories[1], total_turns, failures])
	quit(1 if failures else 0)