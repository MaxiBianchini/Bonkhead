extends Label

# ==============================================================================
# SEÑALES
# ==============================================================================
# Se emite cuando el efecto de escritura finaliza o es omitido
signal typing_finished


# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN)
# ==============================================================================
@export var typing_speed: float = 20.0
@export var typing_sound: AudioStream


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var timer: Timer = $Timer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


# ==============================================================================
# VARIABLES DE ESTADO INTERNO
# ==============================================================================
var _full_text: String = ""
var _current_char_index: int = 0
var _is_typing: bool = false


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del nodo al cargar la escena
func _ready() -> void:
	# Conexión dinámica de la señal del temporizador
	timer.timeout.connect(_on_timer_timeout)
	
	# Asigna el flujo de audio si se configuró desde el inspector
	if typing_sound:
		audio_player.stream = typing_sound


# ==============================================================================
# API PÚBLICA (MÉTODOS DE CONTROL)
# ==============================================================================

# Inicia la animación de la máquina de escribir con un nuevo texto
func start_typing(text_to_type: String) -> void:
	_full_text = text_to_type
	_current_char_index = 0
	self.text = ""
	_is_typing = true
	
	# Inicia el temporizador calculando el intervalo en base a la velocidad
	if typing_speed > 0:
		timer.wait_time = 1.0 / typing_speed
		timer.start()
	# Si la velocidad es 0 o negativa, muestra el texto de inmediato
	else:
		skip()

# Omite la animación y despliega la totalidad del texto al instante
func skip() -> void:
	# Cláusula de guarda: No hace nada si no hay una animación en curso
	if not _is_typing:
		return
		
	_is_typing = false
	timer.stop()
	self.text = _full_text
	emit_signal("typing_finished")


# ==============================================================================
# GESTIÓN DE SEÑALES (CALLBACKS INTERNOS)
# ==============================================================================

# Bucle principal de animación impulsado por el Timer
func _on_timer_timeout() -> void:
	# Verifica si aún quedan caracteres por escribir
	if _current_char_index < _full_text.length():
		var char_actual = _full_text[_current_char_index]
		
		# Agrega el nuevo carácter al Label
		self.text += char_actual
		_current_char_index += 1
		
		# Reproduce el sonido de tecleo con variación de tono, ignorando los espacios en blanco
		if audio_player.stream:
			if char_actual != " ":
				audio_player.pitch_scale = randf_range(0.9, 1.1)
				audio_player.play()
	else:
		# Finaliza el proceso cuando se alcanza la longitud máxima del texto
		_is_typing = false
		timer.stop()
		emit_signal("typing_finished")
