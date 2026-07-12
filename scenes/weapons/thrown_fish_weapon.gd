extends WeaponBase
## Boomerfish - throws a returning fish through the crowd. Line-pierce AoE
## that rewards aim-by-positioning.

const BOOMERANG_SCENE := preload("res://scenes/weapons/boomerang.tscn")
const TEXTURE_PATH := "res://assets/sprites/fx/thrown_fish.png"

var _texture: Texture2D
var _alternate := false


func _on_refresh() -> void:
	if _texture == null and ResourceLoader.exists(TEXTURE_PATH):
		_texture = load(TEXTURE_PATH)


func _try_fire() -> bool:
	var s := stats()
	var player := manager.player
	var target: Object = arena().enemy_grid.nearest(player.position, float(s.range) * 1.6)
	if target == null:
		return false
	var aim: Vector2 = (target.position - player.position).normalized()
	var count := int(s.count)
	for i in count:
		var dir := aim
		if count > 1:
			# Second fish goes the other way: cover your back.
			dir = aim if i == 0 else -aim
		var fish: Boomerang = ObjectPool.acquire(BOOMERANG_SCENE)
		arena().projectile_container.add_child(fish)
		fish.launch(arena(), player, _texture, dir, damage(), float(s.speed), float(s.range))
	AudioManager.play_sfx("fish_throw", 0.12)
	return true
