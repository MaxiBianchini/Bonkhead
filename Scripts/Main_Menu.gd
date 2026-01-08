extends CanvasLayer

@onready var Exit_Button = $ExitButton
@onready var main_background: TextureRect = $Background
@onready var Button_background = $ButtonsBackground
@onready var Resume_Button = $ButtonsContainer/ResumeButton

# --- Lista para cargar las imágenes de los niveles ---
@export var level_backgrounds: Array[Texture2D]

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2
@onready var music_main = $AudioStream_MainMusic


# --- Referencias a los Sliders ---
@onready var master_slider: HSlider = $OthersMenu/Options/HBoxContainer/Volumen/General/MasterSlider
@onready var music_slider: HSlider = $OthersMenu/Options/HBoxContainer/Volumen/Music/MusicSlider
@onready var sfx_slider: HSlider = $OthersMenu/Options/HBoxContainer/Volumen/SFX/SFXSlider
# Nombres de los buses (deben coincidir EXACTAMENTE con los que creaste)
const MASTER_BUS_NAME = "Master"
const MUSIC_BUS_NAME = "Music"
const SFX_BUS_NAME = "SFX"

# Ruta para guardar los ajustes
const SAVE_PATH = "user://settings.cfg"

var exist_file: SceneManager

func _ready():
	# Cargamos los ajustes guardados al iniciar el menú
	load_settings()
	
	# Conectamos las señales de los sliders a nuestras funciones
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Resume_Button.visible = SceneManager.has_saved_game
	if Resume_Button.visible:
		$ButtonsContainer.size.y = 480.0
		$ButtonsContainer.position.y = 416.0
		
	
	update_menu_background()
	music_main.play()

# --- NUEVO: Función para cambiar el fondo ---
func update_menu_background() -> void:
	# Obtenemos el nivel actual del SceneManager
	var current_lvl = SceneManager.current_level
	
	# Si por algún motivo es 0 o menor (primera vez), forzamos que sea 1
	if current_lvl < 1:
		current_lvl = 1
	
	# Los Arrays empiezan en 0, pero tus niveles en 1.
	# Restamos 1 para obtener el índice correcto.
	var bg_index = current_lvl - 1
	
	# Verificamos que tengamos una imagen cargada para ese nivel para evitar errores
	if bg_index < level_backgrounds.size():
		if level_backgrounds[bg_index] != null:
			main_background.texture = level_backgrounds[bg_index]
	else:
		# Si estamos en el nivel 10 pero solo pusiste 5 imágenes,
		# cargamos la última disponible o la del nivel 1 por defecto.
		if level_backgrounds.size() > 0:
			main_background.texture = level_backgrounds[0]

func _on_master_volume_changed(value: float) -> void:
	set_bus_volume(MASTER_BUS_NAME, value)

func _on_music_volume_changed(value: float) -> void:
	set_bus_volume(MUSIC_BUS_NAME, value)

func _on_sfx_volume_changed(value: float) -> void:
	set_bus_volume(SFX_BUS_NAME, value) 

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

func _on_continue_pressed():
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var tween = create_tween()
	tween.tween_property(music_main, "volume_db", -80, 2)
	var scene_path = "res://Scenes/Level_" + str(SceneManager.current_level) + ".tscn"
	ScenesTransitions.change_scene(scene_path)

func _on_new_game_pressed():
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	SceneManager.start_new_game()
	var scene_path = "res://Scenes/LoreScene.tscn"#"res://Scenes/LoreScene.tscn"
	ScenesTransitions.change_scene(scene_path)

func _on_options_pressed():
	audio_click.play()
	await  audio_click.finished
	show_main_menu(false)
	await animate_menu(true)
	show_other_menu(true)

func _on_credits_pressed():
	audio_click.play()
	await  audio_click.finished
	show_main_menu(false)
	await animate_menu(true)
	show_other_menu(false)

func _on_back_pressed():
	audio_click.play()
	await  audio_click.finished
	$OthersMenu.hide()
	$OthersMenu/Options.hide()
	$OthersMenu/Credits.hide()
	await animate_menu(false)
	show_main_menu(true)

func _on_exit_pressed():
	audio_click.play()
	await  audio_click.finished
	get_tree().quit()

func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 305)
	var tween = create_tween()
	tween.tween_property(Button_background, "size", size, 0.5)
	tween.parallel().tween_property(Button_background, "position", position, 0.5)
	await tween.finished

func show_other_menu(enter: bool):
	if enter:
		$OthersMenu/Options.show()
	else:
		$OthersMenu/Credits.show()
	$OthersMenu.show()

func show_main_menu(enter: bool):
	if enter:
		Exit_Button.show()
		$ButtonsContainer.show()
		$Label.show()
	else:
		$Label.hide()
		$ExitButton.hide()
		$ButtonsContainer.hide()

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		print("PASAPOR")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		print("PASAPOR2")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_mouse_entered() -> void:
	audio_entered.play()
