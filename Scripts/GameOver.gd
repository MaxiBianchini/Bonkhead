extends CanvasLayer

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2
@onready var restart_level_button = $VBoxContainer/RestartLevelButton
@onready var restart_level_label = $VBoxContainer/RestartLevelButton/Label

signal press_restartlevel()
signal press_mainmenu()

func _ready() -> void: 
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restartlevel_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	emit_signal("press_restartlevel")
	queue_free()

func _on_mainmenu_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("press_mainmenu")
	queue_free()

func _on_mouse_entered() -> void:
	audio_entered.play()
	await audio_entered.finished
