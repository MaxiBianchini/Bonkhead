extends CanvasLayer

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var typewriter_label = $TypewriterLabel
@onready var animation_player = $AnimationPlayer
@onready var continue_button: TextureButton = $ContinueButton
@onready var audio_click: AudioStreamPlayer2D = $AudioStreamPlayer


# ==============================================================================
# DATOS Y CONFIGURACIÓN DE LA HISTORIA
# ==============================================================================
var story_texts: Array[String] = [
	"The ink of chaos has finally settled. \nThe nightmare within the pages is over.", 
	"With the recovered cover, the artist's \nmasterpiece has reached its true conclusion.",
	"Reality returns as the artist wakes up at his desk, \nleaving behind the world of paper.",
	"The legend of Bonkhead is now written. \nThank you for completing the journey!"
]


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

func _ready() -> void:
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	continue_button.visible = false
	animation_player.play("IntroSequence")


# ==============================================================================
# LÓGICA DE CINEMÁTICA Y TEXTO
# ==============================================================================

func start_new_text(text_index: int) -> void:
	if text_index < story_texts.size():
		typewriter_label.start_typing(story_texts[text_index])
	else:
		typewriter_label.start_typing("")

func show_continue_button() -> void:
	typewriter_label.visible = false
	continue_button.visible = true


# ==============================================================================
# GESTIÓN DE ENTRADAS Y SEÑALES (INPUTS & EVENTS)
# ==============================================================================

# Función centralizada: Evalúa el estado de la cinemática y decide qué hacer.
func _advance_story() -> void:
	# 1. Reproduce el sonido de retroalimentación (variable que estaba sin uso)
	if audio_click: 
		audio_click.play()
		
	# 2. Omite el efecto de escritura si está en progreso
	if typewriter_label._is_typing:
		typewriter_label.skip()
		
	# 3. O salta al final de la animación si aún se está reproduciendo
	elif animation_player.is_playing():
		animation_player.seek(animation_player.get_current_animation_length(), true)
		
	# 4. Si la cinemática terminó y el botón ya está visible, sale de la escena
	elif continue_button.visible:
		ScenesTransitions.change_scene("res://Scenes/MainMenu.tscn")
		queue_free()

# Delega la pulsación de teclas/mando a la función central
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance_story()

# Delega el clic del ratón en la interfaz gráfica a la función central
func _on_continue_button_pressed() -> void:
	_advance_story()
