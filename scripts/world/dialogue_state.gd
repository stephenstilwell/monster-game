extends RefCounted
var speaker: String = ""
var pages: Array[String] = []
var index: int = 0
var active: bool = false

func open(entry: Dictionary) -> void:
	speaker = entry.get("name", "TRAIL NOTE")
	pages.clear()
	for page: String in entry.get("pages", []):
		pages.append(page)
	index = 0
	active = not pages.is_empty()

func advance() -> void:
	if not active:
		return
	index += 1
	if index >= pages.size():
		close()

func close() -> void:
	active = false
	index = 0

func current_text() -> String:
	return pages[index] if active else ""
