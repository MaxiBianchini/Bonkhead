extends Node

# Referencias a nodos importantes
@onready var pause_menu = $PauseMenu

# Conectamos las señales de los botones al script
@onready var MainMenu_Button = $PauseMenu/VBoxContainer/MainMenuButton
@onready var Option_Button = $PauseMenu/VBoxContainer/OptionButton
@onready var Resume_Button = $PauseMenu/VBoxContainer/ResumeButtom
@onready var Back_Button = $OptionsMenu/BackButtonContainer/BackButton

func _ready() -> void:
	MainMenu_Button.connect("pressed", Callable(self, "_on_mainmenu_pressed"))
	Option_Button.connect("pressed", Callable(self, "_on_options_pressed"))
	Resume_Button.connect("pressed", Callable(self, "_on_resume_pressed"))
	Back_Button.connect("pressed", Callable(self, "_on_back_pressed"))

func _on_mainmenu_pressed():
	get_tree().paused = false  # Reanuda el juego
	# Cambia de escena o realiza alguna acción para iniciar el juego
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

func _on_options_pressed():
	$PauseMenu.hide()
	$OptionsMenu.show()

func _on_resume_pressed():
	pause_menu.hide()
	get_tree().paused = false  # Reanuda el juego

func _on_back_pressed():
	$PauseMenu.show()
	$OptionsMenu.hide()

# Método para manejar la pausa
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Detecta la tecla "Esc"
		toggle_pause_menu()

# Mostrar u ocultar el menú de pausa
func toggle_pause_menu():
	if pause_menu.visible:
		pause_menu.hide()
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
