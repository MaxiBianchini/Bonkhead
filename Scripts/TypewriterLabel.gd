extends Label

signal typing_finished

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

func start_typing(text_to_type: String) -> void:
	_full_text = text_to_type
	_current_char_index = 0
	self.text = ""
	_is_typing = true
	
	if typing_speed > 0:
		timer.wait_time = 1.0 / typing_speed
		timer.start()
	else:
		skip()

func _on_timer_timeout() -> void:
	if _current_char_index < _full_text.length():
		var char_actual = _full_text[_current_char_index]
		
		self.text += char_actual
		_current_char_index += 1
		
		if audio_player.stream:
			if char_actual != " ":
				audio_player.pitch_scale = randf_range(0.9, 1.1)
				audio_player.play()
	else:
		_is_typing = false
		timer.stop()
		emit_signal("typing_finished")

func skip() -> void:
	if not _is_typing:
		return
		
	_is_typing = false
	timer.stop()
	self.text = _full_text
	emit_signal("typing_finished")
