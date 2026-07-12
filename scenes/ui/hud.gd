extends MarginContainer
## In-run HUD: XP bar + level, hearts, run timer, Fish Coins, kills.
## Anchors + containers only; the virtual joystick lives here too.

signal pause_requested

const HEART_TEXTURE_PATH := "res://assets/sprites/fx/heart.png"
const COIN_TEXTURE_PATH := "res://assets/sprites/snacks/coin.png"

@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var hearts_box: HBoxContainer = %Hearts
@onready var timer_label: Label = %TimerLabel
@onready var coin_label: Label = %CoinLabel
@onready var coin_icon: TextureRect = %CoinIcon
@onready var kills_label: Label = %KillsLabel
@onready var announce_label: Label = %Announce

var _announce_tween: Tween

var _xp_target := 0.0
var _heart_texture: Texture2D
var _max_hp := 0
var _level_tween: Tween


func _ready() -> void:
	if ResourceLoader.exists(HEART_TEXTURE_PATH):
		_heart_texture = load(HEART_TEXTURE_PATH)
	if ResourceLoader.exists(COIN_TEXTURE_PATH):
		coin_icon.texture = load(COIN_TEXTURE_PATH)
	GameData.xp_changed.connect(_on_xp_changed)
	GameData.leveled_up.connect(_on_leveled_up)
	GameData.player_hp_changed.connect(_on_hp_changed)
	GameData.run_coins_changed.connect(_on_coins_changed)
	GameData.kills_changed.connect(_on_kills_changed)
	level_label.text = "Lv 1"
	xp_bar.max_value = Balance.xp_to_next(1)
	xp_bar.value = 0
	var pause_button: Button = %PauseButton
	pause_button.visible = InputRouter.touch_mode
	InputRouter.touch_mode_changed.connect(func(on: bool) -> void: pause_button.visible = on)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())


func _process(delta: float) -> void:
	var t: float = GameData.run_time
	timer_label.text = "%02d:%02d" % [int(t) / 60, int(t) % 60]
	# XP bar eases toward its target - reads juicier than snapping.
	xp_bar.value = lerpf(xp_bar.value, _xp_target, minf(1.0, 12.0 * delta))


func _on_xp_changed(xp: int, needed: int) -> void:
	if needed != int(xp_bar.max_value):
		xp_bar.max_value = needed
		xp_bar.value = 0
	_xp_target = xp


func _on_leveled_up(new_level: int) -> void:
	level_label.text = "Lv %d" % new_level
	if _level_tween != null:
		_level_tween.kill()
	level_label.pivot_offset = level_label.size / 2.0
	level_label.scale = Vector2.ONE * 1.5
	_level_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_level_tween.tween_property(level_label, "scale", Vector2.ONE, 0.35)


func _on_hp_changed(hp: int, max_hp: int) -> void:
	if max_hp != _max_hp:
		_max_hp = max_hp
		for child in hearts_box.get_children():
			child.queue_free()
		for i in max_hp:
			if _heart_texture != null:
				var heart := TextureRect.new()
				heart.texture = _heart_texture
				heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				heart.custom_minimum_size = Vector2(22, 22)
				hearts_box.add_child(heart)
	if _heart_texture != null:
		var hearts := hearts_box.get_children()
		for i in hearts.size():
			hearts[i].modulate = Color.WHITE if i < hp else Color(0.25, 0.15, 0.12, 0.6)
	else:
		# Until the heart icon lands: readable text, never a gray box.
		if hearts_box.get_child_count() == 0:
			hearts_box.add_child(Label.new())
		hearts_box.get_child(0).text = "HP %d/%d" % [hp, max_hp]


## Big center-screen callout: boss intros, enrages, defeats.
func announce(text: String) -> void:
	announce_label.text = text
	announce_label.pivot_offset = announce_label.size / 2.0
	if _announce_tween != null:
		_announce_tween.kill()
	announce_label.scale = Vector2.ONE * 0.8
	announce_label.modulate.a = 0.0
	_announce_tween = create_tween()
	_announce_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_announce_tween.tween_property(announce_label, "modulate:a", 1.0, 0.18)
	_announce_tween.parallel().tween_property(announce_label, "scale", Vector2.ONE, 0.3)
	_announce_tween.tween_interval(2.4)
	_announce_tween.tween_property(announce_label, "modulate:a", 0.0, 0.5)


func _on_coins_changed(amount: int) -> void:
	coin_label.text = str(amount)


func _on_kills_changed(kills: int) -> void:
	kills_label.text = str(kills)
