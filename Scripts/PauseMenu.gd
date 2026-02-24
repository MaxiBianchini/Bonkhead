extends CanvasLayer

# ==============================================================================
# SEÑALES
# ==============================================================================
signal press_resume()
signal press_mainmenu()


# ==============================================================================
# CONSTANTES GLOBALES
# ==============================================================================
# Nombres de los canales de audio en el AudioServer
const MASTER_BUS_NAME = "Master"
const MUSIC_BUS_NAME = "Music"
const SFX_BUS_NAME = "SFX"

# Ruta física donde se guardará la configuración del usuario
const SAVE_PATH = "user://settings.cfg"


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
# --- Audio ---
@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2

# --- Interfaz Visual ---
@onready var Background = $Background

# --- Controles de Volumen (Sliders) ---
@onready var master_slider: HSlider = $OptionsMenu/Options/HBoxContainer/Volumen/General/MasterSlider
@onready var music_slider: HSlider = $OptionsMenu/Options/HBoxContainer/Volumen/Music/MusicSlider
@onready var sfx_slider: HSlider = $OptionsMenu/Options/HBoxContainer/Volumen/SFX/SFXSlider


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Se ejecuta al instanciar el menú en la escena
func _ready() -> void: 
	# Recupera las preferencias guardadas del usuario
	load_settings()
	
	# Conecta las señales de los sliders a sus respectivas funciones dinámicamente
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Configura el cursor personalizado y lo hace visible para la navegación
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# ==============================================================================
# SISTEMA DE GUARDADO Y CONFIGURACIÓN DE AUDIO
# ==============================================================================

# Carga la configuración desde el disco y actualiza los sliders y volúmenes
func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	
	var master_vol = config.get_value("audio", "master_volume", 100)
	master_slider.value = master_vol
	set_bus_volume(MASTER_BUS_NAME, master_vol)
	
	var music_vol = config.get_value("audio", "music_volume", 100)
	music_slider.value = music_vol
	set_bus_volume(MUSIC_BUS_NAME, music_vol)
	
	var sfx_vol = config.get_value("audio", "sfx_volume", 100)
	sfx_slider.value = sfx_vol
	set_bus_volume(SFX_BUS_NAME, sfx_vol)

# Persiste los valores actuales de los sliders en un archivo físico
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save(SAVE_PATH)

# Convierte el valor lineal (0-100) a decibelios y lo aplica al bus correspondiente
func set_bus_volume(bus_name: String, value: float) -> void:
	if value == 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), -80)
	else:
		var db_volume = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db_volume)
		
	# Guarda automáticamente cada vez que se ajusta un volumen
	

func _on_master_volume_changed(value: float) -> void:
	set_bus_volume(MASTER_BUS_NAME, value)
	save_settings()

func _on_music_volume_changed(value: float) -> void:
	set_bus_volume(MUSIC_BUS_NAME, value)
	save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	set_bus_volume(SFX_BUS_NAME, value)
	save_settings()


# ==============================================================================
# NAVEGACIÓN DE INTERFAZ Y ANIMACIONES
# ==============================================================================

func _on_resume_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	emit_signal("press_resume")  
	queue_free()

func _on_mainmenu_pressed() -> void:
	audio_click.play()
	await  audio_click.finished
	emit_signal("press_mainmenu")  
	queue_free()

func _on_options_pressed():
	audio_click.play()
	await  audio_click.finished
	$VBoxContainer.hide()
	await animate_menu(true)
	$OptionsMenu.show()

func _on_back_pressed():
	audio_click.play()
	await  audio_click.finished
	$OptionsMenu.hide()
	await animate_menu(false)
	$VBoxContainer.show()

# Interpola el tamaño y la posición del fondo para transicionar entre menús
func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 190)
	var tween = create_tween()
	tween.tween_property(Background, "size", size, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(Background, "position", position, 0.5)
	await tween.finished

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_mouse_entered() -> void:
	audio_entered.play()
