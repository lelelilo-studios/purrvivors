extends Control
## Pause overlay. Also triggered automatically when the window loses focus
## (web tab switch / phone lock).

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_restart)


func open() -> void:
	if visible:
		return
	get_tree().paused = true
	visible = true
	AudioManager.play_sfx("pause")


func close() -> void:
	visible = false
	get_tree().paused = false


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
