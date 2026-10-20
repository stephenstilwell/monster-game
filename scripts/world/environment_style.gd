extends RefCounted
const Sprite = preload("res://scripts/world/environment_sprite.gd")
var regions: Dictionary
func _init() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/environment/manifest.json"))
	regions = manifest.regions.duplicate(true)
	for id: String in regions: regions[id].texture_path = "res://assets/generated/environment/" + regions[id].asset + ".png"
static func stable(value: String) -> int:
	var seed_value := 20261020
	for i in range(value.length()): seed_value = (seed_value * 31 + value.unicode_at(i)) % 2147483647
	return seed_value
static func map_seed(map: Resource) -> int:
	var seed_value := stable(map.id + map.title)
	for tile: int in map.tiles: seed_value = (seed_value * 31 + tile) % 2147483647
	return seed_value
func variant(prop: Dictionary, map: Resource, house_index: int, seed_value: int) -> String:
	var value := stable("%s/%s/%s" % [seed_value, prop.region, Vector2(prop.origin)])
	match prop.region:
		"tree": return "tree_%s" % (value % 6)
		"waystation": return "house_%s" % ((house_index + (0 if map.id == "town" else 2)) % 4)
		"flowers": return "flower_%s" % (value % 4)
	return ""
func sprite(id: String, origin: Vector2, seed_value: int) -> Sprite2D:
	var result := Sprite.new()
	result.name = "Scenery_" + id
	result.configure(regions[id], origin, seed_value)
	return result
func scatter(map: Resource, existing: Dictionary, seed_value: int) -> Array[Dictionary]:
	var exclusions: Array[Rect2] = []
	for prop: Dictionary in map.props:
		if not existing.has(prop.region): continue
		var rect: Array = existing[prop.region].rect
		exclusions.append(Rect2(Vector2(prop.origin) * 16, Vector2(rect[2], rect[3])).grow(3))
	for npc: Dictionary in map.npcs: exclusions.append(Rect2(Vector2(npc.cell - Vector2i.ONE) * 16, Vector2(48, 48)))
	for point: Vector2i in map.landmarks.values(): exclusions.append(Rect2(Vector2(point - Vector2i.ONE) * 16, Vector2(48, 48)))
	exclusions.append(Rect2(Vector2(map.start - Vector2i.ONE) * 16, Vector2(48, 48)))
	var result: Array[Dictionary] = []
	for y in range(2, map.size.y - 2):
		for x in range(2, map.size.x - 2):
			var cell := Vector2i(x, y)
			if map.tile_at(cell) not in [0, 1] or not map.can_enter(cell): continue
			var value := stable("%s/ground/%s/%s" % [seed_value, x, y])
			if value % 19 != 0: continue
			var area := Rect2(Vector2(cell) * 16, Vector2(24, 16))
			var clear := true
			for excluded: Rect2 in exclusions:
				if excluded.intersects(area): clear = false; break
			if not clear: continue
			var id := ("flower_" if value % 4 == 0 else "ground_") + str((value / 19) % 4)
			result.append({"region": id, "origin": cell, "seed": value})
			exclusions.append(area.grow(4))
	return result
