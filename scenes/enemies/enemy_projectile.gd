extends Node2D
## Pooled enemy shot (sprinkler water blob). Hurts only the cat.

const TEXTURE_PATH := "res://assets/sprites/fx/water_drop.png"

static var _texture: Texture2D

var velocity := Vector2.ZERO
var damage := 1
var ttl := 3.0
var _arena: Node2D

@onready var sprite: Sprite2D = $Sprite


func launch(arena: Node2D, pos: Vector2, vel: Vector2, dmg: int) -> void:
	_arena = arena
	position = pos
	velocity = vel
	damage = dmg
	ttl = 3.0
	if _texture == null and ResourceLoader.exists(TEXTURE_PATH):
		_texture = load(TEXTURE_PATH)
	sprite.texture = _texture
	show()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	ttl -= delta
	if ttl <= 0.0:
		ObjectPool.release(self)
		return
	if position.distance_to(_arena.player.position) < Balance.PLAYER_CONTACT_RADIUS:
		_arena.player.take_hit(damage, position)
		ObjectPool.release(self)
