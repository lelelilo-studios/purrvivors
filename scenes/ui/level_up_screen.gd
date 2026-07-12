extends Control
## Level-up! Pauses the run and deals in 3 upgrade cards one at a time.

signal option_chosen(option: Dictionary)

const CHEEKY_LINES := [
	"Snack-powered evolution!",
	"The cat grows stronger.",
	"Choose your treat-ment.",
	"A very good decision approaches.",
	"Paws and reflect.",
	"More power to the paw.",
]

@onready var subtitle: Label = %Subtitle
@onready var cards_box: HBoxContainer = %Cards


func present(options: Array[Dictionary]) -> void:
	get_tree().paused = true
	visible = true
	subtitle.text = CHEEKY_LINES.pick_random()
	if DevTools.auto_pick:
		var t := get_tree().create_timer(0.3, true)
		t.timeout.connect(_choose.bind(options[0]))
		return
	for child in cards_box.get_children():
		child.queue_free()
	for i in options.size():
		var card := _build_card(options[i])
		cards_box.add_child(card)
		card.pivot_offset = card.custom_minimum_size / 2.0
		card.scale = Vector2.ONE * 0.6
		card.modulate.a = 0.0
		var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_interval(0.08 + i * 0.12)
		t.tween_property(card, "modulate:a", 1.0, 0.12)
		t.parallel().tween_property(card, "scale", Vector2.ONE, 0.28) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _build_card(option: Dictionary) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"Card"
	card.custom_minimum_size = Vector2(184, 280)
	card.pressed.connect(_choose.bind(option))
	card.mouse_entered.connect(func() -> void:
		var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(card, "scale", Vector2.ONE * 1.04, 0.1))
	card.mouse_exited.connect(func() -> void:
		var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(card, "scale", Vector2.ONE, 0.1))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override(&"separation", 6)
	margin.add_child(vbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0, 52)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(option.icon):
		icon.texture = load(option.icon)
	vbox.add_child(icon)

	var title := Label.new()
	title.text = option.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var text := Label.new()
	text.text = option.text
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(text)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	var flavor := Label.new()
	flavor.text = option.flavor
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.modulate = Color(1, 1, 1, 0.55)
	flavor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(flavor)
	return card


func _choose(option: Dictionary) -> void:
	AudioManager.play_sfx("card_pick")
	visible = false
	get_tree().paused = false
	option_chosen.emit(option)
