extends Node

# Referencias a nodos importantes
@onready var pause_menu = $PauseMenu

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
	get_tree().paused = false  # Asegúrate de despausar antes de cambiar escena
	get_tree().change_scene("res://MenuPrincipal.tscn")

# Continuar el juego (ocultar el menú)
func _on_continue_pressed():
	toggle_pause_menu()
