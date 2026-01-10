extends Label

signal typing_finished

# Velocidad de escritura en caracteres por segundo.
@export var typing_speed: float = 20.0

@export var typing_sound: AudioStream
@onready var timer: Timer = $Timer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _full_text: String = ""
var _current_char_index: int = 0
var _is_typing: bool = false

func _ready() -> void:
	
	timer.timeout.connect(_on_timer_timeout)
	
	if typing_sound:
		audio_player.stream = typing_sound

# Función principal para iniciar el efecto. Llamada desde LoreScene.
func start_typing(text_to_type: String) -> void:
	_full_text = text_to_type
	_current_char_index = 0
	self.text = "" # Limpia el texto actual.
	_is_typing = true
	
	# Configura el timer basado en la velocidad de tecleo y lo iniciamos.
	if typing_speed > 0:
		timer.wait_time = 1.0 / typing_speed
		timer.start()
	else:
		# Si la velocidad es 0 o negativa, muestra el texto de inmediato.
		skip()

func _on_timer_timeout() -> void:
	if _current_char_index < _full_text.length():
		# Obtenemos el caracter actual
		var char_actual = _full_text[_current_char_index]
		
		# Añadimos el caracter al texto
		self.text += char_actual
		_current_char_index += 1
		
		# --- AQUÍ ESTÁ LA MAGIA DEL SONIDO ---
		if audio_player.stream:
			# Solo reproducimos sonido si NO es un espacio (opcional, pero suena mejor)
			if char_actual != " ":
				# Variamos el tono entre 0.95 y 1.05 (un 5% arriba o abajo)
				audio_player.pitch_scale = randf_range(0.9, 1.1)
				audio_player.play()
	else:
		# Terminamos de escribir.
		_is_typing = false
		timer.stop()
		emit_signal("typing_finished")

# Función para saltar el efecto y mostrar todo el texto.
func skip() -> void:
	if not _is_typing:
		return
		
	_is_typing = false
	timer.stop()
	self.text = _full_text
	emit_signal("typing_finished")
