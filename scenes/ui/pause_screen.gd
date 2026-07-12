extends Control
## Pause overlay. Also triggered automatically when the window loses focus
## (web tab switch / phone lock).

signal restart_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(func() -> void:
		close()
		restart_requested.emit())
	%QuitButton.pressed.connect(func() -> void:
		close()
		quit_requested.emit())


func open() -> void:
	if visible:
		return
	get_tree().paused = true
	visible = true
	AudioManager.play_sfx("pause")


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
