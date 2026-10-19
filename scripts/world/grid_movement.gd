extends Node
## One reserved destination at a time; cell ownership changes only on completion.
signal step_completed(cell: Vector2i)
const STEP_SECONDS := 0.16
var cell := Vector2i.ZERO
var destination := Vector2i.ZERO
var facing := Vector2i.DOWN
var moving: bool = false
var locked: bool = false
var elapsed: float = 0.0

func place(at: Vector2i) -> void:
	cell = at
	destination = at
	moving = false
	elapsed = 0.0

func try_step(direction: Vector2i, can_enter: Callable) -> bool:
	if locked or moving or absi(direction.x) + absi(direction.y) != 1:
		return false
	facing = direction
	var target := cell + direction
	if not can_enter.call(target):
		return false
	destination = target
	elapsed = 0.0
	moving = true
	return true

func advance(delta: float) -> void:
	if not moving or locked:
		return
	elapsed = minf(elapsed + maxf(delta, 0.0), STEP_SECONDS)
	if elapsed >= STEP_SECONDS:
		cell = destination
		moving = false
		step_completed.emit(cell)

func foot_position() -> Vector2:
	var fraction: float = elapsed / STEP_SECONDS if moving else 0.0
	return (Vector2(cell).lerp(Vector2(destination), fraction) * 16.0 + Vector2(8, 15)).round()
