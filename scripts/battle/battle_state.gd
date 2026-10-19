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

func first_healthy() -> int:
	for index in range(party.size()):
		if party[index].hp > 0:
			return index
	return -1
