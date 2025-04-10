extends Node

# Referencias a nodos importantes
@onready var button_background = $ButtonBackground
@onready var MainMenu_Button = $VBoxContainer/MainMenuButton
@onready var Option_Button = $VBoxContainer/OptionButton
@onready var Resume_Button = $VBoxContainer/ResumeButtom
@onready var Back_Button = $OptionsMenu/BackButtonContainer/BackButton


signal delete_pausemenu()
signal press_mainmenu()

var textura_cursor = preload("res://Graphics/GUI/Cursors/1.png")  # Reemplaza con la ruta de tu imagen

func _ready() -> void: 
	Input.set_custom_mouse_cursor(textura_cursor)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Ocultar el cursor
	
	MainMenu_Button.pressed.connect(_on_mainmenu_pressed)
	Option_Button.pressed.connect(_on_options_pressed)
	Resume_Button.pressed.connect(_on_resume_pressed)
	Back_Button.pressed.connect(_on_back_pressed)


func _on_resume_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	emit_signal("delete_pausemenu")  
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
	tween.tween_property(button_background, "size", size, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(button_background, "position", position, 0.5)
	await tween.finished


func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) # Activa pantalla completa
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED) # Cambia a modo ventana
