extends Node2D
var font: Font
var panel_style: StyleBox
var palette: Array[Color] = []
var glyphs: String = ""

func _ready() -> void:
	var theme: Theme = load("res://assets/generated/woodland_theme.tres")
	font = theme.default_font
	panel_style = theme.get_stylebox("panel", "Panel")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	glyphs = manifest.glyphs
	for hex: String in manifest.palette:
		palette.append(Color.html(hex))

func text(value: String, x: int, y: int, color: int = 3) -> void:
	assert(x >= 0 and y >= 0 and x + value.length() * 6 <= 320 and y + 7 <= 180, "UI text outside viewport: " + value)
	var supported := ""
	for character: String in value:
		supported += character if character in glyphs else "?"
	draw_string(font, Vector2(x, y + 7), supported, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, palette[color])

static func wrap_lines(value: String, columns: int = 46) -> Array[String]:
	var lines: Array[String] = []
	for paragraph: String in value.split("\n"):
		var current := ""
		for word: String in paragraph.split(" ", false):
			while word.length() > columns:
				if not current.is_empty():
					lines.append(current)
					current = ""
				lines.append(word.left(columns))
				word = word.substr(columns)
			if current.length() + word.length() + (1 if not current.is_empty() else 0) > columns:
				lines.append(current)
				current = ""
			if not word.is_empty():
				current += (" " if not current.is_empty() else "") + word
		if not current.is_empty():
			lines.append(current)
	return lines
