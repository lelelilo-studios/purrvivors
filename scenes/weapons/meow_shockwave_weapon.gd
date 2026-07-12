extends WeaponBase
## Sonic Meow - a periodic expanding shockwave. Pure crowd control:
## modest damage, big knockback, hits everything around the cat.

const FLASH_SCENE := preload("res://scenes/fx/flash_sprite.tscn")
const TEXTURE_PATH := "res://assets/sprites/fx/meow_ring.png"

var _texture: Texture2D
var _texture_size := 32.0


func _on_refresh() -> void:
	if _texture == null and ResourceLoader.exists(TEXTURE_PATH):
		_texture = load(TEXTURE_PATH)
		_texture_size = maxf(_texture.get_width(), 1.0)


func _try_fire() -> bool:
	var s := stats()
	var player := manager.player
	# Only meow when someone is around to hear it.
	if arena().enemy_grid.nearest(player.position, float(s.radius) * 1.3) == null:
		return false
	for enemy in arena().enemy_grid.query_radius(player.position, float(s.radius)):
		var away: Vector2 = (enemy.position - player.position).normalized()
		arena().damage_enemy(enemy, damage(), away * float(s.knockback))

	var ring: FlashSprite = ObjectPool.acquire(FLASH_SCENE)
	arena().fx_container.add_child(ring)
	var end_scale := float(s.radius) * 2.2 / _texture_size
	ring.flash(_texture, player.position, 0.0, 0.3, end_scale, 0.35, 0.9)
	arena().camera.add_trauma(0.12)
	AudioManager.play_sfx("meow", 0.15)
	return true
