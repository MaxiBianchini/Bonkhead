extends CanvasLayer

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2

@onready var Background = $Background

signal press_resume()
signal press_mainmenu()

func _ready() -> void: 
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	emit_signal("press_resume")  
	queue_free()

func _on_mainmenu_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	emit_signal("press_mainmenu")  
	queue_free()

func _on_options_pressed():
	audio_click.play()
	await  audio_click.finished
	$VBoxContainer.hide()
	await animate_menu(true)
	$OptionsMenu.show()

func _on_back_pressed():
	audio_click.play()
	await  audio_click.finished
	$OptionsMenu.hide()
	await animate_menu(false)
	$VBoxContainer.show()

func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 190)
	var tween = create_tween()
	tween.tween_property(Background, "size", size, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(Background, "position", position, 0.5)
	await tween.finished

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_mouse_entered() -> void:
	audio_entered.play()
	await audio_entered.finished
