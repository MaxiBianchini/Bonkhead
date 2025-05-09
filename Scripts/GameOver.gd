extends CanvasLayer

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2

signal press_playagain()
signal press_mainmenu()

func _ready() -> void: 
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_playagain_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	emit_signal("press_playagain")
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
