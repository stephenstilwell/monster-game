extends RefCounted
var id: int = 0
var party: Array = []
var enemy: RefCounted
var active: int = 0
var inventory: Dictionary = {}
var rng := RandomNumberGenerator.new()
var turn: int = 0
var flee_attempts: int = 0
var outcome: String = ""
var habitat: String = "forest"
var guardian: bool = false
var capture_allowed: bool = true
var ally_damage_bonus: int = 0
var foe_damage_reduction: int = 0

func first_healthy() -> int:
	for index in range(party.size()):
		if party[index].hp > 0:
			return index
	return -1

var foe_damage_bonus: int = 0
var risk_bonus: int = 0
var opening_bonus: int = 0
var capture_bonus: float = 0.0
