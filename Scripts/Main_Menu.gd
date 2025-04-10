extends Control

# Conectamos las señales de los botones al script
@onready var Play_Button = $CanvasLayer/ButtonsContainer/PlayButton
@onready var Option_Button = $CanvasLayer/ButtonsContainer/OptionButton
@onready var Credit_Button = $CanvasLayer/ButtonsContainer/CreditButton
@onready var Exit_Button = $CanvasLayer/ExitButton
@onready var Back_Button = $OthersMenu/BackButtonContainer/BackButton
@onready var button_background = $CanvasLayer/ButtonBackground

var textura_cursor = preload("res://Graphics/GUI/Cursors/1.png")  # Reemplaza con la ruta de tu imagen

func _ready():
	Input.set_custom_mouse_cursor(textura_cursor)
	
	# Conectamos las señales de los botones a sus respectivas funciones
	Play_Button.pressed.connect(_on_start_game_pressed)
	Option_Button.pressed.connect(_on_options_pressed)
	Credit_Button.pressed.connect(_on_credits_pressed)
	Exit_Button.pressed.connect(_on_exit_pressed)
	Back_Button.pressed.connect(_on_back_pressed)

# Inicia el juego cambiando a la escena del primer nivel
func _on_start_game_pressed():
	ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")

# Muestra el menú de opciones con una animación
func _on_options_pressed():
	show_main_menu(false)
	await animate_menu(true)
	show_other_menu(true)

# Muestra los créditos con la misma animación de menú
func _on_credits_pressed():
	show_main_menu(false)
	await animate_menu(true)
	show_other_menu(false)

# Regresa al menú principal desde cualquier menú secundario con animación
func _on_back_pressed():
	$OthersMenu.hide()
	$OthersMenu/Options.hide()
	$OthersMenu/Credits.hide()
	await animate_menu(false)
	show_main_menu(true)

# Cierra el juego
func _on_exit_pressed():
	get_tree().quit()

# Función para manejar la animación del menú, tomando un parámetro para determinar si es de entrada o salida
func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 305)
	var tween = create_tween()
	tween.tween_property(button_background, "size", size, 0.5)#.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(button_background, "position", position, 0.5)
	await tween.finished

# Centraliza la lógica para mostrar el otro menú
func show_other_menu(enter: bool):
	if enter:
		$OthersMenu/Options.show()
	else:
		$OthersMenu/Credits.show()
	$OthersMenu.show()

# Centraliza la lógica para mostrar u ocultar el menú principal
func show_main_menu(enter: bool):
	if enter:
		Exit_Button.show()
		$CanvasLayer/ButtonsContainer.show()
		$CanvasLayer/Label.show()
	else:
		$CanvasLayer/Label.hide()
		$CanvasLayer/ExitButton.hide()
		$CanvasLayer/ButtonsContainer.hide()

# Maneja el cambio entre modo pantalla completa y ventana
func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
