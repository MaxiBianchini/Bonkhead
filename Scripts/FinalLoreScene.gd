extends CanvasLayer

@onready var typewriter_label = $TypewriterLabel # Tu nodo con script de tecleo
@onready var animation_player = $AnimationPlayer
@onready var continue_button: TextureButton = $ContinueButton
@onready var audio_click: AudioStreamPlayer2D = $AudioStreamPlayer # Ajustado a AudioStreamPlayer si es global

# --- Textos de la Narración Final (en Inglés) ---
var story_texts: Array[String] = [
	"The ink of chaos has finally settled. \nThe nightmare within the pages is over.", # Para Final_1 (Victoria)
	"With the recovered cover, the artist's \nmasterpiece has reached its true conclusion.", # Para Final_2 (Paz/Sueño)
	"Reality returns as the artist wakes up at his desk, \nleaving behind the world of paper.", # Para Final_3 (Despertar)
	"The legend of Bonkhead is now written. \nThank you for completing the journey!" # Para Final_4 (Celebración)
]

func _ready() -> void:
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	continue_button.visible = false
	
	# Asegúrate de que tu animación IntroSequence en esta escena 
	# maneje los tiempos para estas nuevas imágenes.
	animation_player.play("IntroSequence")

# Llamado por AnimationPlayer
func start_new_text(text_index: int) -> void:
	if text_index < story_texts.size():
		typewriter_label.start_typing(story_texts[text_index])
	else:
		typewriter_label.start_typing("")

# Llamado por AnimationPlayer al final de la secuencia
func show_continue_button() -> void:
	typewriter_label.visible = false
	continue_button.visible = true

func _on_continue_button_pressed() -> void:
	if typewriter_label._is_typing:
		typewriter_label.skip()
	elif animation_player.is_playing():
		animation_player.seek(animation_player.get_current_animation_length(), true)
	else:
		# AL FINAL: Volvemos al Menú Principal 
		ScenesTransitions.change_scene("res://Scenes/MainMenu.tscn")
		queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if typewriter_label._is_typing:
			typewriter_label.skip()
		elif animation_player.is_playing():
			animation_player.seek(animation_player.get_current_animation_length(), true)
