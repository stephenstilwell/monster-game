extends Node
signal closed(state: RefCounted)
const Rules = preload("res://scripts/battle/battle_resolver.gd")
const Bindings = preload("res://scripts/world/exploration_input.gd")
enum Phase { ENTRY, COMMAND, PRESENT, RESULT, CLOSED }
var state: RefCounted
var session: RefCounted
var rules: RefCounted
var phase: Phase = Phase.ENTRY
var menu: String = "root"
var selected: int = 0
var message: String = ""
var result_text: String = ""
var events: Array = []
var event_clock: float = 0.0
var clock: float = 0.0
var event: Dictionary = {}
var display_active: int = 0
var display_hp: Array[int] = []
var display_enemy_hp: int = 1
@onready var view: Node2D = $Canvas/View

func configure(battle_state: RefCounted, run_session: RefCounted) -> void:
	state = battle_state
	session = run_session
	rules = Rules.new(session.catalog)
	display_active = state.active
	for monster: RefCounted in state.party: display_hp.append(monster.hp)
	display_enemy_hp = state.enemy.hp
	message = "THE FERN GUARDIAN AWAKENS!" if state.guardian else "WILD %s APPEARED!" % session.catalog.species[state.enemy.species_id].title

func _ready() -> void:
	Bindings.install()
	view.battle = self

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	clock += delta
	event_clock += delta
	if phase == Phase.ENTRY and event_clock >= 0.35:
		command_phase()
	elif phase == Phase.PRESENT and event_clock >= (0.25 if session.settings.text_speed == 1 else 0.55):
		next_event()
	view.queue_redraw()

func choices() -> Array[String]:
	var result: Array[String] = []
	match menu:
		"root": result.assign(["MOVES", "BAG", "PARTY", "LEAVE"])
		"moves":
			for id: String in state.party[state.active].moves: result.append(session.catalog.moves[id].title)
		"bag": result.assign(["CHARM X%s" % state.inventory.charm, "BALM X%s" % state.inventory.balm, "BACK"])
		"party":
			for monster: RefCounted in state.party:
				result.append("%s %s/%s" % [session.catalog.species[monster.species_id].title, monster.hp, monster.max_hp(session.catalog.species[monster.species_id])])
	return result

func _unhandled_input(input: InputEvent) -> void:
	for action in ["interact", "close_dialogue", "walk_up", "walk_down", "walk_left", "walk_right"]:
		if input.is_action_pressed(action, false): get_viewport().set_input_as_handled()
	if input.is_action_pressed("interact", false):
		confirm()
	elif input.is_action_pressed("close_dialogue", false):
		if phase == Phase.COMMAND and state.party[state.active].hp > 0:
			menu = "root"; selected = 0; message = "WHAT WILL YOU DO?"
	elif phase == Phase.COMMAND:
		var stride := 0
		if input.is_action_pressed("walk_left", false): stride = -1
		elif input.is_action_pressed("walk_right", false): stride = 1
		elif input.is_action_pressed("walk_up", false): stride = -2
		elif input.is_action_pressed("walk_down", false): stride = 2
		if stride != 0: selected = posmod(selected + stride, choices().size())
	view.queue_redraw()

func confirm() -> void:
	match phase:
		Phase.ENTRY: command_phase()
		Phase.PRESENT:
			if event_clock > 0.08: next_event()
		Phase.RESULT:
			phase = Phase.CLOSED
			closed.emit(state)
		Phase.COMMAND:
			match menu:
				"root":
					if selected == 3: submit({"kind": "flee"})
					else:
						menu = ["moves", "bag", "party"][selected]
						selected = 0
				"moves": submit({"kind": "move", "move": state.party[state.active].moves[selected]})
				"bag":
					if selected == 2: menu = "root"; selected = 0; message = "WHAT WILL YOU DO?"
					else: submit({"kind": "item", "item": "charm" if selected == 0 else "balm"})
				"party": submit({"kind": "switch", "index": selected})

func submit(command: Dictionary) -> bool:
	if phase != Phase.COMMAND: return false
	var result: Dictionary = rules.resolve(state, command)
	if not result.valid:
		message = result.message
		return false
	events = result.events.duplicate()
	phase = Phase.PRESENT
	next_event()
	return true

func next_event() -> void:
	event_clock = 0.0
	if events.is_empty():
		event = {}
		if state.outcome.is_empty(): command_phase()
		else: finish_result()
		return
	event = events.pop_front()
	message = event.message
	if event.kind == "switch": display_active = event.index
	elif event.kind == "heal": display_hp[event.index] = event.hp
	elif event.kind == "hit":
		if event.side == "ally": display_enemy_hp = event.hp
		else: display_hp[event.index] = event.hp

func command_phase() -> void:
	phase = Phase.COMMAND
	menu = "party" if state.party[state.active].hp <= 0 else "root"
	selected = 0
	message = "CHOOSE A HEALTHY COMPANION." if menu == "party" else "WHAT WILL YOU DO?"

func finish_result() -> void:
	var reward: Dictionary = session.claim(state)
	phase = Phase.RESULT
	if reward.is_empty(): return
	match state.outcome:
		"capture": result_text = "CAUGHT %s! %s" % [session.catalog.species[state.enemy.species_id].title, reward.placement]
		"victory": result_text = "THE WILD COMPANION WITHDREW."
		"flee": result_text = "YOU RETURNED TO THE TRAIL SAFELY."
		"defeat": result_text = "BACK TO LANTERN REST. YOUR TEAM RESTED."
	if reward.xp > 0: result_text += " GAINED %s XP." % reward.xp
	if reward.levels > 0: result_text += " LEVEL UP!"
	if session.get("expedition") == true:
		if state.outcome == "defeat": result_text = "THE EXPEDITION ENDS. YOUR SANCTUARY IS SAFE."
		elif state.guardian: result_text = "THE GUARDIAN BOWS. RETURN WITH ONE RECRUIT."
		if reward.get("field_heal", 0) > 0:
			result_text += " HEARTH HEALED YOUR TEAM."
			for i in range(session.party.size()):
				if i < display_hp.size(): display_hp[i] = session.party[i].hp
	message = result_text
