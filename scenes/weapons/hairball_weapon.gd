extends WeaponBase
## Hairball Hurl - lobs hairballs at the nearest critter. Multi-shot levels
## fan the extra hairballs out slightly.

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const TEXTURE_PATH := "res://assets/sprites/fx/hairball.png"
const TARGET_RANGE := 300.0
const SPREAD_RAD := 0.16

var _texture: Texture2D


func _on_refresh() -> void:
	if _texture == null and ResourceLoader.exists(TEXTURE_PATH):
		_texture = load(TEXTURE_PATH)


func _try_fire() -> bool:
	var target: Object = arena().enemy_grid.nearest(manager.player.position, TARGET_RANGE)
	if target == null:
		return false
	var s := stats()
	var base_dir: Vector2 = (target.position - manager.player.position).normalized()
	var count := int(s.count)
	for i in count:
		var angle_offset := (i - (count - 1) * 0.5) * SPREAD_RAD
		var projectile: Projectile = ObjectPool.acquire(PROJECTILE_SCENE)
		arena().projectile_container.add_child(projectile)
		projectile.launch(
			arena(), _texture, manager.player.position,
			base_dir.rotated(angle_offset) * float(s.speed),
			damage(), int(s.pierce), 60.0, 1.4, 0.72
		)
	AudioManager.play_sfx("hairball", 0.12)
	return true
