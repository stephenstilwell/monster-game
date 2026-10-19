extends Resource
## Baked map data. The same cell rules are used by traversal, spawning and tests.
@export var id: String = ""
@export var title: String = ""
@export var size := Vector2i.ZERO
@export var tiles := PackedInt32Array()
@export var blocked_cells: Array[Vector2i] = []
@export var props: Array[Dictionary] = []
@export var npcs: Array[Dictionary] = []
@export var interactions: Array[Dictionary] = []
@export var portals: Array[Dictionary] = []
@export var landmarks: Dictionary = {}
@export var start := Vector2i.ZERO

func contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)

func tile_at(cell: Vector2i) -> int:
	return tiles[cell.y * size.x + cell.x] if contains(cell) else -1

func can_enter(cell: Vector2i) -> bool:
	if not contains(cell) or cell in blocked_cells:
		return false
	var terrain := tile_at(cell)
	if terrain >= 6 and terrain < 28:
		return false
	for npc: Dictionary in npcs:
		if npc.cell == cell:
			return false
	return true

func portal_at(cell: Vector2i) -> Dictionary:
	for portal: Dictionary in portals:
		if portal.cell == cell:
			return portal
	return {}

func interaction_at(cell: Vector2i) -> Dictionary:
	for npc: Dictionary in npcs:
		if npc.cell == cell:
			return npc
	for entry: Dictionary in interactions:
		if entry.cell == cell or cell in entry.get("cells", []):
			return entry
	return {}

func safe_spawn(requested: Vector2i) -> Vector2i:
	var origin := requested.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	var pending: Array[Vector2i] = [origin]
	var visited := {origin: true}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if can_enter(cell) and portal_at(cell).is_empty():
			return cell
		for direction: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			var next := cell + direction
			if contains(next) and not visited.has(next):
				visited[next] = true
				pending.append(next)
	return Vector2i(-1, -1)
