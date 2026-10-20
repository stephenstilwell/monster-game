extends RefCounted
const Codec = preload("res://scripts/save/save_codec.gd")
var directory := "user://saves"
var codec: Script = Codec

func read_file(path: String, maps: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error": "NO SAVE FOUND."}
	if FileAccess.get_file_as_bytes(path).size() > 8388608: return {"error": "SAVE TOO LARGE."}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {"error": "SAVE IS CORRUPT."}
	var envelope: Variant = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("digest") is String: return {"error": "SAVE IS CORRUPT."}
	if envelope.payload.sha256_text() != envelope.digest: return {"error": "SAVE CHECKSUM FAILED."}
	if parser.parse(envelope.payload) != OK: return {"error": "SAVE IS CORRUPT."}
	var raw: Variant = parser.data
	return codec.decode(raw, maps)

func load_game(maps: Dictionary) -> Dictionary:
	var primary := read_file(directory + "/slot.json", maps)
	if not primary.has("error"): return primary
	# A newer valid schema protects the slot from fallback and overwrite.
	if primary.error in ["UNSUPPORTED SAVE VERSION.", "UNSUPPORTED CONTENT VERSION."]: return primary
	for name: String in ["pending.json", "backup.json"]:
		var recovered := read_file(directory + "/" + name, maps)
		if recovered.get("error", "") in ["UNSUPPORTED SAVE VERSION.", "UNSUPPORTED CONTENT VERSION."]: return recovered
		if not recovered.has("error"):
			recovered.recovered = name
			return recovered
	return primary

func save_game(data: Dictionary, maps: Dictionary) -> String:
	if codec.decode(data, maps).has("error"): return "INVALID STATE. SAVE REFUSED."
	var primary := directory + "/slot.json"
	var previous := read_file(primary, maps)
	if previous.get("error", "") in ["UNSUPPORTED SAVE VERSION.", "UNSUPPORTED CONTENT VERSION."]: return "NEWER SAVE PROTECTED."
	# Preserve the recoverable candidate before reusing pending.json.
	if previous.has("error"):
		var recovery := load_game(maps)
		if recovery.get("error", "") in ["UNSUPPORTED SAVE VERSION.", "UNSUPPORTED CONTENT VERSION."]: return "NEWER SAVE PROTECTED."
		if recovery.has("recovered"):
			if FileAccess.file_exists(primary) and DirAccess.remove_absolute(primary) != OK: return "CANNOT RECOVER SAVE."
			if DirAccess.copy_absolute(directory + "/" + recovery.recovered, primary) != OK: return "CANNOT RECOVER SAVE."
			previous = read_file(primary, maps)
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return "CANNOT CREATE SAVE DIRECTORY."
	# Keep the source schema independently of rotating gameplay backups.
	if previous.get("legacy", false):
		if not FileAccess.file_exists(directory + "/legacy_v2.json"):
			if DirAccess.copy_absolute(primary, directory + "/legacy_v2.json") != OK: return "CANNOT PRESERVE LEGACY SAVE."
		if read_file(directory + "/legacy_v2.json", maps).has("error"): return "LEGACY BACKUP FAILED VALIDATION."
	if previous.get("migrated", false):
		var original := directory + "/legacy_v3.json"
		if not FileAccess.file_exists(original):
			if DirAccess.copy_absolute(primary, original) != OK: return "CANNOT PRESERVE V3 SAVE."
		if read_file(original, maps).has("error"): return "V3 BACKUP FAILED VALIDATION."
	var payload := JSON.stringify(data, "", true)
	var pending := directory + "/pending.json"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null: return "CANNOT WRITE SAVE."
	file.store_string(JSON.stringify({"payload": payload, "digest": payload.sha256_text()}))
	file.flush()
	file.close()
	if read_file(pending, maps).has("error"): return "SAVE VERIFICATION FAILED."
	var backup := directory + "/backup.json"
	if not previous.has("error"):
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK: return "CANNOT ROTATE BACKUP."
		if DirAccess.rename_absolute(primary, backup) != OK: return "CANNOT BACK UP SAVE."
	elif FileAccess.file_exists(primary):
		if DirAccess.remove_absolute(primary) != OK: return "CANNOT REPLACE DAMAGED SAVE."
	if DirAccess.rename_absolute(pending, primary) != OK: return "WRITE INTERRUPTED. RECOVERY AVAILABLE."
	return "SAVED."
