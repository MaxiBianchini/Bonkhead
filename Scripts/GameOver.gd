extends CanvasLayer

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2
@onready var play_again_button = $VBoxContainer/PlayButton
@onready var play_again_label = $VBoxContainer/PlayButton/Label

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

func set_checkpoint_mode(is_boss_level: bool):
	# Esperamos un frame para asegurar que los nodos estén listos si se llama en _ready
	if not is_inside_tree(): await ready
	
	if is_boss_level:
		# Opción A: Si cambias texto de un Label hijo
		if play_again_label: play_again_label.text = "RESTART
LEVEL"
	else:
		if play_again_label: play_again_label.text = "PLAY
AGAIN"
