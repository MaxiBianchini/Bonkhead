extends Node

# Referencias a nodos importantes
@onready var Button_background = $ButtonBackground
@onready var Option_Button = $VBoxContainer/OptionButton
@onready var Resume_Button = $VBoxContainer/ResumeButtom
@onready var MainMenu_Button = $VBoxContainer/MainMenuButton
@onready var Back_Button = $OptionsMenu/BackButtonContainer/BackButton

signal press_resume()
signal press_mainmenu()

func _ready() -> void: 
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	
	MainMenu_Button.pressed.connect(_on_mainmenu_pressed)
	Option_Button.pressed.connect(_on_options_pressed)
	Resume_Button.pressed.connect(_on_resume_pressed)
	Back_Button.pressed.connect(_on_back_pressed)

func _on_resume_pressed() -> void:
	emit_signal("press_resume")  
	queue_free()

func _on_mainmenu_pressed() -> void:
	emit_signal("press_mainmenu")  
	queue_free()

func _on_options_pressed():
	$VBoxContainer.hide()
	await animate_menu(true)
	$OptionsMenu.show()

func _on_back_pressed():
	$OptionsMenu.hide()
	await animate_menu(false)
	$VBoxContainer.show()

func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 190)
	var tween = create_tween()
	tween.tween_property(Button_background, "size", size, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(Button_background, "position", position, 0.5)
	await tween.finished

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) # Activa pantalla completa
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED) # Cambia a modo ventana
