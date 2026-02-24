extends CanvasLayer

# ==============================================================================
# CONSTANTES GLOBALES
# ==============================================================================
const MASTER_BUS_NAME = "Master"
const MUSIC_BUS_NAME = "Music"
const SFX_BUS_NAME = "SFX"

const SAVE_PATH = "user://settings.cfg"


# ==============================================================================
# PROPIEDADES EXPORTADAS
# ==============================================================================
@export var level_backgrounds: Array[Texture2D]


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
# --- Interfaz Principal ---
@onready var Exit_Button = $ExitButton
@onready var main_background: TextureRect = $Background
@onready var Button_background = $ButtonsBackground
@onready var Resume_Button = $ButtonsContainer/ResumeButton

# --- Interfaz de Opciones (Sliders) ---
@onready var master_slider: HSlider = $OthersMenu/Options/HBoxContainer/Volumen/General/MasterSlider
@onready var music_slider: HSlider = $OthersMenu/Options/HBoxContainer/Volumen/Music/MusicSlider
@onready var sfx_slider: HSlider = $OthersMenu/Options/HBoxContainer/Volumen/SFX/SFXSlider

# --- Audio ---
@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2
@onready var music_main = $AudioStream_MainMusic


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

func _ready():
	# Carga las configuraciones de audio guardadas en disco
	load_settings()
	
	# Conecta las señales de los sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Configura el cursor personalizado
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Muestra u oculta el botón de "Continuar" dependiendo de si hay progreso
	Resume_Button.visible = SceneManager.has_saved_game
	if Resume_Button.visible:
		$ButtonsContainer.size.y = 480.0
		$ButtonsContainer.position.y = 416.0
		
	# Ajusta la ambientación e inicia la música
	update_menu_background()
	music_main.play()


# ==============================================================================
# GESTIÓN VISUAL Y ANIMACIONES DE MENÚ
# ==============================================================================

# Actualiza el fondo del menú basándose en el nivel actual del Singleton SceneManager
func update_menu_background() -> void:
	var current_lvl = SceneManager.current_level
	print("currentLevel: ", current_lvl)
	
	if current_lvl < 1:
		current_lvl = 1
	
	var bg_index = current_lvl - 1
	
	if bg_index < level_backgrounds.size():
		if level_backgrounds[bg_index] != null:
			main_background.texture = level_backgrounds[bg_index]
	else:
		if level_backgrounds.size() > 0:
			main_background.texture = level_backgrounds[0]

# Interpola el tamaño y posición del fondo de botones para transiciones suaves
func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 305)
	
	var tween = create_tween()
	tween.tween_property(Button_background, "size", size, 0.5)
	tween.parallel().tween_property(Button_background, "position", position, 0.5)
	await tween.finished

# Alterna la visibilidad entre el menú de Opciones y el menú de Créditos
func show_other_menu(enter: bool):
	if enter:
		$OthersMenu/Options.show()
	else:
		$OthersMenu/Credits.show()
	$OthersMenu.show()

# Alterna la visibilidad de los elementos del menú principal
func show_main_menu(enter: bool):
	if enter:
		Exit_Button.show()
		$ButtonsContainer.show()
		$Label.show()
	else:
		$Label.hide()
		$ExitButton.hide()
		$ButtonsContainer.hide()


# ==============================================================================
# SISTEMA DE GUARDADO Y CONFIGURACIÓN DE AUDIO
# ==============================================================================

# Carga el archivo de opciones de disco y aplica los valores a los sliders y buses
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

# Escribe los valores actuales de los sliders en un archivo de configuración físico
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save(SAVE_PATH)

# Convierte el valor lineal (0-100) a decibelios y lo aplica al bus de audio objetivo
func set_bus_volume(bus_name: String, value: float) -> void:
	if value == 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), -80)
	else:
		var db_volume = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db_volume)
	
	

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
# GESTIÓN DE SEÑALES DE INTERFAZ (BOTONES)
# ==============================================================================

func _on_continue_pressed():
	audio_click.play()
	await audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	SceneManager.load_game_data()
	
	# Desvanece la música principal antes de cargar la escena
	var tween = create_tween()
	tween.tween_property(music_main, "volume_db", -80, 2)
	
	var scene_path = "res://Scenes/Level_" + str(SceneManager.current_level) + ".tscn"
	ScenesTransitions.change_scene(scene_path)

func _on_new_game_pressed():
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	SceneManager.start_new_game()
	
	var scene_path = "res://Scenes/LoreScene.tscn"
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

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_mouse_entered() -> void:
	audio_entered.play()
