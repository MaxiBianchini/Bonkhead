extends CanvasLayer
@onready var audio_click = $AudioStreamPlayer
@onready var timer = $Timer

func _ready() -> void:
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	timer.start(10.0) # Pasa automáticamente tras 10 segundos

func _on_continue_button_pressed() -> void:
	#audio_click.play()
	#await audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")
	queue_free()

func _on_timer_timeout() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")
	queue_free()

func _on_mouse_entered() -> void:
	pass
	#var audio_entered = $AudioStreamPlayer2
	#audio_entered.play()
	#await audio_entered.finished
