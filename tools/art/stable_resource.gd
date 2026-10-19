extends RefCounted
## Canonicalize Godot-generated IDs in tool-owned, newly constructed resources.
static func save(resource: Resource, path: String) -> Error:
	var result := ResourceSaver.save(resource, path)
	if result != OK:
		return result
	var content := FileAccess.get_file_as_string(path)
	var regex := RegEx.new()
	regex.compile(' id="([^"]+)"')
	var matches := regex.search_all(content)
	for index in range(matches.size()):
		content = content.replace('"' + matches[index].get_string(1) + '"', '"@temporary_%s"' % index)
	for index in range(matches.size()):
		content = content.replace('"@temporary_%s"' % index, '"stable_%s"' % index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK
