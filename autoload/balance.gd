extends Node
## Balance - EVERY tunable number in the game lives here. No magic numbers
## in gameplay scripts, ever. See the balance table at the bottom for the
## reasoning behind the key numbers.
##
## Display names and flavor text live next to the stats on purpose: an
## entry isn't "done" until it has both numbers and personality.

# ============================== RUN STRUCTURE ==============================

const RUN_LENGTH_SEC := 900.0                 # 15:00
const BOSS_TIMES_SEC: Array[float] = [300.0, 600.0, 900.0]

# Win tiers (index = bosses beaten). 0 bosses + death = Defeat.
const WIN_TIER_NAMES: Array[String] = ["Defeat", "Bronze Paw", "Silver Paw", "Golden Paw"]
const WIN_TIER_COIN_BONUS: Array[int] = [0, 50, 120, 300]

# =============================== PLAYER CATS ===============================

const CATS := {
	"tabby": {
		"display_name": "Biscuit",
		"tagline": "A perfectly balanced breakfast cat.",
		"max_hp": 6,
		"move_speed": 85.0,
		"pickup_radius": 30.0,
		"starting_weapon": "hairball",
		"unlock_cost": 0,
		"sprite_dir": "res://assets/sprites/cats/tabby",
	},
	"chonk": {
		"display_name": "Meatloaf",
		"tagline": "Absolute unit. Slow to anger. Slow to everything.",
		"max_hp": 9,
		"move_speed": 65.0,
		"pickup_radius": 30.0,
		"starting_weapon": "claw_swipe",
		"unlock_cost": 300,
		"sprite_dir": "res://assets/sprites/cats/chonk",
	},
	"kitten": {
		"display_name": "Pip",
		"tagline": "90% zoomies, 10% cat.",
		"max_hp": 4,
		"move_speed": 108.0,
		"pickup_radius": 36.0,
		"starting_weapon": "laser_pointer",
		"unlock_cost": 500,
		"sprite_dir": "res://assets/sprites/cats/kitten",
	},
}

const PLAYER_IFRAMES_SEC := 0.9
const PLAYER_CONTACT_RADIUS := 14.0        # world px around player for enemy contact
const SNACK_EAT_RADIUS := 10.0             # snack is eaten inside this distance
const SNACK_MAGNET_SPEED := 240.0

# ================================= WEAPONS =================================
# Levels index 0 = level 1. Max 5 levels. See DPS parity table below.
# "upgrade_text" is what the level-up card shows for that level.

const MAX_WEAPONS := 6
const MAX_PASSIVES := 6

const WEAPONS := {
	"hairball": {
		"display_name": "Hairball Hurl",
		"flavor": "A time-honored feline greeting.",
		"icon": "res://assets/sprites/fx/hairball.png",
		"levels": [
			{"damage": 8, "cooldown": 0.90, "count": 1, "speed": 260.0, "pierce": 0, "upgrade_text": "Ptooey!"},
			{"damage": 11, "cooldown": 0.90, "count": 1, "speed": 260.0, "pierce": 0, "upgrade_text": "+3 damage. Chunkier."},
			{"damage": 11, "cooldown": 0.80, "count": 2, "speed": 260.0, "pierce": 0, "upgrade_text": "Double hairball!"},
			{"damage": 13, "cooldown": 0.70, "count": 2, "speed": 280.0, "pierce": 1, "upgrade_text": "Pierces one extra critter."},
			{"damage": 16, "cooldown": 0.60, "count": 3, "speed": 300.0, "pierce": 1, "upgrade_text": "TRIPLE hairball. Vet is concerned."},
		],
	},
	"claw_swipe": {
		"display_name": "Claws Out",
		"flavor": "Snip snip.",
		"icon": "res://assets/sprites/fx/claw_swipe.png",
		"levels": [
			{"damage": 12, "cooldown": 1.10, "arc_deg": 100.0, "range": 46.0, "knockback": 90.0, "upgrade_text": "The classic."},
			{"damage": 15, "cooldown": 1.00, "arc_deg": 110.0, "range": 50.0, "knockback": 100.0, "upgrade_text": "+3 damage, wider swipe."},
			{"damage": 18, "cooldown": 0.95, "arc_deg": 120.0, "range": 54.0, "knockback": 110.0, "upgrade_text": "Freshly sharpened."},
			{"damage": 21, "cooldown": 0.88, "arc_deg": 130.0, "range": 58.0, "knockback": 120.0, "upgrade_text": "Now with follow-through."},
			{"damage": 25, "cooldown": 0.80, "arc_deg": 145.0, "range": 64.0, "knockback": 140.0, "upgrade_text": "The couch remembers."},
		],
	},
	"laser_pointer": {
		"display_name": "Red Dot of Doom",
		"flavor": "You'll never catch it. They might.",
		"icon": "res://assets/sprites/fx/laser_dot.png",
		"levels": [
			{"damage": 3, "tick": 0.30, "count": 1, "orbit_radius": 58.0, "orbit_speed": 3.2, "dot_radius": 14.0, "upgrade_text": "Chase-proof damage."},
			{"damage": 4, "tick": 0.28, "count": 1, "orbit_radius": 60.0, "orbit_speed": 3.4, "dot_radius": 15.0, "upgrade_text": "+1 damage per zap."},
			{"damage": 4, "tick": 0.26, "count": 2, "orbit_radius": 62.0, "orbit_speed": 3.6, "dot_radius": 15.0, "upgrade_text": "A second dot appears!"},
			{"damage": 5, "tick": 0.24, "count": 2, "orbit_radius": 66.0, "orbit_speed": 3.8, "dot_radius": 16.0, "upgrade_text": "Faster, angrier dots."},
			{"damage": 6, "tick": 0.22, "count": 3, "orbit_radius": 70.0, "orbit_speed": 4.0, "dot_radius": 17.0, "upgrade_text": "Three dots. Utter chaos."},
		],
	},
	"thrown_fish": {
		"display_name": "Boomerfish",
		"flavor": "It always comes back. Fish are loyal.",
		"icon": "res://assets/sprites/fx/thrown_fish.png",
		"levels": [
			{"damage": 10, "cooldown": 1.60, "count": 1, "speed": 220.0, "range": 150.0, "upgrade_text": "Catch and release."},
			{"damage": 13, "cooldown": 1.50, "count": 1, "speed": 230.0, "range": 160.0, "upgrade_text": "+3 damage. Fresher fish."},
			{"damage": 15, "cooldown": 1.40, "count": 1, "speed": 240.0, "range": 175.0, "upgrade_text": "Flies further."},
			{"damage": 17, "cooldown": 1.30, "count": 2, "speed": 250.0, "range": 185.0, "upgrade_text": "Two fish! Twice the loyalty."},
			{"damage": 21, "cooldown": 1.15, "count": 2, "speed": 265.0, "range": 200.0, "upgrade_text": "Premium sashimi grade."},
		],
	},
	"meow_shockwave": {
		"display_name": "Sonic Meow",
		"flavor": "The 3 AM special.",
		"icon": "res://assets/sprites/fx/meow_ring.png",
		"levels": [
			{"damage": 9, "cooldown": 2.20, "radius": 90.0, "knockback": 130.0, "upgrade_text": "MEOW."},
			{"damage": 11, "cooldown": 2.05, "radius": 102.0, "knockback": 140.0, "upgrade_text": "MEOW!"},
			{"damage": 13, "cooldown": 1.90, "radius": 114.0, "knockback": 155.0, "upgrade_text": "MEOOOW!"},
			{"damage": 15, "cooldown": 1.75, "radius": 128.0, "knockback": 170.0, "upgrade_text": "The neighbors called."},
			{"damage": 18, "cooldown": 1.55, "radius": 145.0, "knockback": 190.0, "upgrade_text": "Heard three houses down."},
		],
	},
}

# ================================= PASSIVES ================================

const PASSIVES := {
	"milk": {
		"display_name": "Warm Milk",
		"flavor": "Soothes the soul, mends the fur.",
		"icon": "res://assets/sprites/snacks/milk.png",
		"max_level": 3,
		"heal_interval": [30.0, 24.0, 18.0],   # seconds per 1 HP regen
		"upgrade_text": ["Regenerate 1 HP every 30s.", "Faster refills: every 24s.", "Bottomless saucer: every 18s."],
	},
	"catnip": {
		"display_name": "Premium Catnip",
		"flavor": "Locally sourced. Extremely legal.",
		"icon": "res://assets/sprites/fx/catnip.png",
		"max_level": 5,
		"damage_mult_per_level": 0.10,
		"upgrade_text": ["+10% damage.", "+20% damage.", "+30% damage.", "+40% damage.", "+50% damage. Sees sounds."],
	},
	"collar": {
		"display_name": "Zoomies Collar",
		"flavor": "Unleashes the 2 AM energy.",
		"icon": "res://assets/sprites/fx/collar.png",
		"max_level": 4,
		"speed_mult_per_level": 0.08,
		"upgrade_text": ["+8% move speed.", "+16% move speed.", "+24% move speed.", "+32% move speed. Wheee!"],
	},
	"bigger_bowl": {
		"display_name": "The Bigger Bowl",
		"flavor": "If it fits, it sits... in your stomach.",
		"icon": "res://assets/sprites/fx/bowl.png",
		"max_level": 4,
		"pickup_mult_per_level": 0.25,
		"upgrade_text": ["+25% snack magnet range.", "+50% range.", "+75% range.", "+100% range. Gravitational."],
	},
	"nine_lives": {
		"display_name": "Ninth Life",
		"flavor": "Turns out you had one more.",
		"icon": "res://assets/sprites/fx/nine_lives.png",
		"max_level": 1,
		"upgrade_text": ["Revive once with half HP."],
	},
	"lucky_paw": {
		"display_name": "Lucky Paw",
		"flavor": "Always lands on someone's feet.",
		"icon": "res://assets/sprites/fx/lucky_paw.png",
		"max_level": 3,
		"luck_per_level": 1.0,
		"upgrade_text": ["Better level-up choices.", "Even better choices.", "The cards fear you."],
	},
}

# ================================== XP =====================================

## XP needed to go from `level` to `level + 1`.
## ~4-6s per level early, slowing to ~35-45s by level 20.
func xp_to_next(level: int) -> int:
	return int(5.0 + 3.0 * (level - 1) + pow(maxf(0.0, level - 1), 1.7))


const SNACK_XP := {
	"cookie": 1,
	"fish": 3,
	"sushi": 8,
	"golden_cookie": 25,
}
const MILK_HEAL := 2
const COIN_SNACK_VALUE := 3

# Rare bonus drop rates (rolled on enemy death, after the guaranteed snack).
const DROP_MILK_CHANCE := 0.008
const DROP_COIN_CHANCE := 0.04
const DROP_GOLDEN_COOKIE_CHANCE := 0.002   # small delight: rare golden snack
const DROP_VACUUM_CHANCE := 0.003          # magnets every snack on screen

# ================================= ENEMIES =================================
# Threat-proportional: tougher/scarier = more XP + coins (see table below).
# hp/damage get multiplied by difficulty_scalar(t); speed does not.

const ENEMIES := {
	"mouse": {
		"display_name": "Squeakster",
		"flavor": "It's not even scared of you.",
		"behavior": "swarmer", "hp": 6.0, "speed": 72.0, "damage": 1,
		"drop": "cookie", "coins": 0, "contact_radius": 8.0, "score": 10,
		"sprite_dir": "res://assets/sprites/enemies/mouse", "tier": "A",
	},
	"bee": {
		"display_name": "Buzzness Bee",
		"flavor": "All buzz, no appointment.",
		"behavior": "swarmer_wave", "hp": 4.0, "speed": 95.0, "damage": 1,
		"drop": "cookie", "coins": 0, "contact_radius": 8.0, "score": 12,
		"sprite_dir": "res://assets/sprites/enemies/bee", "tier": "A",
	},
	"dog": {
		"display_name": "Borkley",
		"flavor": "Just wants to play. Forever. With your bones.",
		"behavior": "chaser", "hp": 18.0, "speed": 55.0, "damage": 1,
		"drop": "fish", "coins": 1, "contact_radius": 11.0, "score": 25,
		"sprite_dir": "res://assets/sprites/enemies/dog", "tier": "A",
	},
	"raccoon": {
		"display_name": "Trash Bandit",
		"flavor": "Washes its paws of all wrongdoing.",
		"behavior": "chaser_erratic", "hp": 14.0, "speed": 78.0, "damage": 1,
		"drop": "fish", "coins": 1, "contact_radius": 10.0, "score": 25,
		"sprite_dir": "res://assets/sprites/enemies/raccoon", "tier": "B",
	},
	"roomba": {
		"display_name": "Sir Sucksalot",
		"flavor": "Knight of the Round Rug.",
		"behavior": "tank", "hp": 60.0, "speed": 30.0, "damage": 2,
		"drop": "fish", "coins": 2, "contact_radius": 13.0, "score": 50,
		"sprite_dir": "res://assets/sprites/enemies/roomba", "tier": "B",
	},
	"rival_cat": {
		"display_name": "Le Chat Noir",
		"flavor": "Hates you specifically, and with style.",
		"behavior": "dasher", "hp": 22.0, "speed": 60.0, "damage": 2,
		"dash_speed": 240.0, "dash_windup": 0.6, "dash_time": 0.45, "dash_cooldown": 2.6,
		"drop": "sushi", "coins": 2, "contact_radius": 10.0, "score": 60,
		"sprite_dir": "res://assets/sprites/enemies/rival_cat", "tier": "B",
	},
	"crow": {
		"display_name": "Corvin the Bold",
		"flavor": "Remembers your face. Holds grudges.",
		"behavior": "dasher", "hp": 10.0, "speed": 70.0, "damage": 1,
		"dash_speed": 280.0, "dash_windup": 0.5, "dash_time": 0.4, "dash_cooldown": 2.2,
		"drop": "cookie", "coins": 1, "contact_radius": 9.0, "score": 35,
		"sprite_dir": "res://assets/sprites/enemies/crow", "tier": "C",
	},
	"dust_bunny": {
		"display_name": "Dust Bunny",
		"flavor": "Multiplies when disciplined, like all chores.",
		"behavior": "chaser", "hp": 16.0, "speed": 62.0, "damage": 1,
		"split_into": "dust_mini", "split_count": [2, 3],
		"drop": "fish", "coins": 1, "contact_radius": 10.0, "score": 40,
		"sprite_dir": "res://assets/sprites/enemies/dust_bunny", "tier": "C",
	},
	"dust_mini": {
		"display_name": "Dustlet",
		"flavor": "The chore continues.",
		"behavior": "swarmer", "hp": 5.0, "speed": 80.0, "damage": 1,
		"drop": "cookie", "coins": 0, "contact_radius": 7.0, "score": 8,
		"sprite_dir": "res://assets/sprites/enemies/dust_bunny", "sprite_scale": 0.6,
		"tier": "none",   # never spawned by the director, only by splitting
	},
	"sprinkler": {
		"display_name": "Sprinky",
		"flavor": "Every cat's mortal enemy: scheduled water.",
		"behavior": "ranged", "hp": 30.0, "speed": 16.0, "damage": 1,
		"projectile_damage": 2, "projectile_speed": 120.0, "shoot_interval": 2.4, "keep_distance": 170.0,
		"drop": "sushi", "coins": 2, "contact_radius": 11.0, "score": 55,
		"sprite_dir": "res://assets/sprites/enemies/sprinkler", "tier": "C",
	},
}

# Elites: runtime tint + scale, no extra art.
const ELITE_HP_MULT := 3.0
const ELITE_DAMAGE_MULT := 2.0
const ELITE_SCALE := 1.35
const ELITE_COIN_BONUS := 4
const ELITE_SCORE_MULT := 3.0
const ELITE_TINT := Color(1.25, 0.85, 1.25)   # violet-ish sheen

# ============================ DIFFICULTY / DIRECTOR ========================
# The roguelite gate: a fresh cat should die somewhere in minutes 4-8.
# Formula: stepped scalar, +6% enemy hp/damage every 30s -> x2.74 at 15:00.

func difficulty_scalar(t: float) -> float:
	return 1.0 + 0.06 * floorf(t / 30.0)


## Seconds between spawn ticks (each tick spawns a pack, see pack_size).
func spawn_interval(t: float) -> float:
	return lerpf(1.7, 0.30, clampf(t / RUN_LENGTH_SEC, 0.0, 1.0))


## How many enemies a single spawn tick emits.
func pack_size(t: float) -> int:
	return 1 + int(t / 150.0)   # 1 early -> 7 at 15:00


## Hard cap of simultaneously alive enemies (pooling keeps this smooth).
func max_alive(t: float) -> int:
	return int(lerpf(24.0, 330.0, clampf(t / RUN_LENGTH_SEC, 0.0, 1.0)))


func elite_chance(t: float) -> float:
	if t < 120.0:
		return 0.0
	return lerpf(0.01, 0.14, clampf((t - 120.0) / (RUN_LENGTH_SEC - 120.0), 0.0, 1.0))


# Enemy tier unlock times (sec) and spawn weights while a tier is active.
const TIER_UNLOCK := {"A": 0.0, "B": 180.0, "C": 360.0, "D": 600.0}

## Spawn weight tables per unlocked tier phase. Tier D = "everything, dense".
const SPAWN_WEIGHTS := {
	"A": {"mouse": 6.0, "bee": 3.0, "dog": 3.0},
	"B": {"mouse": 5.0, "bee": 3.0, "dog": 4.0, "raccoon": 3.0, "roomba": 1.5, "rival_cat": 1.0},
	"C": {"mouse": 4.0, "bee": 3.0, "dog": 3.0, "raccoon": 3.0, "roomba": 2.0, "rival_cat": 1.5, "crow": 2.0, "dust_bunny": 2.0, "sprinkler": 1.0},
	"D": {"mouse": 5.0, "bee": 4.0, "dog": 3.0, "raccoon": 3.0, "roomba": 2.5, "rival_cat": 2.5, "crow": 2.5, "dust_bunny": 2.5, "sprinkler": 1.5},
}

# Surges: short bursts of extra spawns with breathers between.
const SURGE_INTERVAL_SEC := 75.0        # a surge roughly every 75s
const SURGE_DURATION_SEC := 12.0
const SURGE_RATE_MULT := 3.0            # spawn interval divided by this
const PINCER_CHANCE := 0.4              # surge comes from 2 opposite edges

const SPAWN_MARGIN := 60.0              # px outside the visible edge

# ================================= BOSSES ==================================

const BOSSES := {
	"boss_bulldog": {
		"display_name": "Big Chompus",
		"flavor": "The yard is HIS. The street is HIS. You are trespassing.",
		"intro_line": "A very good boy. For someone else.",
		"hp": 900.0, "speed": 45.0, "damage": 2, "contact_radius": 26.0,
		"charge_speed": 300.0, "charge_windup": 0.9, "charge_time": 0.8, "charge_cooldown": 3.5,
		"coins": 25, "score": 1000, "snacks": ["sushi", "sushi", "fish", "fish", "milk"],
		"sprite_dir": "res://assets/sprites/bosses/bulldog",
	},
	"boss_vacuum": {
		"display_name": "VAC-U-TRON 9000",
		"flavor": "Firmware update 6.66 installed successfully.",
		"intro_line": "*aggressive whirring*",
		"hp": 1900.0, "speed": 38.0, "damage": 2, "contact_radius": 30.0,
		"summon_interval": 6.0, "summon_type": "roomba", "summon_count": 2,
		"suck_interval": 9.0, "suck_duration": 2.5, "suck_pull": 140.0,
		"coins": 60, "score": 2500, "snacks": ["sushi", "sushi", "sushi", "fish", "milk"],
		"sprite_dir": "res://assets/sprites/bosses/vacuum",
	},
	"boss_fatcat": {
		"display_name": "The Fatriarch",
		"flavor": "Godfather of the food bowl. You ate from HIS dish.",
		"intro_line": "You come to my arena, on the day of my nap...",
		"hp": 3400.0, "speed": 42.0, "damage": 3, "contact_radius": 30.0,
		"charge_speed": 260.0, "charge_windup": 1.0, "charge_time": 0.9, "charge_cooldown": 4.0,
		"phase2_hp_frac": 0.5, "phase2_speed_mult": 1.4, "phase2_summon": "rival_cat",
		"coins": 150, "score": 6000, "snacks": ["sushi", "sushi", "sushi", "sushi", "milk", "golden_cookie"],
		"sprite_dir": "res://assets/sprites/bosses/fatcat",
	},
}
const BOSS_HP_META_SCALE := 1.0   # hook: scale boss hp if meta makes runs too easy

# =============================== META / SHOP ===============================
# Escalating costs: cost(tier) = base * growth^tier, rounded to 5.

const SHOP_UPGRADES := {
	"whisker_vitality": {
		"icon": "res://assets/sprites/ui/cupcake.png",
		"display_name": "Whisker Vitality",
		"flavor": "Eat your greens. And the mice.",
		"max_tiers": 5, "base_cost": 40, "cost_growth": 1.6,
		"effect": "max_hp", "per_tier": 1,
	},
	"toe_beans": {
		"icon": "res://assets/sprites/ui/toe_beans.png",
		"display_name": "Turbo Toe Beans",
		"flavor": "Freshly kneaded.",
		"max_tiers": 5, "base_cost": 50, "cost_growth": 1.6,
		"effect": "move_speed_mult", "per_tier": 0.05,
	},
	"long_whiskers": {
		"icon": "res://assets/sprites/ui/whisker.png",
		"display_name": "Longer Whiskers",
		"flavor": "Sense snacks from another room.",
		"max_tiers": 5, "base_cost": 45, "cost_growth": 1.6,
		"effect": "pickup_mult", "per_tier": 0.15,
	},
	"sharp_claws": {
		"icon": "res://assets/sprites/fx/claw_swipe.png",
		"display_name": "Salon Claws",
		"flavor": "Buffed, polished, lethal.",
		"max_tiers": 5, "base_cost": 60, "cost_growth": 1.65,
		"effect": "damage_mult", "per_tier": 0.06,
	},
	"lucky_bell": {
		"icon": "res://assets/sprites/ui/bell.png",
		"display_name": "Lucky Bell",
		"flavor": "Jingle responsibly.",
		"max_tiers": 3, "base_cost": 80, "cost_growth": 1.8,
		"effect": "luck", "per_tier": 1.0,
	},
	"head_start": {
		"icon": "res://assets/sprites/ui/stretch.png",
		"display_name": "Warm-Up Stretches",
		"flavor": "Start the day one level of smug higher.",
		"max_tiers": 3, "base_cost": 100, "cost_growth": 1.9,
		"effect": "starting_weapon_level", "per_tier": 1,
	},
	"spare_life": {
		"icon": "res://assets/sprites/ui/catnap.png",
		"display_name": "Emergency Catnap",
		"flavor": "Death is just a nap you weren't planning.",
		"max_tiers": 1, "base_cost": 400, "cost_growth": 1.0,
		"effect": "revive", "per_tier": 1,
	},
}


func shop_cost(upgrade_id: String, tier: int) -> int:
	var def: Dictionary = SHOP_UPGRADES[upgrade_id]
	var raw := float(def.base_cost) * pow(def.cost_growth, tier)
	return int(round(raw / 5.0) * 5.0)


# Kill coins get a small time bonus so late-run kills matter more.
func kill_coin_scale(t: float) -> float:
	return 1.0 + t / RUN_LENGTH_SEC


# ============================ LEVEL-UP CARDS ===============================

const CARDS_PER_LEVEL_UP := 3
## Luck: each point of luck adds one extra weighted re-roll that keeps the
## rarer/higher-value option. Simple, tunable, explainable.

# ================================ BALANCE TABLE ============================
# Weapon DPS parity (single target, on paper):
#   hairball   L1  8/0.90 = 8.9      L5 3x16/0.60 = 26.7 (multi-shot spreads)
#   claw       L1 12/1.10 = 10.9     L5 25/0.80 = 31.2 (melee risk premium)
#   laser      L1  3/0.30 = 10.0     L5 3x 6/0.22 = 27.3 (unaimed, orbit RNG)
#   fish       L1 10/1.60 = 6.3x2hits= 12.5  L5 2x21/1.15 = 36.5x pierce (line AoE)
#   meow       L1  9/2.20 = 4.1xN targets    L5 18/1.55 = 11.6xN (pure AoE + CC)
#   Band: ~9-12 effective DPS at L1, ~27-37 at L5; AoE weapons trade
#   single-target DPS for crowd coverage. No dominant, no dead weapon.
# Enemy reward proportionality (threat -> xp drop + coins + score):
#   swarmers: cookie(1xp)+0c | chasers: fish(3xp)+1c | tank/dasher/ranged:
#   fish-sushi(3-8xp)+2c | elites: +4c, 3x score | bosses: 25/60/150c.
# Difficulty gate: at 5:00 scalar=1.6, fresh tabby DPS ~15-20 vs bulldog
#   900hp -> ~50-60s fight while hordes spawn: beatable with a decent build,
#   deadly if sloppy. At 15:00 scalar=2.74 + tier D density: needs meta.
#   Target: first Golden Paw after ~8-15 runs (tune scalar slope if off).
# ===========================================================================
