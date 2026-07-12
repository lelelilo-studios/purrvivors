class_name WeaponManager
extends Node2D
## Owns the cat's arsenal: weapon levels + passive levels. Weapon scenes are
## children that auto-fire; passives are pure stats applied via
## player.recompute_stats().

var player: Player
var weapon_levels: Dictionary = {}    # id -> level (1-based)
var passive_levels: Dictionary = {}   # id -> level (1-based)
var nine_lives_consumed := false

var _weapon_nodes: Dictionary = {}


func setup(p: Player) -> void:
	player = p
	weapon_levels.clear()
	passive_levels.clear()
	nine_lives_consumed = false
	for node: Node in _weapon_nodes.values():
		node.queue_free()
	_weapon_nodes.clear()


func add_weapon(id: String) -> void:
	if weapon_levels.has(id):
		level_up_weapon(id)
		return
	weapon_levels[id] = 1
	var scene: PackedScene = load("res://scenes/weapons/%s_weapon.tscn" % id)
	var node: WeaponBase = scene.instantiate()
	add_child(node)
	node.setup(self, id)
	_weapon_nodes[id] = node


func level_up_weapon(id: String) -> void:
	var max_level: int = Balance.WEAPONS[id].levels.size()
	if weapon_levels.get(id, 0) >= max_level:
		return
	weapon_levels[id] += 1
	_weapon_nodes[id].refresh()


func add_passive(id: String) -> void:
	passive_levels[id] = mini(passive_levels.get(id, 0) + 1, int(Balance.PASSIVES[id].max_level))
	player.recompute_stats()


func weapon_level(id: String) -> int:
	return int(weapon_levels.get(id, 0))


func passive_level(id: String) -> int:
	return int(passive_levels.get(id, 0))


func weapon_count() -> int:
	return weapon_levels.size()


func passive_count() -> int:
	return passive_levels.size()
