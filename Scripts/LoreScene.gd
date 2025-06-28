# LoreScene.gd (modificado)
extends CanvasLayer

# --- Nodos de la Escena ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Actualizamos la referencia a nuestro nuevo componente.
@onready var typewriter_label: Label = $TypewriterLabel # Asegúrate que el nodo se llame así.
@onready var continue_button: TextureButton = $ContinueButton
@onready var audio_click: AudioStreamPlayer2D = $AudioStreamPlayer

# --- Textos de la Narración (sin cambios) ---
var story_texts: Array[String] = [
	"Para un artista, no hay nada como la presión de una fecha de entrega. 
	Noche tras noche, nuestro héroe trabajaba sin descanso...",
	"...dando vida a su más grande creación: 
		un cómic destinado a ser legendario.",
	"Pero hasta el lápiz más afilado necesita descansar. 
	Y en un parpadeo, el agotamiento ganó la batalla.",
	"Fue entonces cuando el mundo real se desvaneció, 
	y la tinta y el papel cobraron vida. 
	Despertó dentro de su propia creación...",
	"...pero algo andaba mal. Las páginas de su obra maestra 
	se habían esparcido por este nuevo y extraño mundo. 
	Su misión era clara: ¡recuperarlas todas!"
]

func _ready() -> void:
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	continue_button.visible = false
	
	animation_player.play("IntroSequence")

# Esta función será llamada por el AnimationPlayer. Ahora inicia el efecto de escritura.
func start_new_text(text_index: int) -> void:
	if text_index < story_texts.size():
		typewriter_label.start_typing(story_texts[text_index])
	else:
		typewriter_label.start_typing("") # Limpia el texto

# Esta función será llamada por el AnimationPlayer para mostrar el botón al final
func show_continue_button() -> void:
	continue_button.visible = true

func _on_continue_button_pressed() -> void:
	# Ahora, en lugar de saltar la animación, saltamos el efecto de tecleo.
	if typewriter_label._is_typing:
		typewriter_label.skip()
	elif animation_player.is_playing():
		# Si no está tecleando, saltamos al final de la animación de la escena.
		animation_player.seek(animation_player.get_current_animation_length(), true)
	else:
		# Si no hay nada que saltar, cambiamos de escena.
		ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")
		queue_free()

func _input(event: InputEvent) -> void:
	# La tecla 'Enter' o 'Espacio' ahora salta el efecto de tecleo.
	if event.is_action_pressed("ui_accept"):
		if typewriter_label._is_typing:
			typewriter_label.skip()
		elif animation_player.is_playing():
			animation_player.seek(animation_player.get_current_animation_length(), true)
