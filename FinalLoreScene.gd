extends CanvasLayer

@onready var typewriter_label = $TypewriterLabel # Tu nodo con script de tecleo
@onready var animation_player = $AnimationPlayer
@onready var continue_button: TextureButton = $ContinueButton
@onready var audio_click: AudioStreamPlayer2D = $AudioStreamPlayer # Ajustado a AudioStreamPlayer si es global

# --- Textos de la Narración Final (en Inglés) ---
var story_texts: Array[String] = [
	"The battle is over. The ink of the chaos has finally dried.",
	"With the final page recovered, the comic is finally complete.",
	"The artist wakes up to the morning light, 
holding his masterpiece in his hands.",
	"He survived his own creation... and Bonkhead is now a legend.",
	"Thank you for playing!"
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
