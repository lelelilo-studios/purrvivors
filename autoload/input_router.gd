extends Node
## InputRouter - adaptive input. One place answers "where does the player
## want to move?" regardless of device: keyboard (desktop) or the virtual
## joystick (touch). Also detects touch mode and surfaces focus loss so the
## game can auto-pause (required for web).

signal touch_mode_changed(enabled: bool)
signal app_focus_lost

var touch_mode := false
## Set every frame by VirtualJoystick while dragged; zero when released.
var joystick_vector := Vector2.ZERO


func _ready() -> void:
	touch_mode = DisplayServer.is_touchscreen_available()


func get_move_vector() -> Vector2:
	var kb := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if kb != Vector2.ZERO:
		return kb
	return joystick_vector.limit_length(1.0)


func _input(event: InputEvent) -> void:
	# Web can run on phones: flip into touch mode on the first real touch.
	if not touch_mode and event is InputEventScreenTouch:
		touch_mode = true
		touch_mode_changed.emit(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		app_focus_lost.emit()
