extends "res://scripts/ui/pixel_ui.gd"
var world: Node2D
var show_menu_hint: bool = false
var status_text: String = ""
var health_text: String = ""
var status_relics: Array = []
var relic_texture: Texture2D
func _draw() -> void:
	if font == null or world == null or world.current_map == null:
		return
	draw_rect(Rect2(0, 0, 320, 18), palette[0])
	text("LANTERNWILD / " + world.current_map.title, 6, 5, 13)
	if world.dialogue.active:
		draw_style_box(panel_style, Rect2(5, 119, 310, 59))
		text(world.dialogue.speaker, 13, 126, 13)
		var lines: Array[String] = wrap_lines(world.dialogue.current_text())
		assert(lines.size() <= 2, "Dialogue page exceeds two lines")
		for index in range(lines.size()):
			text(lines[index], 13, 138 + index * 10)
		text("E NEXT  ESC CLOSE", 13, 167, 9)
		text("%s/%s" % [world.dialogue.index + 1, world.dialogue.pages.size()], 282, 167, 9)
	else:
		draw_rect(Rect2(0, 165, 320, 15), palette[0])
		if show_menu_hint: text("TAB/M MENU", 246, 5, 9)
		var target: Dictionary = world.current_map.interaction_at(world.movement.cell + world.movement.facing)
		text("ARROWS/WASD WALK  E " + ("TALK" if target.has("id") and target.id in ["mara", "ivo"] else "READ" if not target.is_empty() else "INTERACT"), 6, 170, 9)
	if world.mode == world.Mode.TRANSITION:
		var fade: float = clampf(1.0 - absf(world.transition_elapsed - 0.14) / 0.14, 0.0, 1.0)
		draw_rect(Rect2(0, 0, 320, 180), Color(palette[0], fade))
	if not status_text.is_empty() and not world.dialogue.active:
		draw_rect(Rect2(0, 152, 320, 13), palette[0])
		text(status_text, 6, 155, 13)
	if not health_text.is_empty() and not world.dialogue.active:
		draw_rect(Rect2(0, 138, 320, 14), palette[0])
		text(health_text, 6, 142, 9)
		if not status_relics.is_empty():
			if relic_texture == null: relic_texture = load("res://assets/generated/m5/relics.png")
			for i in range(status_relics.size()):
				var index: int = ["thorn", "shell", "hearth"].find(status_relics[i])
				draw_texture_rect_region(relic_texture, Rect2(265 + i * 16, 138, 14, 14), Rect2(index * 24, 0, 24, 24))
