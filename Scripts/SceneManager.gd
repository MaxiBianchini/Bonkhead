extends Node

# ==============================================================================
# VARIABLES GLOBALES Y DE ESTADO
# ==============================================================================
# --- Progreso del Juego ---
var current_level: int
var game_time: float
var points: int
var life_packs: int
var has_saved_game: bool = false

# --- Optimización de UI ---
var last_rendered_second: int = -1

# --- Sistema de Checkpoints (Nivel Normal) ---
var has_active_checkpoint: bool = false
var active_checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_points: int = 0

# --- Sistema de Checkpoints (Jefe Final) ---
var has_boss_checkpoint: bool = false
var boss_checkpoint_state: int = 0
var boss_checkpoint_health: int = 0

# --- Control de Escena ---
var last_scene_id: int = 0
var player_positioned: bool = false


# ==============================================================================
# REFERENCIAS A NODOS (DINÁMICAS)
# ==============================================================================
# --- Actores Principales ---
var player: Node = null
var enemies_node: Node = null
var comic_page: Node = null

# --- Interfaz de Usuario (GUI) Principal ---
var gui: Node = null
var time_counter: HBoxContainer = null
var points_counter: HBoxContainer = null
var lives_sprites: Array = []
var packs_sprites: Array = []

# --- Interfaz de Habilidades ---
var dash_bar_container: Sprite2D = null 
var dash_bar: TextureProgressBar = null

# --- Interfaz del Jefe Final ---
var boss_health_container: Sprite2D = null
var boss_health_bar: TextureProgressBar = null

# --- Menús Emergentes ---
var pause_menu: Node = null
var game_over_menu: Node = null


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

func _ready() -> void:
	check_saved_game()
	load_game_data()

func _process(delta):
	var current_scene = get_tree().current_scene
	
	# Detecta si se ha cargado una nueva escena para reinicializar referencias
	if current_scene and current_scene.get_instance_id() != last_scene_id:
		initialize_scene()
		
	# Actualiza el reloj y la barra de dash solo si la interfaz está visible
	if gui and gui.visible:
		game_time += delta
		update_time_and_dash_ui()


# ==============================================================================
# INICIALIZACIÓN DE ESCENA Y DEPENDENCIAS
# ==============================================================================

# Busca y conecta todos los nodos críticos de la escena actual
func initialize_scene() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	last_scene_id = current_scene.get_instance_id()
	player_positioned = false 
		
	# 1. Configuración de la GUI y sus sub-nodos
	if current_scene.has_node("GUI"):
		gui = current_scene.get_node("GUI")
		
		if gui.has_node("HBoxContainer/TimeLabel/TimeCounter"):
			time_counter = gui.get_node("HBoxContainer/TimeLabel/TimeCounter")
		if gui.has_node("HBoxContainer/PointsLabel/PointersCounter"):
			points_counter = gui.get_node("HBoxContainer/PointsLabel/PointersCounter")
			
		# Configuración de la barra de Dash (Se desbloquea en nivel 3)
		if gui.has_node("HBoxContainer/DashBar/TextureProgressBar"):
			dash_bar = gui.get_node("HBoxContainer/DashBar/TextureProgressBar")
			if gui.has_node("HBoxContainer/DashBar"):
				dash_bar_container = gui.get_node("HBoxContainer/DashBar")
				
			if current_level < 3: 
				dash_bar_container.visible = false
			else: 
				dash_bar_container.visible = true
			dash_bar.value = dash_bar.max_value
		
		# Configuración de los íconos de vida y paquetes
		var lives_container = gui.get_node("HBoxContainer/LivesLabel/HBoxContainer")
		lives_sprites = lives_container.get_children()
		var packs_container = gui.get_node("HBoxContainer/LifePacks/HBoxContainer")
		packs_sprites = packs_container.get_children()
		
		# Configuración de la barra del Jefe Final
		if gui.has_node("HBoxContainer/FinalBossContainer/BossHealthBar"):
			boss_health_container = gui.get_node("HBoxContainer/FinalBossContainer")
			boss_health_bar = gui.get_node("HBoxContainer/FinalBossContainer/BossHealthBar")

	# 2. Conexión de Enemigos
	if current_scene.has_node("Enemies"):
		enemies_node = current_scene.get_node("Enemies")
		for enemy in enemies_node.get_children():
			if enemy.has_signal("add_points") and not enemy.add_points.is_connected(add_new_points):
				enemy.add_points.connect(add_new_points)
				
	# 3. Conexión de la Meta del Nivel (Cómic)
	if current_scene.has_node("Page_Comic"):
		comic_page = current_scene.get_node("Page_Comic")
		if comic_page.has_signal("winLevel") and not comic_page.winLevel.is_connected(pass_to_nextlevel):
			comic_page.winLevel.connect(pass_to_nextlevel)
			
	# 4. Configuración del Jugador y Checkpoints
	if current_scene.has_node("Player"):
		player = current_scene.get_node("Player")
		
		if not player_positioned:
			if has_active_checkpoint:
				player.global_position = active_checkpoint_pos
				points = checkpoint_points 
			else:
				player.lives = 5
				points = get_saved_points_from_disk()
				
			update_lives(player.lives)
			player.emit_signal("change_UI_lives", player.lives)
			
			# Refresca los puntos visuales al cargar la escena
			update_points_ui()
			
			player_positioned = true 
			
		if not player.player_died.is_connected(on_player_died):
			player.player_died.connect(on_player_died)
		if not player.change_UI_lives.is_connected(update_lives):
			player.change_UI_lives.connect(update_lives)
		
	# 5. Configuración del Jefe Final
	var boss_found = false
	if current_scene.has_node("Final_Boss"):
		boss_found = true
		var boss = current_scene.get_node("Final_Boss")
		
		if boss.has_signal("phase_changed") and not boss.phase_changed.is_connected(_on_boss_phase_changed):
			boss.phase_changed.connect(_on_boss_phase_changed)
			
		if has_boss_checkpoint and current_level == 5:
			if boss.has_method("load_phase_checkpoint"):
				boss.load_phase_checkpoint(boss_checkpoint_state, boss_checkpoint_health)
				
		if boss.has_signal("health_changed") and not boss.health_changed.is_connected(update_boss_health):
			boss.health_changed.connect(update_boss_health)
			
		if boss.has_signal("boss_die") and not boss.boss_die.is_connected(hide_boss_bar):
			boss.boss_die.connect(hide_boss_bar)
			
		if boss.has_signal("boss_intro_started") and not boss.boss_intro_started.is_connected(show_boss_bar_animated):
			boss.boss_intro_started.connect(show_boss_bar_animated)

	if not boss_found and boss_health_bar:
		boss_health_bar.visible = false
		if boss_health_container: boss_health_container.visible = false


# ==============================================================================
# GESTIÓN DE ENTRADAS DEL SISTEMA (INPUTS)
# ==============================================================================

func _input(event):
	# Pausar el juego
	if event.is_action_pressed("ui_cancel") and gui and gui.visible and !ScenesTransitions.is_transitioning:
		gui.visible = false
		show_pause_menu()
		
	# --- HACKS DE DEBUG (TRUCOS) ---
	if event is InputEventKey and event.pressed:
		
		# HACK F9: Teletransporte a la página de cómic
		if event.keycode == KEY_F9:
			if is_instance_valid(player) and is_instance_valid(comic_page):
				# Movemos al jugador a la posición del cómic con un desfase seguro
				player.global_position = comic_page.global_position + Vector2(-50, -20)
				player.velocity = Vector2.ZERO 
				print("HACK: Teletransportado al final del nivel.")
				
		# HACK F10: Restaurar salud al máximo
		elif event.keycode == KEY_F10:
			if is_instance_valid(player):
				# Forzamos la vida del jugador al límite establecido (5)
				player.lives = 5
				
				# Forzamos la actualización visual de los corazones/sprites en la UI
				update_lives(player.lives)
				
				# Emitimos la señal para asegurarnos de que todo el sistema lo registre
				player.emit_signal("change_UI_lives", player.lives)
				
				print("HACK: Salud restaurada al máximo (5 vidas).")


# ==============================================================================
# LÓGICA DE FLUJO DE JUEGO (GAME LOOP Y TRANSICIONES)
# ==============================================================================

func start_new_game():
	points = 0
	life_packs = 3
	game_time = 0.0
	current_level = 1
	last_rendered_second = -1
	
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	has_boss_checkpoint = false
	boss_checkpoint_state = 0
	
	save_game_data()
	ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")

func pass_to_nextlevel():
	if current_level == 5:
		delete_saved_game()
		current_level = 1
		ScenesTransitions.change_scene("res://Scenes/FinalLoreScene.tscn")
		return
		
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	has_boss_checkpoint = false
	boss_checkpoint_state = 0
	
	current_level += 1
	game_time = 0.0
	last_rendered_second = -1
	
	save_game_data()
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")

func on_player_died():
	life_packs -= 1
	if life_packs <= 0:
		if gui: gui.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		show_game_over_menu()
	else:
		respawn_player()

func respawn_player():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	ScenesTransitions.change_scene(get_tree().current_scene.scene_file_path)

func restart_gameplay() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	life_packs = 3
	points = 0
	game_time = 0.0
	last_rendered_second = -1
	
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	has_boss_checkpoint = false
	boss_checkpoint_state = 0
	
	save_game_data()
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")

func go_to_mainmenu() -> void:
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	has_boss_checkpoint = false
	boss_checkpoint_state = 0
	
	if life_packs <= 0:
		life_packs = 3
		points = 0
		save_game_data()
		
	game_time = 0.0
	last_rendered_second = -1
	get_tree().paused = false
	ScenesTransitions.change_scene("res://Scenes/MainMenu.tscn")

func resuem_gameplay() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	if gui: gui.visible = true


# ==============================================================================
# SISTEMA DE GUARDADO Y CARGA (PERSISTENCIA)
# ==============================================================================

func check_saved_game() -> void:
	has_saved_game = FileAccess.file_exists("user://save_data.json")

func save_game_data() -> void:
	var data = {
		"current_level": current_level,
		"points": points,
		"life_packs": life_packs,
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
	has_saved_game = true

func load_game_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		file.close()
		
		current_level = data.get("current_level", 1)
		points = data.get("points", 0)
		life_packs = data.get("life_packs", 3)
		has_saved_game = true
	else:
		has_saved_game = false

func delete_saved_game() -> void:
	if FileAccess.file_exists("user://save_data.json"):
		DirAccess.remove_absolute("user://save_data.json")
	has_saved_game = false

func get_saved_points_from_disk() -> int:
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		file.close()
		return data.get("points", 0)
	return 0


# ==============================================================================
# ACTUALIZACIÓN DE INTERFAZ DE USUARIO (GUI) Y MENÚS
# ==============================================================================

# Se llama únicamente cuando el jugador obtiene puntos
func update_points_ui() -> void:
	if points_counter:
		points_counter.set_text(str(points))

# Se llama 60 veces por segundo, pero el reloj solo actualiza el texto cada 1 segundo
func update_time_and_dash_ui() -> void:
	var current_second = int(game_time)
	
	if current_second != last_rendered_second:
		last_rendered_second = current_second
		
		var minuts = current_second / 60
		var seconds = current_second % 60
		var time_str = "%02d:%02d" % [minuts, seconds]
		
		if time_counter: 
			time_counter.set_text(time_str)

	# La barra de dash se actualiza visualmente frame a frame
	if dash_bar and player:
		if not player.dash_cool_down_timer.is_stopped():
			var time_left = player.dash_cool_down_timer.time_left
			var wait_time = player.dash_cool_down_timer.wait_time
			dash_bar.value = (1.0 - (time_left / wait_time)) * dash_bar.max_value
		elif not player.dash_duration_timer.is_stopped():
			var time_left = player.dash_duration_timer.time_left
			var wait_time = player.dash_duration_timer.wait_time
			dash_bar.value = (time_left / wait_time) * dash_bar.max_value
		elif player.can_dash:
			if dash_bar.value != dash_bar.max_value:
				dash_bar.value = dash_bar.max_value

func update_lives(lives):
	for i in range(len(lives_sprites)):
		lives_sprites[i].visible = i < lives
	for i in range(len(packs_sprites)):
		packs_sprites[i].visible = i < life_packs

func show_pause_menu() -> void:
	get_tree().paused = true
	pause_menu = preload("res://Scenes/PauseMenu.tscn").instantiate()
	if not pause_menu.press_resume.is_connected(resuem_gameplay):
		pause_menu.press_resume.connect(resuem_gameplay)
	if not pause_menu.press_mainmenu.is_connected(go_to_mainmenu):
		pause_menu.press_mainmenu.connect(go_to_mainmenu)
	get_tree().current_scene.add_child(pause_menu)

func show_game_over_menu() -> void:
	get_tree().paused = true
	game_over_menu = preload("res://Scenes/GameOverMenu.tscn").instantiate()
	if not game_over_menu.press_restartlevel.is_connected(restart_gameplay):
		game_over_menu.press_restartlevel.connect(restart_gameplay)
	if not game_over_menu.press_mainmenu.is_connected(go_to_mainmenu):
		game_over_menu.press_mainmenu.connect(go_to_mainmenu)
	get_tree().current_scene.add_child(game_over_menu)


# ==============================================================================
# RECEPTORES DE SEÑALES (CHECKPOINTS, PUNTOS Y JEFE)
# ==============================================================================

func add_new_points(value: int):
	points += value
	update_points_ui()

func activate_checkpoint(pos: Vector2, current_points: int) -> void:
	active_checkpoint_pos = pos
	checkpoint_points = current_points
	has_active_checkpoint = true

func _on_boss_phase_changed(state: int, health: int) -> void:
	boss_checkpoint_state = state
	boss_checkpoint_health = health
	has_boss_checkpoint = true

func update_boss_health(new_health: int) -> void:
	if boss_health_bar:
		var tween = create_tween()
		tween.tween_property(boss_health_bar, "value", new_health, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func show_boss_bar_animated() -> void:
	if not boss_health_bar: return
	var current_scene = get_tree().current_scene
	if not current_scene or not current_scene.has_node("Final_Boss"): return
	
	var boss = current_scene.get_node("Final_Boss")
	if not boss_health_container.visible:
		boss_health_container.visible = true
		boss_health_bar.max_value = boss.max_health
		boss_health_bar.value = 0
		boss_health_bar.visible = true
		
		var fill_tween = create_tween()
		fill_tween.tween_property(boss_health_bar, "value", boss.current_health, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_boss_bar() -> void:
	if boss_health_bar:
		var tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(boss_health_bar, "modulate:a", 0.0, 1.0)
		await tween.finished
		
		boss_health_container.visible = false
		boss_health_bar.visible = false
		boss_health_bar.modulate.a = 1.0
