class_name UpgradePool
extends RefCounted
## Rolls the 3 level-up cards. Weighted, no maxed dupes, respects slot caps.
## Luck rule (see Balance): per card slot, sample (1 + luck) candidates and
## keep the rarest - more luck, spicier options.


static func roll(player: Player, count := Balance.CARDS_PER_LEVEL_UP) -> Array[Dictionary]:
	var mgr := player.weapons
	var candidates: Array[Dictionary] = []

	for id: String in Balance.WEAPONS:
		var w: Dictionary = Balance.WEAPONS[id]
		var lvl := mgr.weapon_level(id)
		if lvl == 0 and mgr.weapon_count() < Balance.MAX_WEAPONS:
			candidates.append(_card("weapon_new", id, w.display_name, "New weapon: %s" % w.levels[0].upgrade_text, w.flavor, w.icon, 8.0))
		elif lvl > 0 and lvl < w.levels.size():
			candidates.append(_card("weapon_up", id, "%s Lv %d" % [w.display_name, lvl + 1], w.levels[lvl].upgrade_text, w.flavor, w.icon, 10.0))

	for id: String in Balance.PASSIVES:
		var p: Dictionary = Balance.PASSIVES[id]
		var lvl := mgr.passive_level(id)
		if lvl == 0 and mgr.passive_count() < Balance.MAX_PASSIVES:
			candidates.append(_card("passive", id, p.display_name, p.upgrade_text[0], p.flavor, p.icon, 7.0))
		elif lvl > 0 and lvl < int(p.max_level):
			candidates.append(_card("passive", id, "%s Lv %d" % [p.display_name, lvl + 1], p.upgrade_text[lvl], p.flavor, p.icon, 9.0))

	var result: Array[Dictionary] = []
	var luck_tries := 1 + int(player.luck)
	for slot in count:
		if candidates.is_empty():
			result.append(_card("snack_bag", "snack_bag", "Snack Bag",
				"Everything is maxed! Heal 2 HP and gain 10 XP instead.",
				"The bottom of the bag is the best part.", "res://assets/sprites/snacks/cookie.png", 1.0))
			continue
		var best: Dictionary = {}
		for t in luck_tries:
			var pick := _pick_weighted(candidates)
			if best.is_empty() or pick.weight < best.weight:   # lower weight = rarer
				best = pick
		candidates.erase(best)
		result.append(best)
	return result


static func apply(player: Player, option: Dictionary) -> void:
	match option.kind:
		"weapon_new":
			player.weapons.add_weapon(option.id)
		"weapon_up":
			player.weapons.level_up_weapon(option.id)
		"passive":
			player.weapons.add_passive(option.id)
		"snack_bag":
			player.heal(2)
			GameData.gain_xp(10)


static func _card(kind: String, id: String, title: String, text: String,
		flavor: String, icon: String, weight: float) -> Dictionary:
	return {"kind": kind, "id": id, "title": title, "text": text,
		"flavor": flavor, "icon": icon, "weight": weight}


static func _pick_weighted(candidates: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for c in candidates:
		total += c.weight
	var roll := randf() * total
	for c in candidates:
		roll -= c.weight
		if roll <= 0.0:
			return c
	return candidates[0]
