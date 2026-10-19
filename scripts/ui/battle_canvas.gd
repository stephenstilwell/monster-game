extends "res://scripts/ui/pixel_ui.gd"
var battle: Node
var frames: Dictionary = {}
var arena: Texture2D
var icons: Texture2D
func _ready() -> void:
	super._ready()
	arena = load("res://assets/generated/m3/arena.png")
	icons = load("res://assets/generated/m3/icons.png")
	for id in ["brindlewick", "cindrel", "rillume", "effects"]:
		frames[id] = load("res://assets/generated/m3/" + id + "_frames.tres")

func animation(group: String, name: String, position: Vector2) -> void:
	var resource: SpriteFrames = frames[group]
	var index: int = int(battle.clock * resource.get_animation_speed(name)) % resource.get_frame_count(name)
	if name.ends_with("react"): index = mini(int(battle.event_clock * 10), 3)
	if group == "effects": index = mini(int(battle.event_clock * resource.get_animation_speed(name)), 3)
	draw_texture(resource.get_frame_texture(name, index), position)

func health(x: int, y: int, hp: int, maximum: int, width: int) -> void:
	draw_rect(Rect2(x, y, width, 5), palette[0])
	draw_rect(Rect2(x + 1, y + 1, width - 2, 3), palette[4])
	var amount: int = floori(float(hp) / maximum * (width - 2))
	draw_rect(Rect2(x + 1, y + 1, amount, 3), palette[6 if hp > maximum / 3 else 12])
	if amount > 0: draw_rect(Rect2(x + 1, y + 1, amount, 1), palette[3])

func _draw() -> void:
	if battle == null or font == null: return
	var state: RefCounted = battle.state
	var catalog: RefCounted = battle.session.catalog
	var enemy: RefCounted = state.enemy
	var ally: RefCounted = state.party[battle.display_active]
	var a: Resource = catalog.species[ally.species_id]
	var e: Resource = catalog.species[enemy.species_id]
	draw_rect(Rect2(0, 0, 320, 180), palette[0])
	draw_texture(arena, Vector2(0, 18))
	text("FERNGLASS / WILD ENCOUNTER", 6, 5, 13)
	var foe_hit: bool = battle.event.get("kind", "") == "hit" and battle.event.get("side", "") == "ally" and battle.event_clock < 0.4
	var ally_hit: bool = battle.event.get("kind", "") == "hit" and battle.event.get("side", "") == "foe" and battle.event_clock < 0.4
	animation(enemy.species_id, enemy.species_id + "_front_" + ("react" if foe_hit else "idle"), Vector2(234, 28))
	animation(ally.species_id, ally.species_id + "_back_" + ("react" if ally_hit else "idle"), Vector2(41, 71))
	if battle.event.has("effect") and battle.event_clock < 0.5:
		animation("effects", battle.event.effect, Vector2(234, 56) if battle.event.get("side", "ally") == "ally" and battle.event.kind != "heal" else Vector2(41, 98))
	draw_style_box(panel_style, Rect2(5, 24, 156, 37))
	text("%s LV %s" % [e.title, enemy.level], 13, 31, 13)
	text(e.affinity.to_upper(), 13, 46, 6)
	health(69, 48, battle.display_enemy_hp, enemy.max_hp(e), 83)
	draw_style_box(panel_style, Rect2(150, 80, 165, 37))
	text("%s LV %s" % [a.title, ally.level], 158, 87)
	text("HP %s/%s" % [battle.display_hp[battle.display_active], ally.max_hp(a)], 158, 102, 6)
	health(222, 104, battle.display_hp[battle.display_active], ally.max_hp(a), 84)
	draw_style_box(panel_style, Rect2(5, 127, 310, 41))
	if battle.phase == battle.Phase.COMMAND:
		var options: Array[String] = battle.choices()
		var root_menu: bool = battle.menu == "root"
		if root_menu:
			var lines := wrap_lines(battle.message, 22)
			for index in range(mini(lines.size(), 2)): text(lines[index], 13, 134 + index * 11, 9)
			draw_rect(Rect2(153, 133, 1, 29), palette[9])
		else:
			draw_rect(Rect2(0, 116, 320, 11), palette[0])
			var hint: String = "CHOOSE " + battle.menu.to_upper() + " / ESC BACK"
			if battle.menu == "moves":
				var move: Resource = catalog.moves[state.party[state.active].moves[battle.selected]]
				hint = "%s / %s / POWER %s" % [move.title, move.affinity.to_upper(), move.power]
			text(battle.message if battle.message != "WHAT WILL YOU DO?" else hint, 6, 118, 9)
		for index in range(options.size()):
			var x: int = (166 if root_menu else 16) + index % 2 * (73 if root_menu else 150)
			var y: int = 134 + index / 2 * 15
			if index == battle.selected: text(">", x - 9, y, 13)
			if battle.menu in ["party", "bag"] and options[index] != "BACK":
				var icon_index: int = ["brindlewick", "cindrel", "rillume"].find(state.party[index].species_id) if battle.menu == "party" else 3 + index
				draw_texture_rect_region(icons, Rect2(x, y - 2, 16, 16), Rect2(icon_index * 16, 0, 16, 16))
				x += 18
			text(options[index], x, y, 13 if index == battle.selected else 3)
	else:
		var lines := wrap_lines(battle.message)
		assert(lines.size() <= 3, "Battle message overflow")
		for index in range(lines.size()): text(lines[index], 13, 132 + index * 10, 13 if battle.phase == battle.Phase.RESULT else 3)
	text("E RETURN TO TRAIL" if battle.phase == battle.Phase.RESULT else "ARROWS CHOOSE  E CONFIRM  ESC BACK", 6, 172, 9)
