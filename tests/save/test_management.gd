extends SceneTree
const App = preload("res://tests/fixtures/legacy_game.tscn")
const Codec = preload("res://scripts/save/save_codec.gd")
const Save = preload("res://scripts/save/save_service.gd")
const Field = preload("res://scripts/core/field_service.gd")
const Monster = preload("res://scripts/monsters/monster_state.gd")
var checks: int = 0
var failures: int = 0
var app: Node
var directory: String

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void: run.call_deferred()

func write_raw(name: String, data: Variant, checksum: bool = true) -> void:
	var payload := JSON.stringify(data)
	var file := FileAccess.open(directory + "/" + name, FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload": payload, "digest": payload.sha256_text() if checksum else "damaged"}))
	file.close()

func clear_files() -> void:
	for name: String in ["slot.json", "pending.json", "backup.json"]:
		if FileAccess.file_exists(directory + "/" + name): DirAccess.remove_absolute(directory + "/" + name)

func input_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	Input.parse_input_event(event)
	await process_frame

func input_button(code: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventJoypadButton.new()
	event.button_index = code
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	app = App.instantiate()
	root.add_child(app)
	app.world.set_physics_process(false)
	directory = "res://.godot/m4_validation/test_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	app.saves.directory = directory
	var original: Dictionary = Codec.snapshot(app)
	check(not Codec.decode(original, app.world.maps).has("error"), "fresh session valid")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(original))
	var decoded := Codec.decode(saved, app.world.maps)
	check(not decoded.has("error"), "JSON roundtrip")
	check(decoded.session.party[0].id == "starter_1", "stable identity")
	check(decoded.encounters.state == str(app.encounters.rng.state), "64-bit RNG string roundtrip")
	var migration := original.duplicate(true)
	migration.version = 1
	migration.erase("settings")
	check(Codec.decode(migration, app.world.maps).session.settings.text_speed == 0, "v1 migration")
	for bad: Variant in [null, [], "bad", {}, {"version": 3}, {"version": 0}, {"version": 2}]:
		check(Codec.decode(bad, app.world.maps).has("error"), "reject malformed root")
	for key: String in original:
		var bad := original.duplicate(true)
		bad.erase(key)
		check(Codec.decode(bad, app.world.maps).has("error"), "required " + key)
	for field: String in ["level", "xp", "hp", "id", "species", "moves", "appearance"]:
		for value: Variant in [null, {}, [], true, -1, 1.5, "invalid"]:
			var bad := original.duplicate(true)
			bad.members[0][0][field] = "" if field == "id" and value is String else value
			check(Codec.decode(bad, app.world.maps).has("error"), "reject monster " + field)
	var duplicate := original.duplicate(true)
	duplicate.members[1].append(duplicate.members[0][0].duplicate(true))
	check(Codec.decode(duplicate, app.world.maps).has("error"), "duplicate individual IDs")
	for path: String in ["inventory", "location", "encounters", "settings"]:
		for key: String in original[path]:
			var bad := original.duplicate(true)
			bad[path][key] = null
			check(Codec.decode(bad, app.world.maps).has("error"), "reject " + path + key)
	var blocked := original.duplicate(true)
	blocked.location.cell = [0, 0]
	check(Codec.decode(blocked, app.world.maps).has("error"), "blocked spawn rejected")
	var dead := original.duplicate(true)
	for member: Dictionary in dead.members[0]: member.hp = 0
	check(Codec.decode(dead, app.world.maps).has("error"), "no healthy partner rejected")
	var maximum := original.duplicate(true)
	maximum.members[0][0].level = 20
	maximum.members[0][0].xp = 1
	check(Codec.decode(maximum, app.world.maps).has("error"), "max level XP bounded")
	# Field inventory behavior preserves items on invalid requests.
	var session: RefCounted = app.session
	check(Field.balm(session, 0) == "HEALTH IS ALREADY FULL.", "full health no waste")
	check(session.inventory.balm == 6, "invalid balm preserves count")
	session.party[0].hp = 1
	check(Field.balm(session, 0) == "BALM RESTORED HEALTH." and session.party[0].hp == 25 and session.inventory.balm == 5, "field balm cost and amount")
	session.party[0].hp = 0
	check(Field.balm(session, 0) == "FAINTED PARTNERS NEED TOWN REST.", "balm cannot revive")
	check(Field.deposit(session, 1) == "KEEP A HEALTHY PARTNER.", "cannot store only healthy member")
	check(Field.deposit(session, 0) == "MOVED TO STORAGE." and session.party.size() == 1, "deposit fainted member")
	check(Field.deposit(session, 0) == "KEEP A HEALTHY PARTNER.", "last partner retained")
	check(Field.withdraw(session, 0, 0) == "JOINED THE PARTY.", "withdraw to vacancy")
	while session.party.size() < 4:
		session.party.append(Monster.create("extra_" + str(session.party.size()), session.catalog.species.rillume, 3))
	session.storage.append(Monster.create("stored", session.catalog.species.cindrel, 8))
	var replaced: String = session.party[2].id
	check(Field.withdraw(session, 0, 2) == "EXCHANGED WITH PARTY SLOT 3.", "full party exchanges")
	check(session.party.size() == 4 and session.storage.size() == 1 and session.party[2].id == "stored" and session.storage[0].id == replaced, "exchange preserves IDs and capacity")
	check(Field.withdraw(session, 0, -1) == "CHOOSE A PARTY SLOT FIRST.", "invalid exchange rejected")
	check(Field.rest(session, "forest") == "REST IS AVAILABLE IN TOWN." and session.party[1].hp == 0, "forest rest rejected")
	Field.rest(session, "town")
	for m: RefCounted in session.party + session.storage: check(m.hp == m.max_hp(session.catalog.species[m.species_id]), "town heals all including fainted and stored")
	check(session.inventory.balm == 6 and session.inventory.charm == 12, "rest restores supplies")
	session.inventory.charm = 20
	Field.rest(session, "town")
	check(session.inventory.charm == 20, "rest preserves surplus")
	# Save/load app gate and actual filesystem transactions.
	check(app.save_run() == "SAVE FROM THE FIELD MENU.", "safe save gate")
	check(app.open_menu(), "open at idle")
	check(not app.open_menu() and not app.start_battle("rillume", 3), "menu is exclusive")
	app.world._mount_map("forest", Vector2i(6, 18))
	app.world.movement.facing = Vector2i.LEFT
	app.encounters.rng.state = -8123456789123456789
	app.encounters.cooldown = 3
	app.encounters.grass_steps = 2
	session.settings.text_speed = 1
	session.battle_serial = 7
	session.claimed[7] = true
	session.party[0].experience = 9
	session.party[0].appearance_seed = -8123456789123456789
	session.party[2].id = "wild_7"
	session.storage[0].hp = 5
	var snapshot: Dictionary = Codec.snapshot(app)
	check(app.save_run() == "SAVED.", "save primary")
	session.inventory.balm = 0
	check(app.load_run() == "LOADED.", "load primary")
	check(Codec.snapshot(app) == snapshot, "all state restored including RNG location ledger settings storage")
	check(app.world.movement.locked and app.world.mode == app.world.Mode.MENU, "load retains modal lock")
	app.session.inventory.balm = 4
	check(app.save_run() == "SAVED.", "second save rotates backup")
	check(app.saves.read_file(directory + "/backup.json", app.world.maps).session.inventory.balm == 6, "known-good backup retained")
	var file := FileAccess.open(directory + "/slot.json", FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(app.load_run().begins_with("RECOVERED"), "corrupt primary recovers backup")
	check(app.session.inventory.balm == 6, "backup data restored")
	write_raw("slot.json", {})
	check(app.load_run().begins_with("RECOVERED"), "missing version treated as corruption with backup fallback")
	clear_files()
	write_raw("pending.json", snapshot)
	check(app.load_run() == "RECOVERED FROM PENDING.JSON", "interruption before install recovers pending")
	check(app.save_run() == "SAVED.", "resave preserves pending recovery")
	check(app.saves.read_file(directory + "/backup.json", app.world.maps).session.inventory.balm == 6, "pending recovery backed up before new write")
	clear_files()
	write_raw("backup.json", snapshot)
	write_raw("pending.json", snapshot, false)
	check(app.load_run() == "RECOVERED FROM BACKUP.JSON", "interrupted partial pending uses backup")
	clear_files()
	write_raw("slot.json", snapshot)
	write_raw("pending.json", original)
	check(app.load_run() == "LOADED." and app.world.current_map.id == "forest", "committed primary outranks pending")
	var future := snapshot.duplicate(true)
	future.version = 99
	write_raw("slot.json", future)
	write_raw("backup.json", snapshot)
	check(app.load_run() == "UNSUPPORTED SAVE VERSION.", "future primary never falls back")
	var unchanged: Dictionary = Codec.snapshot(app)
	check(app.save_run() == "NEWER SAVE PROTECTED.", "cannot overwrite future version")
	check(Codec.snapshot(app) == unchanged, "failed load and save preserve live state")
	clear_files()
	write_raw("pending.json", future)
	check(app.save_run() == "NEWER SAVE PROTECTED.", "future pending protected")
	clear_files()
	write_raw("slot.json", snapshot, false)
	check(app.load_run() == "SAVE CHECKSUM FAILED.", "checksum detects damage")
	check(Codec.snapshot(app) == unchanged, "damaged load transactional")
	clear_files()
	check(app.load_run() == "NO SAVE FOUND.", "empty slot handled without mutation")
	var obstruction := directory + "/not_a_directory"
	file = FileAccess.open(obstruction, FileAccess.WRITE)
	file.store_string("obstruction")
	file.close()
	app.saves.directory = obstruction
	check(app.save_run() in ["CANNOT CREATE SAVE DIRECTORY.", "CANNOT WRITE SAVE."], "I/O failure reported without mutation")
	check(Codec.snapshot(app) == unchanged, "I/O failure preserves session")
	app.saves.directory = directory
	var old_state := preload("res://scripts/battle/battle_state.gd").new()
	old_state.id = 7
	old_state.outcome = "victory"
	check(app.session.claim(old_state).is_empty(), "loaded claim ledger prevents duplicate rewards")
	app.close_menu()
	check(app.world.mode == app.world.Mode.EXPLORE and not app.world.movement.locked and app.world.require_neutral, "close restores world with neutral guard")
	await process_frame
	app.world.set_physics_process(false)
	await input_key(KEY_TAB)
	check(app.field_menu != null, "keyboard opens menu")
	for i in range(6):
		check(app.field_menu.page == i, "keyboard page " + str(i))
		await input_key(KEY_RIGHT)
	check(app.field_menu.page == 0, "tabs wrap")
	await input_key(KEY_DOWN)
	await input_key(KEY_RIGHT)
	check(app.field_menu.party_slot == 1, "highlighted party slot becomes exchange target")
	await input_key(KEY_LEFT)
	await input_key(KEY_E)
	check(app.field_menu.mode == "party_actions", "party action submenu")
	await input_key(KEY_ESCAPE)
	check(app.field_menu.mode == "list", "back from submenu")
	await input_key(KEY_ESCAPE)
	check(app.field_menu == null, "keyboard closes")
	await input_button(JOY_BUTTON_START)
	check(app.field_menu != null, "gamepad opens")
	for i in range(6):
		for step in range(i): await input_button(JOY_BUTTON_DPAD_RIGHT)
		check(app.field_menu.page == i, "gamepad page " + str(i))
		await input_button(JOY_BUTTON_DPAD_DOWN)
		await input_button(JOY_BUTTON_B)
		check(app.field_menu == null, "gamepad exit page " + str(i))
		await input_button(JOY_BUTTON_START)
	await input_button(JOY_BUTTON_DPAD_RIGHT)
	for i in range(6): app.session.storage.append(Monster.create("page_" + str(i), app.session.catalog.species.rillume, 3))
	for i in range(5): await input_button(JOY_BUTTON_DPAD_DOWN)
	check(app.field_menu.selected == 5, "gamepad reaches second storage page")
	await input_button(JOY_BUTTON_B)
	await input_button(JOY_BUTTON_START)
	await input_button(JOY_BUTTON_DPAD_RIGHT)
	await input_button(JOY_BUTTON_DPAD_RIGHT)
	await input_button(JOY_BUTTON_DPAD_DOWN)
	await input_button(JOY_BUTTON_A)
	check(app.field_menu.mode == "balm_target", "gamepad balm target focus")
	await input_button(JOY_BUTTON_B)
	check(app.field_menu.mode == "list", "cancel target without spending")
	await input_button(JOY_BUTTON_DPAD_RIGHT)
	await input_button(JOY_BUTTON_DPAD_RIGHT)
	await input_button(JOY_BUTTON_DPAD_RIGHT)
	await input_button(JOY_BUTTON_DPAD_DOWN)
	await input_button(JOY_BUTTON_A)
	check(app.field_menu.mode == "load_confirm" and app.field_menu.selected == 0, "gamepad load defaults to safe cancellation")
	await input_button(JOY_BUTTON_B)
	await input_button(JOY_BUTTON_B)
	await input_button(JOY_BUTTON_START)
	await input_button(JOY_BUTTON_A)
	check(app.field_menu.mode == "party_actions", "gamepad confirm")
	await input_button(JOY_BUTTON_B)
	await input_button(JOY_BUTTON_B)
	check(app.field_menu == null, "gamepad back out nested focus")
	app.world.set_physics_process(false)
	app.world.movement.moving = true
	check(not app.open_menu(), "mid-step menu rejected")
	app.world.movement.moving = false
	app.world.mode = app.world.Mode.DIALOGUE
	check(not app.open_menu(), "dialogue menu rejected")
	app.world.mode = app.world.Mode.TRANSITION
	check(not app.open_menu(), "transition menu rejected")
	app.world.mode = app.world.Mode.EXPLORE
	check(app.start_battle("rillume", 3), "battle works after loaded session")
	check(not app.open_menu(), "battle menu rejected")
	check(app.battle.state.id == 8, "battle serial persists")
	app.battle.set_process(false)
	app.battle.command_phase()
	app.battle.submit({"kind": "move", "move": app.battle.state.party[app.battle.state.active].moves[0]})
	app.battle.advance(0.26)
	check(app.battle.event_clock == 0.0, "loaded quick pace advances battle events")
	app.session.settings.text_speed = 0
	app.battle.advance(0.26)
	check(app.battle.event_clock > 0.25, "normal pace holds event longer")
	clear_files()
	app.queue_free()
	await process_frame
	print("M4 SYSTEM PASS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)
