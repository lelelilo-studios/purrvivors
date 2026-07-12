extends WeaponBase
## Claws Out - a melee arc toward the nearest critter. High knockback,
## hits everything in the wedge. Melee risk, crowd-control reward.

const FLASH_SCENE := preload("res://scenes/fx/flash_sprite.tscn")
const TEXTURE_PATH := "res://assets/sprites/fx/claw_swipe.png"

var _texture: Texture2D


func _on_refresh() -> void:
	if _texture == null and ResourceLoader.exists(TEXTURE_PATH):
		_texture = load(TEXTURE_PATH)


func _try_fire() -> bool:
	var s := stats()
	var reach := float(s.range)
	var player := manager.player
	var target: Object = arena().enemy_grid.nearest(player.position, reach * 1.25)
	if target == null:
		return false
	var aim: Vector2 = (target.position - player.position).normalized()
	var half_arc := deg_to_rad(float(s.arc_deg)) * 0.5

	for enemy in arena().enemy_grid.query_radius(player.position, reach):
		var offset: Vector2 = enemy.position - player.position
		if absf(aim.angle_to(offset)) <= half_arc:
			arena().damage_enemy(enemy, damage(), offset.normalized() * float(s.knockback))

	var slash: FlashSprite = ObjectPool.acquire(FLASH_SCENE)
	arena().fx_container.add_child(slash)
	slash.flash(_texture, player.position + aim * reach * 0.55, aim.angle() + PI * 0.5,
		0.8 + reach / 60.0, 1.3 + reach / 60.0, 0.22)
	AudioManager.play_sfx("claw", 0.12)
	return true
