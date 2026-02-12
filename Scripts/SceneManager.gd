extends Node

# --- REFERENCIAS A NODOS ---
var life_packs: int
var enemies_node: Node = null
var time_counter: HBoxContainer = null
var points_counter: HBoxContainer = null
var lives_sprites: Array = []
var packs_sprites: Array = []
var bullet_type: Array = []
var comic_page: Node = null
var player: Node = null
var gui: Node = null
var boss_health_bar: TextureProgressBar = null
var boss_health_container: Sprite2D = null
var dash_bar: TextureProgressBar = null
var pause_menu: Node = null
var game_over_menu: Node = null

# --- DATOS DE JUEGO ---
var current_level: int
var game_time: float
var points: int
var has_saved_game: bool = false

# --- NUEVO: PERSISTENCIA DE HP (VIDAS INDIVIDUALES) ---
var saved_hp: int = 5      # HP guardado en disco (Inicio del nivel)
var current_hp: int = 5    # HP actual en tiempo real

# --- VARIABLES DE CHECKPOINT (MEMORIA RAM) ---
var active_checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_points: int = 0
var checkpoint_life_packs: int = 0
var checkpoint_hp: int = 5 # Nuevo: HP guardado en el checkpoint
var has_active_checkpoint: bool = false

# --- CONTROL DE ESCENA ---
var last_scene_id: int = 0
var player_positioned: bool = false

func _ready() -> void:
	check_saved_game()
	load_game_data()
	get_tree().tree_changed.connect(_on_tree_changed)
	call_deferred("initialize_scene")

func _on_tree_changed() -> void:
	call_deferred("initialize_scene")

func initialize_scene() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	if current_scene.get_instance_id() != last_scene_id:
		last_scene_id = current_scene.get_instance_id()
		player_positioned = false 

	# --- 1. LÓGICA DE GUI y HUD ---
	if current_scene.has_node("GUI"):
		gui = current_scene.get_node("GUI")
		if gui.has_node("HBoxContainer/TimeLabel/TimeCounter"):
			time_counter = gui.get_node("HBoxContainer/TimeLabel/TimeCounter")
		if gui.has_node("HBoxContainer/PointsLabel/PointersCounter"):
			points_counter = gui.get_node("HBoxContainer/PointsLabel/PointersCounter")
		if gui.has_node("HBoxContainer/DashBar/TextureProgressBar"):
			dash_bar = gui.get_node("HBoxContainer/DashBar/TextureProgressBar")
			dash_bar.value = dash_bar.max_value
		
		var bullet_type_container = gui.get_node("HBoxContainer/BulletIcon")
		bullet_type = bullet_type_container.get_children()
		
		var lives_container = gui.get_node("HBoxContainer/LivesLabel/HBoxContainer")
		lives_sprites = lives_container.get_children()
		var packs_container = gui.get_node("HBoxContainer/LifePacks/HBoxContainer")
		packs_sprites = packs_container.get_children()
		
		update_lives(player.lives if player else 5)
		
		if gui.has_node("HBoxContainer/FinalBossContainer/BossHealthBar"):
			boss_health_container = gui.get_node("HBoxContainer/FinalBossContainer")
			boss_health_bar = gui.get_node("HBoxContainer/FinalBossContainer/BossHealthBar")

	# --- 2. LÓGICA DE ENEMIGOS ---
	if current_scene.has_node("Enemies"):
		enemies_node = current_scene.get_node("Enemies")
		for enemy in enemies_node.get_children():
			if enemy.has_signal("add_points") and not enemy.add_points.is_connected(add_new_points):
				enemy.add_points.connect(add_new_points)

	# --- 3. LÓGICA DEL CÓMIC ---
	if current_scene.has_node("Page_Comic"):
		comic_page = current_scene.get_node("Page_Comic")
		if comic_page.has_signal("winLevel") and not comic_page.winLevel.is_connected(pass_to_nextlevel):
			comic_page.winLevel.connect(pass_to_nextlevel)

	# --- 4. LÓGICA DEL JUGADOR ---
	if current_scene.has_node("Player"):
		player = current_scene.get_node("Player")
		
		# --- CORRECCIÓN CLAVE ---
		# Envolvemos TODO en este if. 
		# Así, si 'player_positioned' ya es true (porque ya cargamos el nivel), 
		# ignoramos este bloque aunque nazcan balas o enemigos.
		if not player_positioned:
			
			if has_active_checkpoint:
				# CASO A: RESPAWN EN CHECKPOINT (RAM)
				player.global_position = active_checkpoint_pos
				
				# Restauramos datos del checkpoint
				points = checkpoint_points
				player.lives = checkpoint_hp 
				current_hp = checkpoint_hp
				
			else:
				# CASO B: INICIO DE NIVEL (O Restart Level)
				# Aquí aplicamos el HP guardado (o regenerado a 5 si fue Game Over)
				player.lives = saved_hp
				current_hp = saved_hp

			# Actualizamos la UI inmediatamente para que se vea la vida correcta
			player.emit_signal("change_UI_lives", player.lives)
			
			# ¡Marcamos que el jugador ya está listo!
			# Esto cierra el candado para que las balas no reseteen la vida.
			player_positioned = true
		
		# B. Conexiones
		if not player.player_died.is_connected(on_player_died):
			player.player_died.connect(on_player_died)
		if not player.change_UI_lives.is_connected(update_lives):
			player.change_UI_lives.connect(update_lives)
		if not player.ammo_changed.is_connected(update_ammo_icon):
			player.ammo_changed.connect(update_ammo_icon)
		update_ammo_icon(player.current_ammo_type)

	# --- 5. LÓGICA DEL BOSS ---
	var boss_found = false
	if current_scene.has_node("Final_Boss"):
		boss_found = true
		var boss = current_scene.get_node("Final_Boss")
		if boss.has_signal("health_changed") and not boss.health_changed.is_connected(update_boss_health):
			boss.health_changed.connect(update_boss_health)
		if boss.has_signal("boss_die") and not boss.boss_die.is_connected(hide_boss_bar):
			boss.boss_die.connect(hide_boss_bar)
		if boss.has_signal("boss_intro_started") and not boss.boss_intro_started.is_connected(show_boss_bar_animated):
			boss.boss_intro_started.connect(show_boss_bar_animated)

	if not boss_found and boss_health_bar:
		boss_health_bar.visible = false
		if boss_health_container: boss_health_container.visible = false

func _process(delta):
	if gui and gui.visible:
		game_time += delta
		update_ui()

func _input(event):
	if event.is_action_pressed("ui_cancel") and gui and gui.visible and !ScenesTransitions.is_transitioning:
		gui.visible = false
		show_pause_menu()

# --- LÓGICA DE MUERTE Y GAME OVER ---
func on_player_died():
	# El jugador perdió 5 HP, restamos un paquete
	life_packs -= 1
	
	if life_packs <= 0:
		# --- GAME OVER (0 Paquetes) ---
		
		# Lógica especial Nivel 5 (Jefe)
		if current_level == 5:
			# En el jefe, permitimos reintentar rápido con 3 vidas.
			# (Esto es una excepción a la regla general para no frustrar en el final)
			life_packs = 3 
			save_game_data() 
			if gui: gui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			show_game_over_menu()
			return

		# --- REGLA GDD: GAME OVER EN NIVELES NORMALES ---
		# "En el caso de tener un checkpoint activo pero perder todos los paquetes... el nuevo punto guardado pasa a ser el inicio del nivel."
		
		# 1. Borramos el Checkpoint de la MEMORIA (se pierde al morir definitivamente)
		has_active_checkpoint = false
		active_checkpoint_pos = Vector2.ZERO
		
		# 2. NO borramos el archivo de guardado del disco.
		# Esto permite que si van a Main Menu, "Resume" cargue el inicio del nivel actual.
		
		if gui: gui.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		show_game_over_menu()

	else:
		# --- RESPAWN TÁCTICO (Aún quedan paquetes) ---
		# Reaparece en checkpoint (si tiene) o inicio (si no tiene), gestionado por initialize_scene
		respawn_player()

func respawn_player():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Al respawnear dentro del mismo intento, el tiempo sigue corriendo o se puede resetear, 
	# pero generalmente en checkpoints NO se resetea a 0, sigue contando. 
	# Si prefieres resetearlo por intento, descomenta:
	# game_time = 0.0 
	ScenesTransitions.change_scene(get_tree().current_scene.scene_file_path)

# --- FLUJO DE JUEGO: RESTART LEVEL (Botón Game Over) ---
func restart_gameplay() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# 1. Cargamos datos del disco (Nivel, Puntos base)
	load_game_data() 
	
	# 2. AQUÍ APLICAMOS MI RECOMENDACIÓN DE DISEÑO:
	# Aunque cargamos los datos, FORZAMOS que la vida sea 5 para el reintento.
	# Si prefieres tu idea "Hardcore" (mantener el HP bajo), borra la línea de abajo.
	saved_hp = 5 
	
	# Reiniciamos contadores de nivel
	game_time = 0.0
	has_active_checkpoint = false
	
	# Recargamos
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")

# --- FLUJO DE JUEGO: PASAR DE NIVEL ---
func pass_to_nextlevel():
	if current_level == 5:
		delete_saved_game()
		current_level = 1
		ScenesTransitions.change_scene("res://Scenes/FinalLoreScene.tscn")
		return

	# GDD: "Si el jugador tiene un checkpoint... y pasa a un nuevo nivel, ese checkpoint se descarta."
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	
	current_level += 1
	game_time = 0.0
	
	# ANTES DE GUARDAR, LEEMOS EL HP FINAL DEL PLAYER
	if player:
		current_hp = player.lives
	
	# Ahora save_game_data guardará este 'current_hp' en 'saved_hp' dentro del JSON
	save_game_data()
	
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")

# --- FLUJO DE JUEGO: NUEVA PARTIDA ---
func start_new_game():
	points = 0
	life_packs = 3
	saved_hp = 5 # Empezamos frescos
	current_hp = 5
	game_time = 0.0
	current_level = 1
	
	has_active_checkpoint = false
	save_game_data()
	ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")

# --- PERSISTENCIA (GUARDADO EN DISCO) ---
func save_game_data() -> void:
	var data = {
		"current_level": current_level,
		"points": points,
		"life_packs": life_packs, # Guarda las vidas actuales
		"saved_hp": current_hp # GUARDAMOS EL HP ACTUAL (Sea 1, 2 o 5)
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
	has_saved_game = true
	print("Partida guardada en disco. Nivel: ", current_level, " Vidas: ", life_packs)

func load_game_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		file.close()
		
		current_level = data.get("current_level", 1)
		points = data.get("points", 0)
		life_packs = data.get("life_packs", 3)
		# CARGAMOS EL HP GUARDADO
		# Si no existe (archivo viejo), por defecto es 5
		saved_hp = data.get("saved_hp", 5) 
		
		has_saved_game = true
	else:
		has_saved_game = false

func delete_saved_game() -> void:
	if FileAccess.file_exists("user://save_data.json"):
		DirAccess.remove_absolute("user://save_data.json")
	has_saved_game = false

# --- CHECKPOINTS (SOLO MEMORIA) ---
func activate_checkpoint(pos: Vector2, current_points: int) -> void:
	active_checkpoint_pos = pos
	checkpoint_points = current_points
	checkpoint_life_packs = life_packs
	
	# GUARDAMOS EL HP ACTUAL EN LA MEMORIA DEL CHECKPOINT
	if player:
		checkpoint_hp = player.lives
	else:
		checkpoint_hp = 5 # Fallback por seguridad
		
	has_active_checkpoint = true
	player_positioned = true
	print("Checkpoint activado (RAM). HP: ", checkpoint_hp)
	print("Checkpoint activado (RAM). Pos: ", pos)

# --- SISTEMA DE MENÚS ---
func go_to_mainmenu() -> void:
	# Cargar datos aquí asegura que si el Menú Principal quisiera mostrar
	# "Nivel Actual: 3" o "Puntaje: 500", mostraría los datos guardados y no los de la muerte.
	load_game_data() 
	
	game_time = 0.0
	get_tree().paused = false
	ScenesTransitions.change_scene("res://Scenes/MainMenu.tscn")

# ... (El resto de funciones auxiliares como add_new_points, update_ui, etc. siguen igual)
func add_new_points(value: int):
	points += value
	update_ui()

func check_saved_game() -> void:
	has_saved_game = FileAccess.file_exists("user://save_data.json")

func update_ui():
	var minuts = float(game_time) / 60
	var seconds = int(game_time) % 60
	var time_str = "%02d:%02d" % [minuts, seconds]
	var points_str = str(points)
	
	if time_counter: time_counter.set_text(time_str)
	if points_counter: points_counter.set_text(points_str)

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
	# Asegúrate de que tu GameOverMenu emita la señal "press_restartlevel" (antes playagain)
	if not game_over_menu.press_restartlevel.is_connected(restart_gameplay):
		game_over_menu.press_restartlevel.connect(restart_gameplay)
	if not game_over_menu.press_mainmenu.is_connected(go_to_mainmenu):
		game_over_menu.press_mainmenu.connect(go_to_mainmenu)
	get_tree().current_scene.add_child(game_over_menu)

func resuem_gameplay() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	if gui: gui.visible = true

func update_boss_health(new_health: int) -> void:
	if boss_health_bar:
		var tween = create_tween()
		tween.tween_property(boss_health_bar, "value", new_health, 0.2)\
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

func update_ammo_icon(ammo_type_index: int) -> void:
	for icon in bullet_type:
		icon.visible = false
	if ammo_type_index >= 0 and ammo_type_index < bullet_type.size():
		bullet_type[ammo_type_index].visible = true
