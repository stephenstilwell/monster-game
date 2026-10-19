extends RefCounted

static func install() -> void:
	var keys := {"field_menu": [KEY_TAB, KEY_M], "walk_up": [KEY_UP, KEY_W], "walk_down": [KEY_DOWN, KEY_S], "walk_left": [KEY_LEFT, KEY_A], "walk_right": [KEY_RIGHT, KEY_D], "interact": [KEY_E, KEY_Z, KEY_ENTER, KEY_SPACE], "close_dialogue": [KEY_ESCAPE, KEY_X]}
	for action: String in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.35)
		for code: Key in keys[action]:
			var event := InputEventKey.new()
			event.keycode = code
			InputMap.action_add_event(action, event)
	var buttons := {"field_menu": JOY_BUTTON_START, "walk_up": JOY_BUTTON_DPAD_UP, "walk_down": JOY_BUTTON_DPAD_DOWN, "walk_left": JOY_BUTTON_DPAD_LEFT, "walk_right": JOY_BUTTON_DPAD_RIGHT, "interact": JOY_BUTTON_A, "close_dialogue": JOY_BUTTON_B}
	for action: String in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
	for spec: Array in [["walk_left", JOY_AXIS_LEFT_X, -1.0], ["walk_right", JOY_AXIS_LEFT_X, 1.0], ["walk_up", JOY_AXIS_LEFT_Y, -1.0], ["walk_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = spec[1]
		event.axis_value = spec[2]
		if not InputMap.action_has_event(spec[0], event):
			InputMap.action_add_event(spec[0], event)

static func direction(vector: Vector2) -> Vector2i:
	if vector.length() < 0.35:
		return Vector2i.ZERO
	if absf(vector.x) > absf(vector.y):
		return Vector2i(int(signf(vector.x)), 0)
	return Vector2i(0, int(signf(vector.y)))

static func held_direction() -> Vector2i:
	return direction(Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down", 0.0))
