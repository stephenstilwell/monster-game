extends RefCounted
var rng := RandomNumberGenerator.new()
var cooldown: int = 0
var grass_steps: int = 0
func _init(seed_value: int = 573029) -> void:
	rng.seed = seed_value
func step(map: Resource, cell: Vector2i) -> Dictionary:
	if cooldown > 0:
		cooldown -= 1
		return {}
	if map.id != "forest" or not map.tile_at(cell) in [4, 5]:
		grass_steps = 0
		return {}
	grass_steps += 1
	if rng.randf() >= 0.22 and grass_steps < 5: return {}
	grass_steps = 0
	cooldown = 6
	return {"species": ["brindlewick", "cindrel", "rillume"][rng.randi_range(0, 2)], "level": rng.randi_range(3, 5)}
func returned() -> void:
	cooldown = 6
	grass_steps = 0
