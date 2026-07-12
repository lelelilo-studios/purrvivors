class_name Boomerang
extends Node2D
## Pooled boomerang projectile (Boomerfish). Flies out, comes back, hits on
## both legs of the trip. Fish are loyal.

const CATCH_RADIUS := 18.0

var damage := 1.0
var speed := 220.0
var range_px := 150.0
var hit_radius := 12.0
var knockback_strength := 60.0

var _arena: Node2D
var _player: Node2D
var _direction := Vector2.ZERO
var _travelled := 0.0
var _returning := false
var _hit: Dictionary = {}
var _ttl := 6.0

@onready var sprite: Sprite2D = $Sprite


func launch(arena: Node2D, player: Node2D, texture: Texture2D, dir: Vector2,
		dmg: float, spd: float, reach: float) -> void:
	_arena = arena
	_player = player
	sprite.texture = texture
	position = player.position
	_direction = dir
	damage = dmg
	speed = spd
	range_px = reach
	_travelled = 0.0
	_returning = false
	_ttl = 6.0
	_hit.clear()
	show()


func _physics_process(delta: float) -> void:
	sprite.rotation += 14.0 * delta
	_ttl -= delta
	if _ttl <= 0.0:
		ObjectPool.release(self)
		return

	if not _returning:
		var step := speed * delta
		position += _direction * step
		_travelled += step
		if _travelled >= range_px:
			_returning = true
			_hit.clear()   # fresh hits on the way home
	else:
		var home: Vector2 = _player.position
		position = position.move_toward(home, speed * 1.2 * delta)
		if position.distance_to(home) < CATCH_RADIUS:
			ObjectPool.release(self)
			return

	for enemy in _arena.enemy_grid.query_radius(position, hit_radius):
		if _hit.has(enemy):
			continue
		_hit[enemy] = true
		var kb: Vector2 = (enemy.position - position).normalized() * knockback_strength
		_arena.damage_enemy(enemy, damage, kb)
