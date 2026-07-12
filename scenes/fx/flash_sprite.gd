class_name FlashSprite
extends Sprite2D
## Pooled one-shot visual: shows a texture that scales + fades out, then
## returns itself to the pool. Claw slashes, meow rings, impact flashes.

var _tween: Tween


func flash(tex: Texture2D, pos: Vector2, rot: float, start_scale: float,
		end_scale: float, duration: float, start_alpha := 1.0) -> void:
	texture = tex
	position = pos
	rotation = rot
	scale = Vector2.ONE * start_scale
	modulate = Color(1, 1, 1, start_alpha)
	show()
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "scale", Vector2.ONE * end_scale, duration)
	_tween.tween_property(self, "modulate:a", 0.0, duration)
	_tween.chain().tween_callback(_done)


func _done() -> void:
	if is_inside_tree():
		ObjectPool.release(self)


func _pool_sleep() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
