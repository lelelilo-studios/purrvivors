extends Node
## GameData - run + meta state and the game-wide event bus.
## Systems mutate state through methods here; UI listens to the signals.
## Persistent meta (coins, upgrades, unlocks, bests) round-trips SaveManager.

signal meta_coins_changed(total: int)
signal run_coins_changed(amount: int)
signal xp_changed(xp: int, needed: int)
signal leveled_up(new_level: int)
signal kills_changed(kills: int)
signal player_hp_changed(hp: int, max_hp: int)
signal boss_defeated(boss_id: String, bosses_beaten: int)
signal run_ended(summary: Dictionary)

# ------------------------------- meta state --------------------------------

var meta := {
	"coins": 0,
	"upgrades": {},          # upgrade_id -> owned tiers (int)
	"unlocked_cats": ["tabby"],
	"best": {},              # cat_id -> {"tier": int, "score": int}
	"selected_cat": "tabby",
	"runs": 0,               # total runs started (rotates the biome)
}

# -------------------------------- run state --------------------------------

var run_active := false
var run_time := 0.0
var kills := 0
var run_coins := 0
var score := 0
var bosses_beaten := 0
var level := 1
var xp := 0
var current_cat := "tabby"


func _ready() -> void:
	meta = SaveManager.load_meta(meta)


# ------------------------------ run lifecycle ------------------------------

func start_run(cat_id: String) -> void:
	current_cat = cat_id
	meta.selected_cat = cat_id
	meta.runs = int(meta.get("runs", 0)) + 1
	run_active = true
	run_time = 0.0
	kills = 0
	run_coins = 0
	score = 0
	bosses_beaten = 0
	level = 1
	xp = 0
	xp_changed.emit(xp, Balance.xp_to_next(level))
	kills_changed.emit(0)
	run_coins_changed.emit(0)


## Called by the arena when the run is over (death or timer + final boss).
func end_run(survived_sec: float) -> Dictionary:
	run_active = false
	var tier := bosses_beaten   # 0 = defeat, 1-3 = paw tiers
	var bonus: int = Balance.WIN_TIER_COIN_BONUS[mini(tier, 3)]
	var summary := {
		"cat": current_cat,
		"tier": tier,
		"tier_name": Balance.WIN_TIER_NAMES[mini(tier, 3)],
		"bosses_beaten": bosses_beaten,
		"kills": kills,
		"survived_sec": survived_sec,
		"coins": run_coins,
		"bonus": bonus,
		"score": score,
	}
	meta.coins += run_coins + bonus
	var best: Dictionary = meta.best.get(current_cat, {"tier": -1, "score": 0})
	if tier > int(best.tier) or (tier == int(best.tier) and score > int(best.score)):
		meta.best[current_cat] = {"tier": tier, "score": score}
		summary["new_best"] = true
	SaveManager.save_meta(meta)
	meta_coins_changed.emit(meta.coins)
	run_ended.emit(summary)
	return summary


# ------------------------------ run mutations ------------------------------

func add_run_time(delta: float) -> void:
	run_time += delta


func gain_xp(amount: int) -> void:
	xp += amount
	var needed := Balance.xp_to_next(level)
	while xp >= needed:
		xp -= needed
		level += 1
		leveled_up.emit(level)
		needed = Balance.xp_to_next(level)
	xp_changed.emit(xp, needed)


func add_kill(coins: int, kill_score: int) -> void:
	kills += 1
	kills_changed.emit(kills)
	score += kill_score
	if coins > 0:
		add_run_coins(coins)


func add_run_coins(amount: int) -> void:
	run_coins += int(round(amount * Balance.kill_coin_scale(run_time)))
	run_coins_changed.emit(run_coins)


func notify_boss_defeated(boss_id: String) -> void:
	bosses_beaten += 1
	var def: Dictionary = Balance.BOSSES[boss_id]
	score += int(def.score)
	add_run_coins(int(def.coins))
	boss_defeated.emit(boss_id, bosses_beaten)


func report_player_hp(hp: int, max_hp: int) -> void:
	player_hp_changed.emit(hp, max_hp)


# ------------------------------ meta / shop --------------------------------

func upgrade_tier(upgrade_id: String) -> int:
	return int(meta.upgrades.get(upgrade_id, 0))


func can_afford_upgrade(upgrade_id: String) -> bool:
	var tier := upgrade_tier(upgrade_id)
	var def: Dictionary = Balance.SHOP_UPGRADES[upgrade_id]
	return tier < int(def.max_tiers) and meta.coins >= Balance.shop_cost(upgrade_id, tier)


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_afford_upgrade(upgrade_id):
		return false
	meta.coins -= Balance.shop_cost(upgrade_id, upgrade_tier(upgrade_id))
	meta.upgrades[upgrade_id] = upgrade_tier(upgrade_id) + 1
	SaveManager.save_meta(meta)
	meta_coins_changed.emit(meta.coins)
	return true


func is_cat_unlocked(cat_id: String) -> bool:
	return cat_id in meta.unlocked_cats


func buy_cat(cat_id: String) -> bool:
	var cost := int(Balance.CATS[cat_id].unlock_cost)
	if is_cat_unlocked(cat_id) or meta.coins < cost:
		return false
	meta.coins -= cost
	meta.unlocked_cats.append(cat_id)
	SaveManager.save_meta(meta)
	meta_coins_changed.emit(meta.coins)
	return true


## Aggregated permanent bonuses from purchased shop upgrades.
func meta_effects() -> Dictionary:
	var fx := {
		"max_hp": 0, "move_speed_mult": 0.0, "pickup_mult": 0.0,
		"damage_mult": 0.0, "luck": 0.0, "starting_weapon_level": 0, "revive": 0,
	}
	for id: String in meta.upgrades:
		var def: Dictionary = Balance.SHOP_UPGRADES[id]
		var effect: String = def.effect
		fx[effect] = fx[effect] + def.per_tier * int(meta.upgrades[id])
	return fx
