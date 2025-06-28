extends Label

# Señal que emitiremos cuando el texto termine de escribirse
signal typing_finished

# --- Variables Configurables desde el Editor ---
# Velocidad de escritura en caracteres por segundo.
@export var typing_speed: float = 20.0
# Sonido que se reproduce con cada letra. Puedes arrastrar un archivo .wav o .ogg aquí.
#@export var typing_sound: AudioStream

# --- Nodos Hijos ---
@onready var timer: Timer = $Timer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# --- Variables Internas ---
var _full_text: String = ""
var _current_char_index: int = 0
var _is_typing: bool = false

func _ready() -> void:
	# Conectamos la señal de timeout del timer a nuestra función de tecleo.
	timer.timeout.connect(_on_timer_timeout)
	
	# Asignamos el recurso de audio al reproductor.
	#if typing_sound:
	#	audio_player.stream = typing_sound

# Función principal para iniciar el efecto. La llamaremos desde LoreScene.
func start_typing(text_to_type: String) -> void:
	_full_text = text_to_type
	_current_char_index = 0
	self.text = "" # Limpiamos el texto actual.
	_is_typing = true
	
	# Configuramos el timer basado en la velocidad de tecleo y lo iniciamos.
	if typing_speed > 0:
		timer.wait_time = 1.0 / typing_speed
		timer.start()
	else:
		# Si la velocidad es 0 o negativa, muestra el texto de inmediato.
		skip()

# Esta función se ejecuta cada vez que el Timer llega a cero.
func _on_timer_timeout() -> void:
	if _current_char_index < _full_text.length():
		# Añadimos el siguiente caracter.
		self.text += _full_text[_current_char_index]
		_current_char_index += 1
		
		# Reproducimos el sonido si existe.
		if audio_player.stream:
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
