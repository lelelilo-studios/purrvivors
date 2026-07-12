extends Control
## End-of-run screen (interim version - the full themed Results screen with
## paw tiers arrives with the meta phase). Coins count up because juice.

@onready var title_label: Label = %ResultTitle
@onready var stats_label: Label = %Stats
@onready var coins_label: Label = %Coins
@onready var again_button: Button = %AgainButton

var _coin_total := 0


func _ready() -> void:
	again_button.pressed.connect(_restart)


func show_summary(summary: Dictionary) -> void:
	get_tree().paused = true
	visible = true
	if summary.tier > 0:
		title_label.text = "%s!" % summary.tier_name
	else:
		title_label.text = "Defeat..."
	var minutes := int(summary.survived_sec) / 60
	var seconds := int(summary.survived_sec) % 60
	stats_label.text = "survived %02d:%02d   bonks %d   bosses %d" % [
		minutes, seconds, summary.kills, summary.bosses_beaten]
	_coin_total = int(summary.coins) + int(summary.bonus)
	coins_label.text = "0"
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(_set_coins, 0, _coin_total, 1.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _set_coins(value: int) -> void:
	coins_label.text = "%d Fish Coins" % value


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
