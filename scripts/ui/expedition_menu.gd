extends "res://scripts/ui/pixel_ui.gd"
const Model = preload("res://scripts/expedition/expedition_service.gd")
const Routes = preload("res://scripts/expedition/route_generator.gd")
var app: Node
var screen: String = "hub"
var selected: int = 0
var member_index: int = 0
var reserve_index: int = 0
var previous: String = "field"
var release_source: String = "party"
var message: String = ""
var art: Dictionary = {}
var regions: Dictionary = {}
var portraits: Texture2D

func _ready() -> void:
	super._ready()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/m5/manifest.json"))
	regions = manifest.regions
	for id: String in manifest.assets: art[id] = load("res://assets/generated/m5/" + id + ".png")
	portraits = load("res://assets/generated/m4/portraits.png")

func root_screen() -> String:
	return "hub" if app.data.run.is_empty() or app.awaiting_continue else "camp" if app.data.run.phase == "camp" else "field"

func label(m: Dictionary) -> String:
	return "%s L%s %s/%s" % [m.species.to_upper(), m.level, m.hp, Model.monster(m).max_hp(Model.Catalog.new().species[m.species])]

func choices() -> Array[String]:
	var entries: Array[String] = []
	var d: Dictionary = app.data
	var r: Dictionary = d.run
	match screen:
		"hub": return ["CONTINUE EXPEDITION" if not r.is_empty() else "START EXPEDITION", "SANCTUARY", "DISCOVERY JOURNAL", "SETTINGS"]
		"starter", "sanctuary":
			for m: Dictionary in d.profile.roster: entries.append(m.species.to_upper())
		"route":
			for option: Dictionary in r.options[int(r.stage)]: entries.append(Routes.THEMES[int(option.theme)] + " / " + ["FERN ROAD", "RIDGE TURN", "RIVER BRIDGE"][int(option.template)])
		"reward":
			for id: String in r.offers: entries.append(Model.RELICS[id].title)
		"field": return ["PARTY", "USE BALM", "CAMP RESERVE", "RELICS", "DISCOVERY JOURNAL", "SETTINGS", "CHECKPOINT", "ABANDON EXPEDITION"]
		"party", "balm", "reserve_target":
			for m: Dictionary in r.party: entries.append(label(m))
		"member": return ["MAKE LEAD", "USE BALM", "MOVE TO RESERVE", "RELEASE AT CAMP", "BACK"]
		"reserve":
			for m: Dictionary in r.reserve: entries.append(label(m))
			if entries.is_empty(): entries.append("NO RESERVE PARTNERS")
		"reserve_member": return ["WITHDRAW / EXCHANGE", "RELEASE AT CAMP", "BACK"]
		"release": return ["KEEP COMPANION", "RELEASE TO THE WILD"]
		"camp": return ["REST SPENT" if r.camp_used else "REST TEAM ONCE", "PARTY", "CAMP RESERVE", "CONTINUE TO STAGE 3", "RETREAT WITH A RECRUIT", "TRAIL JOURNAL"]
		"journal":
			for id: String in Routes.SPECIES: entries.append(id.to_upper() + (" / FOUND" if id in d.profile.discovered else " / NOT CAPTURED"))
		"relics":
			for id: String in r.relics: entries.append(Model.RELICS[id].title)
			if entries.is_empty(): entries.append("NO RELICS YET")
		"settings": return ["BATTLE PACE: " + ("QUICK" if d.profile.settings.text_speed else "NORMAL")]
		"abandon": return ["KEEP EXPLORING", "ABANDON THIS EXPEDITION"]
		"settle":
			entries.append("RETURN WITHOUT A RECRUIT")
			for m: Dictionary in Model.eligible(r): entries.append(m.species.to_upper() + " / BRING HOME")
		"result": return ["BACK TO SANCTUARY"]
	return entries

func go(next: String) -> void:
	screen = next
	selected = 0
	message = ""
	queue_redraw()

func back() -> void:
	if screen in ["hub", "field", "camp"]: app.close_menu()
	elif screen == "member": go("party"); selected = member_index
	elif screen == "reserve_target": go("reserve_member")
	elif screen == "reserve_member": go("reserve"); selected = reserve_index
	elif screen == "release": go("member" if release_source == "party" else "reserve_member")
	elif screen == "abandon": go(previous)
	elif screen in ["route", "reward"]: previous = screen; go("abandon")
	elif screen == "settle": message = "CHOOSE A RECRUIT OR RETURN WITHOUT ONE."
	elif screen == "result": app.close_menu()
	else: go(root_screen())

func _input(event: InputEvent) -> void:
	if not visible: return
	var used := true
	if event.is_action_pressed("walk_up", false): selected = posmod(selected - 1, choices().size())
	elif event.is_action_pressed("walk_down", false): selected = posmod(selected + 1, choices().size())
	elif event.is_action_pressed("interact", false): confirm()
	elif event.is_action_pressed("close_dialogue", false) or event.is_action_pressed("field_menu", false): back()
	else: used = false
	if used: get_viewport().set_input_as_handled(); queue_redraw()

func execute(action: String, args: Dictionary = {}, render: bool = false) -> bool:
	if not app.perform(action, args): message = app.last_error; return false
	message = app.last_error
	if render: app.render_state()
	return true

func confirm() -> void:
	match screen:
		"hub":
			match selected:
				0:
					if app.data.run.is_empty(): go("starter")
					elif not app.continue_run(): message = app.last_error
				1: go("sanctuary")
				2: go("journal")
				3: go("settings")
		"starter": execute("depart", {"index": selected}, true)
		"sanctuary": message = "SAFE AT HOME. START A RUN TO CHOOSE ONE."
		"route": execute("route", {"index": selected}, true)
		"reward": execute("relic", {"id": app.data.run.offers[selected]}, true)
		"field":
			if selected <= 5: go(["party", "balm", "reserve", "relics", "journal", "settings"][selected])
			elif selected == 6: execute("checkpoint")
			else: previous = "field"; go("abandon")
		"party": member_index = selected; go("member")
		"member":
			if selected == 4: back()
			elif selected == 3: release_source = "party"; go("release")
			elif execute(["lead", "balm", "deposit"][selected], {"index": member_index}): go("party")
		"balm": execute("balm", {"index": selected})
		"reserve":
			if app.data.run.phase != "camp": message = "RESERVE EXCHANGES ARE CAMP ONLY."
			elif not app.data.run.reserve.is_empty(): reserve_index = selected; go("reserve_member")
		"reserve_member":
			if selected == 0: go("reserve_target")
			elif selected == 1: release_source = "reserve"; go("release")
			else: back()
		"release":
			if selected == 0: back()
			elif execute("release_" + release_source, {"index": member_index if release_source == "party" else reserve_index}): go(release_source)
		"reserve_target":
			if execute("withdraw", {"index": reserve_index, "target": selected}): go("reserve")
		"camp":
			match selected:
				0: execute("camp", {"action": "rest"})
				1: go("party")
				2: go("reserve")
				3: execute("camp", {"action": "continue"}, true)
				4: execute("end", {"outcome": "retreat"}, true)
				5: go("field")
		"settings": execute("settings")
		"abandon":
			if selected == 0: go(previous)
			else: execute("end", {"outcome": "abandon"}, true)
		"settle":
			var id: String = "" if selected == 0 else Model.eligible(app.data.run)[selected - 1].id
			if execute("settle", {"id": id}): app.mount_hub(); app.lock_world(); go("result")
		"result": app.close_menu()
	queue_redraw()

func sprite(id: String, at: Vector2) -> void:
	var spec: Dictionary = regions[id]
	var r: Array = spec.rect
	draw_texture_rect_region(art[spec.asset], Rect2(at, Vector2(r[2], r[3])), Rect2(r[0], r[1], r[2], r[3]))

func portrait(species: String) -> void:
	var i: int = Routes.SPECIES.find(species)
	draw_texture_rect_region(portraits, Rect2(250, 43, 48, 48), Rect2(i * 48, 0, 48, 48))

func _draw() -> void:
	if app == null or font == null: return
	draw_texture(art.journal, Vector2.ZERO)
	var titles := {"settle": "EXPEDITION RETURN", "field": "TRAIL JOURNAL", "reserve_target": "CAMP EXCHANGE", "result": "HOMEWARD", "starter": "CHOOSE PARTNER", "hub": "SANCTUARY", "journal": "DISCOVERIES"}
	text("LANTERNWILD / " + titles.get(screen, screen.to_upper()), 13, 13, 13)
	draw_style_box(panel_style, Rect2(9, 28, 302, 101))
	var entries := choices()
	selected = clampi(selected, 0, entries.size() - 1)
	var start := selected / 4 * 4
	for i in range(start, mini(start + 4, entries.size())):
		var y := 38 + (i - start) * 21
		if i == selected: draw_rect(Rect2(13, y - 3, 230, 17), palette[4])
		text(("> " if i == selected else "  ") + entries[i], 16, y, 13 if i == selected else 3)
	text("%s/%s" % [selected + 1, entries.size()], 260, 115, 9)
	var d: Dictionary = app.data
	var r: Dictionary = d.run
	var hint := message
	if screen in ["starter", "sanctuary"]:
		portrait(d.profile.roster[selected].species)
		if hint.is_empty(): hint = "ONE PARTNER. LEVEL 5. FOUR CHARMS, TWO BALMS."
	elif screen in ["party", "balm", "reserve_target"]:
		portrait(r.party[selected].species)
		if hint.is_empty(): hint = "E/A: EXCHANGE WITH THIS PARTY SLOT." if screen == "reserve_target" else "BALM HEALS 24. FAINTED PARTNERS NEED CAMP."
	elif screen == "reserve":
		if not r.reserve.is_empty(): portrait(r.reserve[selected].species)
		if hint.is_empty(): hint = "FOUR CAMP RESERVE SLOTS. CHOOSE TO WITHDRAW."
	elif screen in ["reward", "relics"]:
		var list: Array = r.offers if screen == "reward" else r.relics
		if not list.is_empty():
			sprite(list[selected], Vector2(264, 55))
			if hint.is_empty(): hint = Model.RELICS[list[selected]].detail
	elif screen == "release":
		var group: Array = r.party if release_source == "party" else r.reserve
		var individual: Dictionary = group[member_index if release_source == "party" else reserve_index]
		portrait(individual.species)
		if hint.is_empty(): hint = "RELEASE %s FROM THIS RUN. JOURNAL STAYS." % individual.species.to_upper()
	elif screen == "camp":
		sprite("m5_camp", Vector2(250, 43))
		if hint.is_empty(): hint = "REST SPENT. NO REFILLS. CONTINUE OR RETREAT." if r.camp_used else "ONE TEAM REST. NO ITEM REFILLS. EXCHANGE HERE."
	elif screen == "route":
		sprite("m5_gate", Vector2(250, 43))
		if hint.is_empty(): hint = "STAGE %s/3. TWO MARKED LIGHTS, THEN THE GATE." % (int(r.stage) + 1)
	elif screen == "journal":
		portrait(Routes.SPECIES[selected])
		if hint.is_empty(): hint = "CAPTURE DISCOVERIES SURVIVE EVERY OUTCOME."
	elif screen == "settle":
		if selected > 0: portrait(Model.eligible(r)[selected - 1].species)
		else: sprite(r.outcome, Vector2(258, 48))
		if hint.is_empty(): hint = r.outcome.to_upper() + ": ONE LIVING RECRUIT OR NONE. LEVELS RESET." if r.outcome in ["victory", "retreat"] else r.outcome.to_upper() + ": NO RECRUITS. SANCTUARY AND JOURNAL ARE SAFE."
	elif screen == "result":
		sprite(d.profile.last.outcome, Vector2(258, 48))
		if hint.is_empty(): hint = d.profile.last.outcome.to_upper() + ". " + ("NO RECRUIT ADMITTED." if d.profile.last.recruit == "" else d.profile.last.recruit.to_upper() + " JOINED YOUR SANCTUARY.")
	if hint.is_empty():
		match screen:
			"abandon": hint = "LOSE THIS TEAM AND SUPPLIES. KEEP YOUR JOURNAL."
			"hub": hint = "SANCTUARY %s / CLEARS %s. EAST GATE DEPARTS." % [d.profile.roster.size(), d.profile.completed]
			"field": hint = "TEMPORARY TEAM. RESERVE EXCHANGES AT CAMP."
			"member": hint = "KEEP ONE HEALTHY PARTNER. RESERVE IS CAMP ONLY."
			"release": hint = "RELEASE THIS RUN CAPTURE. KEEP YOUR DISCOVERY."
			"reserve_member": hint = "WITHDRAW TO A VACANCY OR EXCHANGE A PARTY SLOT."
			"settings": hint = "NORMAL / QUICK BATTLE EVENT DELAYS."
	var lines := wrap_lines(hint, 48)
	for i in range(mini(2, lines.size())): text(lines[i], 15, 136 + i * 10, 9)
	text("UP/DOWN CHOOSE  E/A CONFIRM  ESC/B BACK", 15, 163, 3)