extends CanvasLayer

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2

@onready var Background = $Background

# --- Referencias a los Sliders ---
@onready var master_slider: HSlider = $OptionsMenu/Options/HBoxContainer/Volumen/General/MasterSlider
@onready var music_slider: HSlider = $OptionsMenu/Options/HBoxContainer/Volumen/Music/MusicSlider
@onready var sfx_slider: HSlider = $OptionsMenu/Options/HBoxContainer/Volumen/SFX/SFXSlider

# Nombres de los buses (deben coincidir EXACTAMENTE con los que creaste)
const MASTER_BUS_NAME = "Master"
const MUSIC_BUS_NAME = "Music"
const SFX_BUS_NAME = "SFX"

# Ruta para guardar los ajustes
const SAVE_PATH = "user://settings.cfg"

signal press_resume()
signal press_mainmenu()

func _ready() -> void: 
	# Cargamos los ajustes guardados al iniciar el menú
	load_settings()
	
	# Conectamos las señales de los sliders a nuestras funciones
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- Funciones que se ejecutan cuando mueves cada slider ---

func _on_master_volume_changed(value: float) -> void:
	set_bus_volume(MASTER_BUS_NAME, value)

func _on_music_volume_changed(value: float) -> void:
	set_bus_volume(MUSIC_BUS_NAME, value)

func _on_sfx_volume_changed(value: float) -> void:
	set_bus_volume(SFX_BUS_NAME, value)


# --- Función Central para Cambiar Volumen ---

func set_bus_volume(bus_name: String, value: float) -> void:
	# Los sliders nos dan un valor de 0 a 100 (lineal).
	# El audio en Godot se controla en decibelios (logarítmico).
	# Necesitamos convertir el valor.
	
	if value == 0:
		# Si el slider está en 0, ponemos el volumen al mínimo (-80 dB es silencio).
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), -80)
	else:
		# Convertimos el valor lineal (0-100) a decibelios.
		var db_volume = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db_volume)
	
	# Guardamos el cambio
	save_settings()


# --- Funciones para Guardar y Cargar ---

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config = ConfigFile.new()
	# Si el archivo de guardado no existe, no hacemos nada.
	if config.load(SAVE_PATH) != OK:
		return

	# Cargamos cada valor y actualizamos los sliders Y el audio.
	var master_vol = config.get_value("audio", "master_volume", 100)
	master_slider.value = master_vol
	set_bus_volume(MASTER_BUS_NAME, master_vol)
	
	var music_vol = config.get_value("audio", "music_volume", 100)
	music_slider.value = music_vol
	set_bus_volume(MUSIC_BUS_NAME, music_vol)
	
	var sfx_vol = config.get_value("audio", "sfx_volume", 100)
	sfx_slider.value = sfx_vol
	set_bus_volume(SFX_BUS_NAME, sfx_vol)

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
	await audio_entered.finished
