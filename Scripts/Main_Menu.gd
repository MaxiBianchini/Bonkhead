extends Control

# Conectamos las señales de los botones al script
@onready var button1 = $CanvasLayer/VBoxContainer/PlayButton
@onready var button2 = $CanvasLayer/VBoxContainer/OptionButton
@onready var button3 = $CanvasLayer/VBoxContainer/CreditButton

func _ready():
	button1.connect("pressed", Callable(self, "_on_start_game_pressed"))
	button2.connect("pressed", Callable(self, "_on_options_pressed"))
	button3.connect("pressed", Callable(self, "_on_exit_pressed"))

# Funciones de los botones
func _on_start_game_pressed():
	print("Iniciar juego")
	# Cambia de escena o realiza alguna acción para iniciar el juego
	get_tree().change_scene_to_file("res://Scenes/Level_1.tscn")

func _on_options_pressed():
	print("Opciones")
	# Aquí puedes abrir una ventana de opciones o cambiar de escena
	get_tree().change_scene_to_file("res://Scenes/OptionsMenu.tscn")

func _on_exit_pressed():
	print("Creditos")
	# Aquí puedes abrir una ventana de creditos o cambiar de escena
	get_tree().change_scene_to_file("res://Scenes/CreditsMenu.tscn")
