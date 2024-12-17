extends Node

# Referencias a nodos importantes
@onready var pause_menu = $PauseMenu
@onready var button_background = $PauseMenu/ButtonBackground

# Conectamos las señales de los botones al script
@onready var MainMenu_Button = $PauseMenu/VBoxContainer/MainMenuButton
@onready var Option_Button = $PauseMenu/VBoxContainer/OptionButton
@onready var Resume_Button = $PauseMenu/VBoxContainer/ResumeButtom
@onready var Back_Button = $OptionsMenu/BackButtonContainer/BackButton

func _ready() -> void:#Play_Button.pressed.connect(_on_start_game_pressed)
	MainMenu_Button.pressed.connect(_on_mainmenu_pressed)
	Option_Button.pressed.connect(_on_options_pressed)
	Resume_Button.pressed.connect(_on_resume_pressed)
	Back_Button.pressed.connect(_on_back_pressed)

func _on_mainmenu_pressed():
	get_tree().paused = false  # Reanuda el juego
	# Cambia de escena o realiza alguna acción para iniciar el juego
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

# Función para manejar la animación del menú, tomando un parámetro para determinar si es de entrada o salida
func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 190)
	var tween = create_tween()
	tween.tween_property(button_background, "size", size, 0.5)#.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(button_background, "position", position, 0.5)
	await tween.finished

func _on_options_pressed():
	$PauseMenu/VBoxContainer.hide()
	await animate_menu(true)
	$OptionsMenu.show()

func _on_resume_pressed():
	pause_menu.hide()
	get_tree().paused = false  # Reanuda el juego

func _on_back_pressed():
	$OptionsMenu.hide()
	await animate_menu(false)
	$PauseMenu/VBoxContainer.show()

# Método para manejar la pausa 
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Detecta la tecla "Esc"
		toggle_pause_menu()

# Mostrar u ocultar el menú de pausa
func toggle_pause_menu():
	if pause_menu.visible:
		pause_menu.hide()
		_on_back_pressed()
		get_tree().paused = false  # Reanuda el juego
	else:
		pause_menu.show()
		get_tree().paused = true   # Pausa el juego

# Ir al menú principal (cambiar escena)
func _on_return_to_menu_pressed():
	get_tree().paused = false  # Reanuda el juego

# Continuar el juego (ocultar el menú)
func _on_continue_pressed():
	toggle_pause_menu()

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) # Activa pantalla completa
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED) # Cambia a modo ventana
