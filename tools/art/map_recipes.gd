extends RefCounted
const Map = preload("res://scripts/world/map_definition.gd")
const SEEDS := {"town": 91207, "forest": 612431}

static func put(map: Map, area: Rect2i, tile: int) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if map.contains(Vector2i(x, y)):
				map.tiles[y * map.size.x + x] = tile + ((x + y) % 2 if tile in [0, 2, 4] else 0)

static func block(map: Map, area: Rect2i) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if map.contains(cell) and not cell in map.blocked_cells:
				map.blocked_cells.append(cell)

static func prop(map: Map, region: String, origin: Vector2i, obstacle: Rect2i = Rect2i()) -> void:
	map.props.append({"region": region, "origin": origin})
	if obstacle.has_area():
		block(map, obstacle)

static func water(map: Map, area: Rect2i) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var mask: int = (1 if y == area.position.y else 0) | (2 if x == area.end.x - 1 else 0) | (4 if y == area.end.y - 1 else 0) | (8 if x == area.position.x else 0)
			map.tiles[y * map.size.x + x] = 8 + mask if mask else 6 + (x + y) % 2

static func base(id: String, size: Vector2i) -> Map:
	var map := Map.new()
	map.id = id
	map.size = size
	map.tiles.resize(size.x * size.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEEDS[id]
	for index in range(map.tiles.size()):
		map.tiles[index] = rng.randi_range(0, 1)
	block(map, Rect2i(0, 0, size.x, 1))
	block(map, Rect2i(0, size.y - 1, size.x, 1))
	block(map, Rect2i(0, 0, 1, size.y))
	block(map, Rect2i(size.x - 1, 0, 1, size.y))
	return map

static func borders(map: Map, exit_side: String) -> void:
	for x in range(-1, map.size.x, 3):
		var top_tile := map.tile_at(Vector2i(x + 1, 1))
		if top_tile < 6 or top_tile >= 28:
			prop(map, "tree", Vector2i(x, -2))
		prop(map, "tree", Vector2i(x, map.size.y - 3))
	for y in range(1, map.size.y - 3, 3):
		if not (exit_side == "west" and y >= 10 and y <= 16):
			prop(map, "tree", Vector2i(-2, y))
		if not (exit_side == "east" and y >= 7 and y <= 13):
			prop(map, "tree", Vector2i(map.size.x - 1, y))

static func town() -> Map:
	var map := base("town", Vector2i(32, 24))
	map.title = "LANTERN REST"
	map.start = Vector2i(10, 12)
	put(map, Rect2i(2, 11, 30, 3), 2)
	put(map, Rect2i(9, 6, 3, 16), 2)
	put(map, Rect2i(6, 10, 5, 2), 2)
	put(map, Rect2i(18, 10, 3, 2), 2)
	water(map, Rect2i(21, 16, 8, 6))
	prop(map, "waystation", Vector2i(5, 7), Rect2i(5, 8, 4, 3))
	prop(map, "waystation", Vector2i(17, 7), Rect2i(17, 8, 4, 3))
	for x in [3, 5, 15, 17]:
		prop(map, "fence", Vector2i(x, 16), Rect2i(x, 17, 1, 1))
	for cell in [Vector2i(3, 5), Vector2i(13, 5), Vector2i(25, 5), Vector2i(3, 20), Vector2i(15, 19)]:
		prop(map, "tree", cell, Rect2i(cell + Vector2i(1, 3), Vector2i.ONE))
	for cell in [Vector2i(4, 18), Vector2i(6, 18), Vector2i(12, 15), Vector2i(22, 14), Vector2i(26, 14), Vector2i(8, 5)]:
		prop(map, "flowers", cell)
	prop(map, "route_sign", Vector2i(23, 9), Rect2i(23, 10, 1, 1))
	prop(map, "lantern_post", Vector2i(29, 9), Rect2i(29, 10, 1, 1))
	prop(map, "lantern_post", Vector2i(29, 13), Rect2i(29, 14, 1, 1))
	map.npcs.append({"id": "mara", "name": "MARA / TRAIL KEEPER", "cell": Vector2i(13, 11), "pages": ["THE EAST GATE LEADS TO FERNGLASS WOOD. FOLLOW THE LANTERNS AND THE STREAM.", "IVO IS REPAIRING THE OLD BRIDGE. HE ALWAYS HAS A TRAIL STORY TO SHARE."]})
	map.interactions.append({"id": "east_sign", "name": "FERNGLASS WOOD", "cell": Vector2i(23, 10), "pages": ["EAST: FERNGLASS WOOD. WEST: LANTERN REST. STAY ON THE PALE WOODEN BRIDGE."]})
	map.interactions.append({"id": "town_door", "name": "KEEPERS' LODGE", "cell": Vector2i(7, 10), "cells": [Vector2i(6, 10), Vector2i(7, 10)], "pages": ["A NOTE ON THE DOOR: OUT ON THE TRAIL. THE LANTERN IS LIT FOR YOUR RETURN."]})
	for y in [11, 12, 13]:
		var cell := Vector2i(31, y)
		map.blocked_cells.erase(cell)
		map.portals.append({"cell": cell, "map": "forest", "spawn": Vector2i(2, 14)})
	map.landmarks = {"mara": Vector2i(13, 12), "sign": Vector2i(23, 11), "door": Vector2i(7, 11), "gate": Vector2i(31, 12), "return": Vector2i(29, 12)}
	borders(map, "east")
	return map

static func forest() -> Map:
	var map := base("forest", Vector2i(36, 28))
	map.title = "FERNGLASS WOOD"
	map.start = Vector2i(2, 14)
	water(map, Rect2i(20, 1, 4, 26))
	put(map, Rect2i(0, 14, 16, 2), 2)
	put(map, Rect2i(14, 6, 2, 10), 2)
	put(map, Rect2i(14, 6, 17, 2), 2)
	# Restore the river away from the authored bridge, then lay two bridge lanes.
	water(map, Rect2i(20, 1, 4, 26))
	for x in range(20, 24):
		map.tiles[6 * map.size.x + x] = 32
		map.tiles[7 * map.size.x + x] = 33
	put(map, Rect2i(29, 6, 2, 18), 2)
	put(map, Rect2i(26, 22, 5, 2), 2)
	prop(map, "waystation", Vector2i(25, 18), Rect2i(25, 19, 4, 3))
	put(map, Rect2i(6, 17, 6, 5), 4)
	put(map, Rect2i(25, 11, 3, 4), 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEEDS.forest + 41
	for y in range(2, 24, 3):
		for x in range(3, 32, 3):
			var area := Rect2i(x, y, 3, 4)
			var clear := true
			for dy in range(area.position.y, area.end.y):
				for dx in range(area.position.x, area.end.x):
					if map.tile_at(Vector2i(dx, dy)) >= 2 or (dx >= 24 and dy >= 17):
						clear = false
			if clear and rng.randf() > 0.2:
				prop(map, "tree", area.position, Rect2i(x + 1, y + 3, 1, 1))
	for cell in [Vector2i(5, 12), Vector2i(11, 10), Vector2i(16, 17), Vector2i(32, 12), Vector2i(25, 8)]:
		prop(map, "stump", cell, Rect2i(cell, Vector2i.ONE))
	for cell in [Vector2i(3, 16), Vector2i(10, 16), Vector2i(13, 9), Vector2i(26, 5), Vector2i(31, 22)]:
		prop(map, "flowers", cell)
	for y in [10, 16, 22]:
		prop(map, "reeds", Vector2i(19, y))
		prop(map, "reeds", Vector2i(24, y))
	prop(map, "lantern_post", Vector2i(18, 4), Rect2i(18, 5, 1, 1))
	prop(map, "lantern_post", Vector2i(25, 4), Rect2i(25, 5, 1, 1))
	prop(map, "route_sign", Vector2i(27, 23), Rect2i(27, 24, 1, 1))
	map.npcs.append({"id": "ivo", "name": "IVO / BRIDGE WARDEN", "cell": Vector2i(12, 13), "pages": ["THE BRIDGE IS SOLID. THE SHALLOWS ARE NOT A PATH. KEEP YOUR BOOTS DRY.", "FOLLOW THE STREAM NORTH, THEN CROSS EAST. AN OLD WAYSTATION WAITS BEYOND THE FERNS."]})
	map.interactions.append({"id": "old_sign", "name": "OLD WAYSTATION", "cell": Vector2i(27, 24), "pages": ["THE TIMBER IS QUIET, BUT ONE SMALL LANTERN STILL WATCHES THE WATER."]})
	map.interactions.append({"id": "old_door", "name": "MOSSY DOOR", "cell": Vector2i(27, 21), "cells": [Vector2i(26, 21), Vector2i(27, 21)], "pages": ["FERNS CURL AROUND THE LOCK. SOMEONE HAS LEFT A FRESH SPRIG ON THE STEP."]})
	for y in [14, 15]:
		var cell := Vector2i(0, y)
		map.blocked_cells.erase(cell)
		map.portals.append({"cell": cell, "map": "town", "spawn": Vector2i(29, 12)})
	map.landmarks = {"ivo": Vector2i(12, 14), "bridge_west": Vector2i(19, 6), "bridge_east": Vector2i(24, 6), "door": Vector2i(27, 22), "sign": Vector2i(27, 23), "gate": Vector2i(0, 14)}
	borders(map, "west")
	return map

static func maps() -> Array[Map]:
	return [town(), forest()]
