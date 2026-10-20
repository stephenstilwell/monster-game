extends RefCounted
const Map = preload("res://scripts/world/map_definition.gd")
const Recipes = preload("res://tools/art/map_recipes.gd")
const CONTENT := "m5.1"
const SPECIES := ["brindlewick", "cindrel", "rillume"]
const THEMES := ["GROVE", "EMBER", "BROOK"]

static func options(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 101
	var stages: Array = []
	for depth in range(3):
		var first := rng.randi_range(0, 2)
		var choices: Array = []
		for branch in range(2):
			choices.append({"template": rng.randi_range(0, 2), "theme": (first + branch) % 3, "seed": str(rng.randi())})
		stages.append(choices)
	return {"stages": stages, "state": str(rng.state)}

static func build(option: Dictionary, depth: int, cleared: Array = []) -> Resource:
	var map := Map.new()
	map.id = "expedition"
	map.title = "FERNGLASS %s / %s" % [depth + 1, THEMES[int(option.theme)]]
	map.size = Vector2i(32, 20)
	map.start = Vector2i(3, 14)
	map.tiles.resize(640)
	var rng := RandomNumberGenerator.new()
	rng.seed = option.seed.to_int()
	for i in range(640): map.tiles[i] = rng.randi_range(0, 1)
	for edge: Rect2i in [Rect2i(0, 0, 32, 2), Rect2i(0, 18, 32, 2), Rect2i(0, 0, 2, 20), Rect2i(30, 0, 2, 20)]: Recipes.block(map, edge)
	var nodes: Array[Vector2i] = [Vector2i(10, 14), Vector2i(22, 14)]
	var exit := Vector2i(28, 7)
	if option.template == 1:
		Recipes.put(map, Rect2i(2, 13, 12, 2), 2)
		Recipes.put(map, Rect2i(12, 7, 2, 8), 2)
		Recipes.put(map, Rect2i(12, 7, 18, 2), 2)
		nodes = [Vector2i(12, 11), Vector2i(22, 7)]
	else:
		Recipes.put(map, Rect2i(2, 13, 28, 2), 2)
		Recipes.put(map, Rect2i(28, 7, 2, 8), 2)
		if option.template == 2:
			Recipes.water(map, Rect2i(15, 2, 3, 16))
			for x in range(15, 18):
				map.tiles[13 * 32 + x] = 32
				map.tiles[14 * 32 + x] = 33
	for i in range(2):
		Recipes.put(map, Rect2i(nodes[i] - Vector2i.ONE, Vector2i(3, 3)), 4)
		Recipes.prop(map, "m5_cleared" if i in cleared else "m5_fern", nodes[i] - Vector2i(0, 1))
		map.landmarks["encounter_%s" % i] = nodes[i]
		map.interactions.append({"id": "light_%s" % i, "cell": nodes[i], "action": "encounter_%s" % i})
	for origin: Vector2i in [Vector2i(4, 3), Vector2i(8, 3), Vector2i(20, 2), Vector2i(25, 2)]:
		Recipes.prop(map, "tree", origin, Rect2i(origin + Vector2i(1, 3), Vector2i.ONE))
	# Authored grove clusters keep broad terrain varied without hiding marked paths.
	for origin: Vector2i in [Vector2i(5, 7), Vector2i(9, 6), Vector2i(18, 5), Vector2i(22, 8), Vector2i(3, 10)]:
		var clear := true
		for y in range(origin.y, origin.y + 4):
			for x in range(origin.x, origin.x + 3):
				if map.tile_at(Vector2i(x, y)) not in [0, 1]: clear = false
		if clear: Recipes.prop(map, "tree", origin, Rect2i(origin + Vector2i(1, 3), Vector2i.ONE))
	for cell: Vector2i in [Vector2i(7, 12), Vector2i(19, 12), Vector2i(25, 16), Vector2i(5, 16)]:
		if map.tile_at(cell) in [0, 1]: Recipes.prop(map, "stump" if cell.x % 2 else "rock", cell, Rect2i(cell, Vector2i.ONE))
	if option.template == 2:
		for y in [5, 9, 16]: Recipes.prop(map, "reeds", Vector2i(14, y))
	for i in range(9):
		var cell := Vector2i(rng.randi_range(3, 27), rng.randi_range(16, 17))
		Recipes.prop(map, "flowers", cell)
	Recipes.prop(map, "m5_camp" if depth == 1 else "m5_guardian_gate" if depth == 2 else "m5_gate", exit - Vector2i(1, 2))
	map.landmarks.exit = exit
	map.portals.append({"cell": exit, "action": "stage_exit"})
	map.interactions.append({"id": "exit", "cell": exit, "action": "stage_exit"})
	Recipes.borders(map, "none")
	return map

static func hub() -> Resource:
	var map: Resource = load("res://data/maps/town.tres").duplicate(true)
	map.portals.clear()
	for y in [11, 12, 13]: map.portals.append({"cell": Vector2i(31, y), "action": "departure"})
	map.npcs[0].pages = ["YOUR SANCTUARY PARTNERS STAY SAFE. TAKE ONE INTO THE EAST GATE AT LEVEL FIVE.", "CAPTURE ON THE TRAIL. RETURN FROM CAMP OR WIN TO BRING ONE LIVING RECRUIT HOME."]
	# Ivo joins the hub; both guides remain useful after every outcome.
	map.npcs.append({"id": "ivo", "name": "IVO / CAMP KEEPER", "cell": Vector2i(20, 11), "pages": ["TWO FERN LIGHTS MARK EACH STAGE. CLEAR THEM, THEN FOLLOW THE LARGE LANTERN.", "AFTER STAGE TWO, CAMP REST WORKS ONCE. RETREAT SAFELY OR CONTINUE TO THE GUARDIAN."]})
	Recipes.prop(map, "m5_sanctuary", Vector2i(12, 16), Rect2i(12, 18, 4, 1))
	Recipes.prop(map, "m5_gate", Vector2i(28, 8))
	return map