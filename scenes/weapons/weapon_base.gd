class_name WeaponBase
extends Node2D
## Base for auto-firing weapons. Subclasses implement _try_fire() and read
## their per-level numbers from stats(). Cooldown-based by default; weapons
## with different rhythms (orbiting laser) override _process.

var manager: WeaponManager
var weapon_id := ""
var cooldown_left := 0.0


func setup(mgr: WeaponManager, id: String) -> void:
	manager = mgr
	weapon_id = id
	_on_refresh()


func level() -> int:
	return manager.weapon_level(weapon_id)


func stats() -> Dictionary:
	return Balance.WEAPONS[weapon_id].levels[level() - 1]


## Weapon damage after the cat's damage multiplier (catnip + meta claws).
func damage() -> float:
	return float(stats().damage) * manager.player.eff_damage_mult


func arena() -> Node2D:
	return manager.player.arena


func refresh() -> void:
	_on_refresh()


func _process(delta: float) -> void:
	cooldown_left -= delta
	if cooldown_left <= 0.0 and _try_fire():
		cooldown_left = float(stats().cooldown)


## Return true if the weapon actually fired (starts the cooldown).
func _try_fire() -> bool:
	return false


func _on_refresh() -> void:
	pass
