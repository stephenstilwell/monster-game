extends RefCounted
var id: String = ""
var species_id: String = ""
var level: int = 1
var experience: int = 0
var hp: int = 1
var moves: Array[String] = []
var appearance_seed: int = 0

static func create(instance_id: String, species: Resource, at_level: int, seed_value: int = 0) -> RefCounted:
	var monster = load("res://scripts/monsters/monster_state.gd").new()
	monster.id = instance_id
	monster.species_id = species.id
	monster.level = clampi(at_level, 1, 20)
	monster.moves.assign(species.moves)
	monster.appearance_seed = seed_value
	monster.hp = monster.max_hp(species)
	return monster

func clone() -> RefCounted:
	var result = get_script().new()
	result.id = id
	result.species_id = species_id
	result.level = level
	result.experience = experience
	result.hp = hp
	result.moves.assign(moves)
	result.appearance_seed = appearance_seed
	return result

func max_hp(species: Resource) -> int:
	return species.base_hp + level * 4
func attack(species: Resource) -> int:
	return species.base_attack + level * 2
func defense(species: Resource) -> int:
	return species.base_defense + level
func speed(species: Resource) -> int:
	return species.base_speed + level

func gain_experience(amount: int, species: Resource) -> int:
	var old_level := level
	var old_max := max_hp(species)
	experience += maxi(0, amount)
	while level < 20 and experience >= level * 12:
		experience -= level * 12
		level += 1
	if level == 20:
		experience = 0
	if hp > 0:
		hp = mini(max_hp(species), hp + max_hp(species) - old_max)
	return level - old_level
