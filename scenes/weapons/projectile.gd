class_name Projectile
extends Node2D
## Generic pooled projectile: straight flight, grid-based hits, pierce,
## a bit of spin for charm.

var velocity := Vector2.ZERO
var damage := 1.0
var pierce := 0
var ttl := 1.2
var hit_radius := 9.0
var spin := 9.0
var knockback_strength := 70.0

var _arena: Node2D
var _hit: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite


func launch(arena: Node2D, texture: Texture2D, pos: Vector2, vel: Vector2,
		dmg: float, pierce_count: int, kb := 70.0, lifetime := 1.4,
		sprite_scale := 1.0) -> void:
	_arena = arena
	sprite.texture = texture
	sprite.scale = Vector2.ONE * sprite_scale
	position = pos
	velocity = vel
	damage = dmg
	pierce = pierce_count
	knockback_strength = kb
	ttl = lifetime
	_hit.clear()
	rotation = 0.0
	show()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	sprite.rotation += spin * delta
	ttl -= delta
	if ttl <= 0.0:
		_despawn()
		return
	for enemy in _arena.enemy_grid.query_radius(position, hit_radius):
		if _hit.has(enemy):
			continue
		_hit[enemy] = true
		_arena.damage_enemy(enemy, damage, velocity.normalized() * knockback_strength)
		pierce -= 1
		if pierce < 0:
			_despawn()
			return


func _despawn() -> void:
	ObjectPool.release(self)
