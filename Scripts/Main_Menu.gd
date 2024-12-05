extends Control

# Conectamos las señales de los botones al script
@onready var Play_Button = $CanvasLayer/ButtonsContainer/PlayButton
@onready var Option_Button = $CanvasLayer/ButtonsContainer/OptionButton
@onready var Credit_Button = $CanvasLayer/ButtonsContainer/CreditButton
@onready var Exit_Button = $CanvasLayer/ExitButton
@onready var Back_Button = $OthersMenu/BackButtonContainer/BackButton

func _ready():
	Play_Button.connect("pressed", Callable(self, "_on_start_game_pressed"))
	Option_Button.connect("pressed", Callable(self, "_on_options_pressed"))
	Credit_Button.connect("pressed", Callable(self, "_on_credits_pressed"))
	Exit_Button.connect("pressed", Callable(self, "_on_exit_pressed"))
	Back_Button.connect("pressed", Callable(self, "_on_back_pressed"))

# Funciones de los botones
func _on_start_game_pressed():
	print("Iniciar juego")
	# Cambia de escena o realiza alguna acción para iniciar el juego
	get_tree().change_scene_to_file("res://Scenes/Level_1.tscn")

func _on_options_pressed():
	print("Opciones")
	Exit_Button.hide()
	$CanvasLayer/ButtonsContainer.hide()
	$OthersMenu.show()
	$OthersMenu/Options.show()

func _on_credits_pressed():
	print("Creditos")
	Exit_Button.hide()
	$CanvasLayer/ButtonsContainer.hide()
	$OthersMenu.show()
	$OthersMenu/Credits.show()

func _on_back_pressed():
	print("Atras")
	Exit_Button.show()
	$CanvasLayer/ButtonsContainer.show()
	$OthersMenu.hide()
	$OthersMenu/Options.hide()
	$OthersMenu/Credits.hide()

func _on_exit_pressed():
	print("Salir")
	get_tree().quit()  # Cierra el juego

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) # Activa pantalla completa
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED) # Cambia a modo ventana
