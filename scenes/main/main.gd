class_name Main
extends Node
## Root state machine: Title -> Cat Select / Cat Café -> Run -> Results.
## Screens cross-fade through a warm brown transition, never a hard cut.

const ARENA_SCENE := preload("res://scenes/run/arena.tscn")

@onready var title_screen: Control = $Screens/TitleScreen
@onready var cat_select: Control = $Screens/CatSelectScreen
@onready var shop_screen: Control = $Screens/ShopScreen
@onready var screens: CanvasLayer = $Screens
@onready var fade_rect: ColorRect = $TransitionLayer/Fade

var arena: Arena


func _ready() -> void:
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen.play_pressed.connect(func() -> void: _switch(cat_select))
	title_screen.shop_pressed.connect(func() -> void: _switch(shop_screen))
	cat_select.back_pressed.connect(func() -> void: _switch(title_screen))
	cat_select.cat_chosen.connect(_start_run)
	shop_screen.back_pressed.connect(func() -> void: _switch(title_screen))
	_show_only(title_screen)
	AudioManager.play_music("res://assets/audio/music/menu_loop.ogg")


func _switch(screen: Control) -> void:
	_fade(func() -> void: _show_only(screen))


func _show_only(screen: Control) -> void:
	for child in screens.get_children():
		if child is Control:
			child.visible = child == screen
	if screen != null and screen.has_method("refresh"):
		screen.refresh()


func _start_run(cat_id: String) -> void:
	GameData.meta.selected_cat = cat_id
	_fade(_spawn_arena)


func _spawn_arena() -> void:
	_show_only(null)   # hide all menu screens
	arena = ARENA_SCENE.instantiate()
	arena.run_finished.connect(_on_run_finished)
	add_child(arena)
	AudioManager.play_music("res://assets/audio/music/run_loop.ogg")


func _on_run_finished(action: String) -> void:
	_fade(_apply_run_finish.bind(action))


func _apply_run_finish(action: String) -> void:
	if arena != null:
		arena.queue_free()
		arena = null
	if action == "again":
		# Straight back in with the same cat - keep the flow state.
		_spawn_arena()
		return
	AudioManager.play_music("res://assets/audio/music/menu_loop.ogg")
	if action == "shop":
		_show_only(shop_screen)
	else:
		_show_only(title_screen)


func _fade(mid_action: Callable) -> void:
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.22)
	t.tween_callback(mid_action)
	t.tween_property(fade_rect, "modulate:a", 0.0, 0.28)
	t.tween_callback(func() -> void: fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)
