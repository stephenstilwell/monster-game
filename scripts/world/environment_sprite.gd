extends Sprite2D
## Baked pixel poses; no scaling, rotation, shader distortion or trunk movement.
var base_rect := Rect2()
var frame_count: int = 1
var step: float = 0.6
var phase: float = 0.0
var elapsed: float = 0.0
var current_pose: int = -1
const CYCLE := [0, 0, 1, 1, 0, 0, 2, 2, 0, 0, 3, 3]
func configure(spec: Dictionary, origin: Vector2, seed_value: int) -> void:
	texture = load(spec.texture_path)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region_enabled = true
	centered = false
	var r: Array = spec.rect
	base_rect = Rect2(r[0], r[1], r[2], r[3])
	var anchor := Vector2(spec.anchor[0], spec.anchor[1])
	offset = -anchor
	position = origin * 16 + anchor
	frame_count = int(spec.frames)
	step = float(spec.step)
	phase = float(seed_value % 120) * 0.1
	synchronize(0.0)
	set_process(frame_count > 1)
func _ready() -> void:
	set_process(frame_count > 1)
func synchronize(time: float) -> void:
	var pose: int = CYCLE[posmod(floori((time + phase) / step), CYCLE.size())] if frame_count > 1 else 0
	if pose == current_pose: return
	current_pose = pose
	region_rect = Rect2(base_rect.position + Vector2(pose * base_rect.size.x, 0), base_rect.size)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed += delta
	synchronize(elapsed)
