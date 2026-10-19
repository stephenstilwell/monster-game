extends RefCounted
var species: Dictionary = {}
var moves: Dictionary = {}
var items: Dictionary = {}
func _init() -> void:
	for id in ["brindlewick", "cindrel", "rillume"]:
		species[id] = load("res://data/species/" + id + ".tres")
	for id in ["nudge", "leaf_arc", "cinder", "rill", "quickstep"]:
		moves[id] = load("res://data/moves/" + id + ".tres")
	for id in ["charm", "balm"]:
		items[id] = load("res://data/items/" + id + ".tres")
