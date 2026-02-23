extends CanvasLayer

# ==============================================================================
# REFERENCIAS A NODOS
# ==============================================================================
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var typewriter_label: Label = $TypewriterLabel
@onready var continue_button: TextureButton = $ContinueButton
@onready var audio_click: AudioStreamPlayer2D = $AudioStreamPlayer

# ==============================================================================
# DATOS Y VARIABLES DE ESTADO
# ==============================================================================
var story_texts: Array[String] = [
    "For an artist, there's nothing like the pressure of a deadline.
Night after night, our hero worked tirelessly...",
    "...bringing to life his greatest creation:
a comic book destined to be legendary.",
    "But even the sharpest pencil needs to rest.
And in the blink of an eye, exhaustion won the battle.",
    "That's when the real world faded away,
and the ink and paper came to life.
He awoke inside his own creation...",
    "...but something was wrong. The pages of his masterpiece
had been scattered across this new and strange world.
His mission was clear: recover them all!"
]

# ==============================================================================
# MÉTODOS NATIVOS DEL MOTOR
# ==============================================================================

func _ready() -> void:
	# Configuración inicial del cursor
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Preparación de la interfaz
	continue_button.visible = false
	
	# Inicio de la cinemática
	animation_player.play("IntroSequence")


func _input(event: InputEvent) -> void:
	# Permitir saltar animaciones y texto con la acción 'ui_accept' (ej. Enter, Espacio)
	if event.is_action_pressed("ui_accept"):
		if typewriter_label._is_typing:
			typewriter_label.skip()
		elif animation_player.is_playing():
			animation_player.seek(animation_player.get_current_animation_length(), true)

# ==============================================================================
# MÉTODOS PÚBLICOS (LÓGICA DEL JUEGO)
# ==============================================================================

func start_new_text(text_index: int) -> void:
	# Inicia la escritura del texto si el índice es válido; de lo contrario, lo limpia
	if text_index < story_texts.size():
		typewriter_label.start_typing(story_texts[text_index])
	else:
		typewriter_label.start_typing("")


func show_continue_button() -> void:
	# Transición en la UI: Oculta el texto y muestra el botón para avanzar
	typewriter_label.visible = false
	continue_button.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ==============================================================================
# MANEJADORES DE SEÑALES
# ==============================================================================

func _on_continue_button_pressed() -> void:
	# Ocultar el cursor para mantener inmersión durante la transición
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# 1. Intentar saltar texto en progreso
	if typewriter_label._is_typing:
		typewriter_label.skip()
	# 2. Intentar saltar animación en progreso
	elif animation_player.is_playing():
		animation_player.seek(animation_player.get_current_animation_length(), true)
	# 3. Si no hay nada que saltar, ejecutar transición de escena
	else:
		ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")
		queue_free()
