extends RefCounted
const Model = preload("res://scripts/progression/expedition_service.gd")
const Meta = preload("res://scripts/progression/meta_service.gd")
const Session = preload("res://scripts/progression/expedition_session.gd")
const Resolver = preload("res://scripts/battle/battle_resolver.gd")
const Driver = preload("res://tests/expedition/play_driver.gd")
var commands: int = 0
var captures: int = 0
var outcomes: Array = []
var stage_snapshots: Array = []
var error: String = ""
func battle(d: Dictionary, catch_new: bool = true) -> void:
	var session := Session.new()
	session.configure(d)
	var state := session.begin(d.run.pending.species, int(d.run.pending.level))
	var resolver := Resolver.new(session.catalog)
	var driver := Driver.new()
	for turn in range(100):
		if not state.outcome.is_empty(): break
		var command := driver.command(session, state, catch_new)
		if command.get("move", "") == "nudge" and not "nudge" in state.party[state.active].moves: command.move = state.party[state.active].moves[0]
		var result := resolver.resolve(state, command)
		if not result.valid: error = result.message; return
		commands += 1
	if state.outcome.is_empty(): error = "TIMEOUT"; return
	session.claim(state)
	if not session.apply_to(d, state): error = "STALE APPLY"; return
	if state.outcome == "capture": captures += 1
	outcomes.append(state.outcome)
func run(d: Dictionary, retreat: bool = false, event_choice: String = "sip") -> void:
	for stage in range(3):
		var route := 0
		var source: String = d.run.source_species
		var preferred: int = {"brindlewick": 2, "cindrel": 0, "rillume": 1}[source]
		for i in range(2):
			if d.run.options[stage][i].theme == preferred: route = i
		Model.choose_route(d, route)
		if not Model.trail_event(d, event_choice).is_empty(): Model.trail_event(d, "gather")
		for slot in range(2):
			Model.prepare(d, slot)
			battle(d)
			stage_snapshots.append(d.duplicate(true))
			if not error.is_empty() or d.run.phase == "settle": return
		Model.exit_stage(d)
		var offers: Array = d.run.offers
		Model.relic(d, "hearth" if "hearth" in offers else "shell" if "shell" in offers else offers[0])
		stage_snapshots.append(d.duplicate(true))
		if stage == 1:
			if retreat: Model.request_end(d, "retreat"); return
			Model.camp(d, "rest")
			Model.camp(d, "continue")
		if stage == 2: battle(d)
