extends Control
## Results screen: earned win tier (paws), stats, counting-up coins, and a
## NEW BEST stamp when deserved.

signal action(action_name: String)

const TIER_LINES := [
	"The horde sends its regards.",
	"One boss bonked. The cafe is proud.",
	"Two bosses down. Getting scary.",
	"FULL CLEAR. Absolute legend of the yard.",
]

const MEDALS := [
	"res://assets/sprites/ui/medal_bronze.png",
	"res://assets/sprites/ui/medal_silver.png",
	"res://assets/sprites/ui/medal_gold.png",
]

@onready var title_label: Label = %ResultTitle
@onready var paws_box: HBoxContainer = %Paws
@onready var flavor_label: Label = %FlavorLine
@onready var stats_label: Label = %Stats
@onready var coins_label: Label = %Coins
@onready var best_label: Label = %NewBest

var _coin_total := 0


func _ready() -> void:
	%AgainButton.pressed.connect(func() -> void: action.emit("again"))
	%CafeButton.pressed.connect(func() -> void: action.emit("shop"))
	%MenuButton.pressed.connect(func() -> void: action.emit("menu"))


func show_summary(summary: Dictionary) -> void:
	get_tree().paused = true
	visible = true
	for child in paws_box.get_children():
		child.queue_free()
	var tier := int(summary.tier)
	if tier > 0:
		title_label.text = "%s!" % summary.tier_name
		var medal: Texture2D = load(MEDALS[mini(tier, 3) - 1])
		for i in tier:
			var rect := TextureRect.new()
			rect.texture = medal
			rect.custom_minimum_size = Vector2(40, 40)
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			paws_box.add_child(rect)
		AudioManager.play_sfx("fanfare")
	else:
		title_label.text = "Defeat..."
	flavor_label.text = TIER_LINES[mini(tier, 3)]
	var minutes := int(summary.survived_sec) / 60
	var seconds := int(summary.survived_sec) % 60
	stats_label.text = "survived %02d:%02d    bonks %d    bosses %d" % [
		minutes, seconds, summary.kills, summary.bosses_beaten]
	best_label.visible = summary.get("new_best", false)
	_coin_total = int(summary.coins) + int(summary.bonus)
	coins_label.text = "0 Fish Coins"
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(_set_coins, 0, _coin_total, 1.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _set_coins(value: int) -> void:
	coins_label.text = "%d Fish Coins" % value
