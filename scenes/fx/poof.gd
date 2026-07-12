class_name Poof
extends CPUParticles2D
## Pooled one-shot particle burst: enemy death poofs, snack-eat sparkles,
## level-up bursts. CPUParticles2D on purpose - reliable on web.

var _release_timer: SceneTreeTimer


func burst(pos: Vector2, color_a: Color, count := 10, size := 3.0, velocity := 55.0) -> void:
	position = pos
	color = color_a
	amount = count
	scale_amount_min = size * 0.6
	scale_amount_max = size
	initial_velocity_min = velocity * 0.6
	initial_velocity_max = velocity
	emitting = true
	restart()
	_release_timer = get_tree().create_timer(lifetime + 0.1)
	_release_timer.timeout.connect(_done, CONNECT_ONE_SHOT)


func _done() -> void:
	if is_inside_tree():
		ObjectPool.release(self)


func _pool_sleep() -> void:
	emitting = false
