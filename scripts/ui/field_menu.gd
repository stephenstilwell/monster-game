extends "res://scripts/ui/pixel_ui.gd"
signal closed
const Field = preload("res://scripts/core/field_service.gd")
const PAGES := ["PARTY", "STORE", "BAG", "REST", "SET", "SAVE"]
var app: Node
var page: int = 0
var selected: int = 0
var party_slot: int = 0
var mode: String = "list"
var message: String = "LEFT/RIGHT: PAGES. E/A: CHOOSE."
var textures: Dictionary = {}
var regions: Dictionary = {}

func _ready() -> void:
	super._ready()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/m4/manifest.json"))
	regions = manifest.regions
	for id: String in manifest.assets: textures[id] = load("res://assets/generated/m4/" + id + ".png")

func choices() -> Array[String]:
	var entries: Array[String] = []
	if mode == "party_actions": return ["MAKE LEAD", "SEND TO STORAGE", "BACK"]
	if mode == "load_confirm": return ["KEEP CURRENT RUN", "REPLACE WITH SAVE"]
	if mode == "balm_target":
		for m: RefCounted in app.session.party: entries.append(member_label(m))
		return entries
	match page:
		0:
			for m: RefCounted in app.session.party: entries.append(member_label(m))
		1:
			for m: RefCounted in app.session.storage: entries.append(member_label(m))
			if entries.is_empty(): entries.append("NO STORED PARTNERS")
		2: entries.assign(["CHARM X%s" % app.session.inventory.charm, "BALM X%s" % app.session.inventory.balm])
		3: entries.assign(["REST AND REPLENISH"])
		4: entries.assign(["BATTLE PACE: " + ("QUICK" if app.session.settings.text_speed else "NORMAL")])
		5: entries.assign(["SAVE CURRENT RUN", "LOAD SAVED RUN"])
	return entries

func member_label(m: RefCounted) -> String:
	return "%s L%s %s/%s" % [app.session.catalog.species[m.species_id].title, m.level, m.hp, m.max_hp(app.session.catalog.species[m.species_id])]

func _input(event: InputEvent) -> void:
	if not visible: return
	var used := true
	if event.is_action_pressed("close_dialogue", false) or event.is_action_pressed("field_menu", false):
		if mode != "list":
			selected = party_slot if mode == "party_actions" else 1
			mode = "list"
		else: closed.emit()
	elif event.is_action_pressed("walk_up", false): selected = posmod(selected - 1, choices().size())
	elif event.is_action_pressed("walk_down", false): selected = posmod(selected + 1, choices().size())
	elif event.is_action_pressed("walk_left", false) or event.is_action_pressed("walk_right", false):
		if mode == "list":
			if page == 0: party_slot = selected
			page = posmod(page + (-1 if event.is_action_pressed("walk_left", false) else 1), PAGES.size())
			selected = 0
			message = ""
	elif event.is_action_pressed("interact", false): confirm()
	else: used = false
	if used:
		get_viewport().set_input_as_handled()
		queue_redraw()

func confirm() -> void:
	if mode == "load_confirm":
		if selected == 1: message = app.load_run()
		mode = "list"; selected = 0
	elif mode == "balm_target":
		message = Field.balm(app.session, selected)
		mode = "list"; selected = 1
	elif mode == "party_actions":
		if selected == 0:
			var m: RefCounted = app.session.party[party_slot]
			app.session.party.remove_at(party_slot)
			app.session.party.push_front(m)
			party_slot = 0
			message = "PARTY ORDER UPDATED."
		elif selected == 1: message = Field.deposit(app.session, party_slot)
		party_slot = mini(party_slot, app.session.party.size() - 1)
		mode = "list"; selected = party_slot
	else:
		match page:
			0: party_slot = selected; mode = "party_actions"; selected = 0
			1:
				message = Field.withdraw(app.session, selected, party_slot)
				selected = clampi(selected, 0, maxi(0, app.session.storage.size() - 1))
			2:
				if selected == 0: message = "CHARMS ARE USED IN BATTLE."
				else: mode = "balm_target"; selected = 0
			3: message = Field.rest(app.session, app.world.current_map.id)
			4: app.session.settings.text_speed = 1 - app.session.settings.text_speed; message = "BATTLE EVENT PACE UPDATED."
			5:
				if selected == 0: message = app.save_run()
				else: mode = "load_confirm"; selected = 0
	queue_redraw()

func sprite(id: String, at: Vector2) -> void:
	var spec: Dictionary = regions[id]
	var r: Array = spec.rect
	draw_texture_rect_region(textures[spec.asset], Rect2(at, Vector2(r[2], r[3])), Rect2(r[0], r[1], r[2], r[3]))

func _draw() -> void:
	if font == null or app == null: return
	draw_rect(Rect2(0, 0, 320, 180), palette[0])
	for i in range(6):
		sprite("focused" if page == i else "disabled" if i == 3 and app.world.current_map.id != "town" else "normal", Vector2(5 + i * 52, 3))
		text(PAGES[i], 11 + i * 52, 9, 13 if page == i else 3)
	draw_style_box(panel_style, Rect2(5, 27, 310, 103))
	var entries := choices()
	selected = clampi(selected, 0, entries.size() - 1)
	var start := (selected / 4) * 4
	for i in range(start, mini(start + 4, entries.size())):
		var y := 35 + (i - start) * 22
		if selected == i: draw_rect(Rect2(10, y - 2, 188, 18), palette[4])
		text(("> " if selected == i else "  ") + entries[i], 12, y + 2, 13 if selected == i else 3)
	text("%s/%s" % [selected + 1, entries.size()], 249, 117, 9)
	if page in [0, 1] and mode == "list":
		var group: Array = app.session.party if page == 0 else app.session.storage
		if not group.is_empty():
			var m: RefCounted = group[selected]
			sprite(m.species_id, Vector2(240, 34))
			text("XP %s/%s" % [m.experience, m.level * 12], 204, 88, 9)
			text(app.session.catalog.species[m.species_id].affinity.to_upper(), 204, 101, 11)
	elif page == 2:
		if mode == "balm_target": sprite(app.session.party[selected].species_id, Vector2(240, 34))
		else: sprite("charm" if selected == 0 else "balm", Vector2(252, 51))
	elif page == 3: text("TOWN ONLY", 222, 58, 9)
	elif page == 4: text("E/A TO TOGGLE", 204, 58, 9)
	elif page == 5: text("ONE SLOT", 234, 58, 9)
	var hint := message
	if hint.is_empty():
		match page:
			0: hint = "CHOOSE A PARTNER TO REORDER OR STORE."
			1: hint = "E: WITHDRAW. FULL PARTY: SWAP SLOT %s." % (party_slot + 1)
			2: hint = "BALM HEALS 24 HP. TOWN REST REVIVES."
			3: hint = "TOWN CARE HEALS PARTY AND STORAGE."
			4: hint = "QUICK SHORTENS BATTLE EVENT DELAYS."
			5: hint = "SAVES LOCATION, PARTNERS AND SUPPLIES."
	if mode == "load_confirm": hint = "REPLACE UNSAVED PROGRESS? ESC: CANCEL."
	elif mode == "balm_target": hint = "CHOOSE A HEALTHY PARTNER FOR BALM."
	for i in range(mini(2, wrap_lines(hint, 49).size())): text(wrap_lines(hint, 49)[i], 9, 136 + i * 10, 9)
	text("L/R PAGE  UP/DOWN SELECT  E/A OK  ESC/B BACK", 9, 167, 3)
