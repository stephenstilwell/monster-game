extends "res://scripts/ui/pixel_ui.gd"
var world: Node2D
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
		var target: Dictionary = world.current_map.interaction_at(world.movement.cell + world.movement.facing)
		text("ARROWS/WASD WALK  E " + ("TALK" if target.has("id") and target.id in ["mara", "ivo"] else "READ" if not target.is_empty() else "INTERACT"), 6, 170, 9)
	if world.mode == world.Mode.TRANSITION:
		var fade: float = clampf(1.0 - absf(world.transition_elapsed - 0.14) / 0.14, 0.0, 1.0)
		draw_rect(Rect2(0, 0, 320, 180), Color(palette[0], fade))
