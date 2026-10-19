extends Node2D
const DIRECTIONS := {Vector2i.DOWN: "south", Vector2i.UP: "north", Vector2i.LEFT: "west", Vector2i.RIGHT: "east"}
var prefix: String = "player"

func configure(frames: SpriteFrames, animation_prefix: String) -> void:
	prefix = animation_prefix
	$Sprite.sprite_frames = frames
	show_state(Vector2i.DOWN, false)

func show_state(facing: Vector2i, walking: bool) -> void:
	var animation: String = "%s_%s_%s" % [prefix, "walk" if walking else "idle", DIRECTIONS[facing]]
	if $Sprite.animation != animation:
		$Sprite.play(animation)
