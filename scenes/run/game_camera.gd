class_name GameCamera
extends Camera2D
## Camera: integer zoom driven by viewport size (crisp pixels on any device)
## plus trauma-based screen shake. The arena feeds it the player position;
## built-in position smoothing does the easing.

const BASE_VIEW := Vector2(640.0, 360.0)
const MAX_SHAKE_OFFSET := 7.0
const TRAUMA_DECAY := 1.6

var trauma := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	get_viewport().size_changed.connect(_update_zoom)
	_update_zoom()


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - TRAUMA_DECAY * delta)
		var shake := trauma * trauma
		offset = Vector2(
			randf_range(-1.0, 1.0) * MAX_SHAKE_OFFSET * shake,
			randf_range(-1.0, 1.0) * MAX_SHAKE_OFFSET * shake
		)
	else:
		offset = Vector2.ZERO


func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func _update_zoom() -> void:
	var vp := get_viewport_rect().size
	var z := maxi(1, floori(minf(vp.x / BASE_VIEW.x, vp.y / BASE_VIEW.y)))
	zoom = Vector2(z, z)


## World-space radius that guarantees a point is outside the visible screen.
func offscreen_radius() -> float:
	var vp := get_viewport_rect().size
	return (vp * 0.5 / zoom.x).length()
