extends CanvasLayer

# ==============================================================================
# SEÑALES
# ==============================================================================
signal press_restartlevel()
signal press_mainmenu()


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
# --- Nodos de Audio ---
@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización de la pantalla (ej. Menú de Pausa o Game Over)
func _ready() -> void: 
	# Configura el cursor personalizado y lo hace visible para interactuar con los botones
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# ==============================================================================
# GESTIÓN DE EVENTOS DE INTERFAZ (BOTONES Y RATÓN)
# ==============================================================================

# Se dispara al hacer clic en el botón de reiniciar nivel
func _on_restartlevel_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	
	# Oculta el cursor del ratón para devolver el control limpio al juego
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	emit_signal("press_restartlevel")
	queue_free()

# Se dispara al hacer clic en el botón de ir al menú principal
func _on_mainmenu_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	
	# Mantiene el cursor visible ya que el menú principal requerirá clics
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	emit_signal("press_mainmenu")
	queue_free()

# Se dispara cuando el cursor del ratón pasa por encima de un botón (Hover)
func _on_mouse_entered() -> void:
	audio_entered.play()
