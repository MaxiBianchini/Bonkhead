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

# --- VARIABLES DE CHECKPOINT ---
var active_checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_points: int = 0
var has_active_checkpoint: bool = false

# --- NUEVO: CONTROL DE ESCENA PARA EVITAR BUGS AL DISPARAR ---
var last_scene_id: int = 0
var player_positioned: bool = false

func _ready() -> void:
	check_saved_game()
	load_game_data()
	
	# Mantenemos esta conexión, pero ahora initialize_scene será inteligente
	get_tree().tree_changed.connect(_on_tree_changed)
	
	# Primera carga manual
	call_deferred("initialize_scene")

func _on_tree_changed() -> void:
	# Usamos call_deferred para esperar a que el árbol termine de actualizarse
	call_deferred("initialize_scene")

func initialize_scene() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	if current_scene.get_instance_id() != last_scene_id:
		last_scene_id = current_scene.get_instance_id()
		player_positioned = false # Abrimos el candado para permitir mover al jugador
	
	# --- 1. LÓGICA DE GUI y HUD (Se ejecuta siempre para asegurar referencias) ---
	if current_scene.has_node("GUI"):
		gui = current_scene.get_node("GUI")
		# Reconectar referencias de UI si se perdieron
		if gui.has_node("HBoxContainer/TimeLabel/TimeCounter"):
			time_counter = gui.get_node("HBoxContainer/TimeLabel/TimeCounter")
		if gui.has_node("HBoxContainer/PointsLabel/PointersCounter"):
			points_counter = gui.get_node("HBoxContainer/PointsLabel/PointersCounter")
		# BUSCAMOS LA BARRA DE DASH (Ajusta la ruta a donde la hayas puesto)
		# Ejemplo: Si la pusiste dentro de un contenedor llamado StaminaContainer
		if gui.has_node("HBoxContainer/DashBar/TextureProgressBar"):
			dash_bar = gui.get_node("HBoxContainer/DashBar/TextureProgressBar")
			# Aseguramos que empiece llena
			dash_bar.value = dash_bar.max_value
		
		var bullet_type_container = gui.get_node("HBoxContainer/BulletIcon")
		bullet_type = bullet_type_container.get_children()
		
		var lives_container = gui.get_node("HBoxContainer/LivesLabel/HBoxContainer")
		lives_sprites = lives_container.get_children()
		var packs_container = gui.get_node("HBoxContainer/LifePacks/HBoxContainer")
		packs_sprites = packs_container.get_children()
		
		# Actualizar visibilidad inicial
		update_lives(player.lives if player else 5)
		
		# Boss UI
		if gui.has_node("HBoxContainer/FinalBossContainer"):
			boss_health_container = gui.get_node("HBoxContainer/FinalBossContainer")
		if gui.has_node("HBoxContainer/FinalBossContainer/BossHealthBar"):
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
	
	# --- 4. LÓGICA DEL JUGADOR (CON CANDADO DE SEGURIDAD) ---
	if current_scene.has_node("Player"):
		player = current_scene.get_node("Player")
		
		# A. Posicionamiento: Solo se ejecuta UNA VEZ por carga de nivel
		if has_active_checkpoint and not player_positioned:
			player.global_position = active_checkpoint_pos
			player_positioned = true # Cerramos el candado. Disparar ya no teletransportará.
			
			# Lógica de Puntos al cargar checkpoint:
			# Si venimos de morir (packs < 3), restauramos los puntos viejos.
			# Si es reinicio total (packs = 3), puntos a 0.
			if life_packs < 3:
				points = checkpoint_points
			else:
				# Si reiniciamos con 3 vidas, decidimos si queremos 0 puntos o los guardados.
				# Generalmente en "Play Again" quieres empezar con 0 puntos extra.
				points = 0 
		
		# B. Conexiones (Siempre verificamos para no perderlas)
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
			
	# Si NO hay jefe, ocultamos la barra (solo si tenemos referencia)
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

func on_player_died():
	# El jugador ha perdido una vida (el sistema de vidas internas ya restó)
	life_packs -= 1
	
	if life_packs <= 0:
		if current_level == 5:
			# Lógica del Jefe (ya estaba bien, la dejamos igual)
			life_packs = 3
			save_game_data()
			if gui: gui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			show_game_over_menu()
			
		else:
			if has_active_checkpoint:
				# CASO 1: TIENE CHECKPOINT
				# Guardamos para permitir "Resume" desde el menú
				life_packs = 3
				points = 0
				checkpoint_points = 0 
				save_game_data() # Se crea el archivo save_data.json
				print("Game Over con Checkpoint. Partida guardada.")
				
			else:
				# CASO 2: NO TIENE CHECKPOINT
				# Borramos el archivo para que NO aparezca "Resume" en el menú
				current_level = 1
				delete_saved_game()
				print("Game Over sin Checkpoint. Archivo de guardado eliminado.")

			# Mostramos el menú de Game Over
			if gui: gui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			show_game_over_menu()

	else:
		# Aún le quedan paquetes. Hacemos "respawn".
		save_game_data() 
		respawn_player()

func respawn_player():
	# Esta función simplemente recarga la escena actual.
	# El jugador reaparecerá al inicio con sus vidas reseteadas.
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Reiniciamos el tiempo del nivel para que no se acumule tras la muerte.
	game_time = 0.0 
	ScenesTransitions.change_scene(get_tree().current_scene.scene_file_path)

func update_ammo_icon(ammo_type_index: int) -> void:
	# 1. Ocultamos todos los íconos primero
	for icon in bullet_type:
		icon.visible = false

	# 2. Mostramos solo el ícono correcto, si existe en el array
	if ammo_type_index >= 0 and ammo_type_index < bullet_type.size():
		bullet_type[ammo_type_index].visible = true

#///////////////////////////////////////////////

# --- FLUJO DE JUEGO: REINICIAR (Play Again) ---
func restart_gameplay() -> void:
# 1. Configuración común (quitar pausa, ocultar mouse)
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# 2. Restablecer Valores Iniciales
	life_packs = 3       # Vidas llenas
	points = 0           # Puntos a 0 (Nueva partida limpia)
	game_time = 0.0      # Reloj a 0
	
	# 3. ELIMINAR CHECKPOINT (Tu petición específica)
	# "Por más que tenga checkpoint o no... quiero que arranque desde el level 1"
	# Al poner esto en false, borramos cualquier rastro de progreso intermedio en memoria.
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")
	
	# 4. DECISIÓN DE NIVEL
	
	# Mantenemos la Excepción del Jefe Final (Nivel 5) que pediste antes:
	# Si mueres contra el jefe, reinicias contra el jefe.
	#if current_level == 5:
		#ScenesTransitions.change_scene("res://Scenes/Level_5.tscn")
		
	#else:
		## PARA TODOS LOS DEMÁS NIVELES (1 al 4):
		## Forzamos el reinicio absoluto al Nivel 1.
		#current_level = 1 
		#ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")
		#start_new_game()

func pass_to_nextlevel():
	# Si el nivel actual es el 5 (el Jefe Final), vamos al lore de cierre
	if current_level == 5:
		# Borramos el archivo de guardado y ponemos has_saved_game en false
		delete_saved_game()
		current_level = 1
		ScenesTransitions.change_scene("res://Scenes/FinalLoreScene.tscn")
		return
	
	# Lógica normal para los niveles anteriores
	has_active_checkpoint = false
	active_checkpoint_pos = Vector2.ZERO
	current_level += 1
	game_time = 0.0
	save_game_data()
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")

func go_to_mainmenu() -> void:
	load_game_data()
	game_time = 0.0
	get_tree().paused = false
	ScenesTransitions.change_scene("res://Scenes/MainMenu.tscn")

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
		print("Partida guardada en nivel: ", current_level)

func load_game_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		file.close()
		
		# Cargar datos básicos
		current_level = data.get("current_level", 1)
		points = data.get("points", 0)
		life_packs = data.get("life_packs", 3)
		has_saved_game = true
	else:
		has_saved_game = false

# --- FLUJO DE JUEGO: NUEVA PARTIDA (New Game) ---
func start_new_game():
	points = 0
	life_packs = 3
	game_time = 0.0
	current_level = 1
	
	# Borrado explícito de checkpoint
	has_active_checkpoint = false 
	active_checkpoint_pos = Vector2.ZERO
	
	# Borrar archivo físico si existe para evitar conflictos
	delete_saved_game()
	
	#ScenesTransitions.change_scene("res://Scenes/Level_1.tscn")

func delete_saved_game() -> void:
	# Verificamos si existe el archivo
	if FileAccess.file_exists("user://save_data.json"):
		# Lo borramos usando DirAccess
		DirAccess.remove_absolute("user://save_data.json")
	
	# Actualizamos la variable para que el Menú sepa que no hay nada
	has_saved_game = false

# --- GUARDADO Y CARGA ---
func activate_checkpoint(pos: Vector2, current_points: int) -> void:
	active_checkpoint_pos = pos
	checkpoint_points = current_points
	has_active_checkpoint = true
	player_positioned = true
	# Guardamos inmediatamente para que funcione el "Resume" desde menú
	save_game_data()

#///////////////////////////////////////////////

func add_new_points(value: int):
	points += value
	update_ui()

func check_saved_game() -> void:
	has_saved_game = FileAccess.file_exists("user://save_data.json")

func update_ui():
	# Calculamos el tiempo igual que antes
	var minuts = float(game_time) / 60
	var seconds = int(game_time) % 60
	
	# Formateamos el string igual que antes
	var time_str = "%02d:%02d" % [minuts, seconds]
	var points_str = str(points)
	
	# En lugar de .text =, llamamos a nuestra función .set_text()
	if time_counter:
		time_counter.set_text(time_str)
		
	if points_counter:
		points_counter.set_text(points_str)
	
	if dash_bar and player:
		# 1. ¿El jugador está en COOLDOWN (recargando)?
		if not player.dash_cool_down_timer.is_stopped():
			# Calculamos cuánto falta para terminar.
			# Fórmula: (1 - (TiempoRestante / TiempoTotal)) * ValorMáximo
			var time_left = player.dash_cool_down_timer.time_left
			var wait_time = player.dash_cool_down_timer.wait_time
			
			# Esto hace que la barra vaya subiendo de 0 a 100 suavemente
			dash_bar.value = (1.0 - (time_left / wait_time)) * dash_bar.max_value
			
		# 2. ¿El jugador está DASHING (gastando la energía)?
		elif not player.dash_duration_timer.is_stopped():
			# Hacemos que la barra baje rápido mientras dura el impulso
			var time_left = player.dash_duration_timer.time_left
			var wait_time = player.dash_duration_timer.wait_time
			
			# Esto hace que baje de 100 a 0
			dash_bar.value = (time_left / wait_time) * dash_bar.max_value
			
		# 3. ¿Está listo para usar?
		elif player.can_dash:
			# Barra llena y lista
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
	
	# Conexiones existentes...
	if not game_over_menu.press_restartlevel.is_connected(restart_gameplay):
		game_over_menu.press_restartlevel.connect(restart_gameplay)
	
	if not game_over_menu.press_mainmenu.is_connected(go_to_mainmenu):
		game_over_menu.press_mainmenu.connect(go_to_mainmenu)
		
	get_tree().current_scene.add_child(game_over_menu)

func resuem_gameplay() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	if gui: gui.visible = true





#func retry_from_checkpoint():
	## Restauramos las vidas para que pueda seguir jugando
	#life_packs = 3
	#
	## Lógica solicitada: Si murió del todo, pierde los puntos acumulados
	#points = 0 
	## (Opcional: si quieres que conserve los puntos que tenía al tocar el check, usa: points = checkpoint_points)
	#
	## Si tiene checkpoint, recargamos la escena actual
	#if has_active_checkpoint:
		#print("Reintentando desde Checkpoint...")
		## Al recargar, initialize_scene() leerá 'active_checkpoint_pos' y moverá al player
		#ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")
	#else:
		## Si no tenía checkpoint, reinicia desde el nivel 1
		#start_new_game()

func update_boss_health(new_health: int) -> void:
	if boss_health_bar:
		# Cambio suave (Más moderno/jugoso)
		var tween = create_tween()
		tween.tween_property(boss_health_bar, "value", new_health, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_boss_bar() -> void:
	if boss_health_bar:
		# Esperamos un poco para ver el golpe final y luego desvanecemos
		var tween = create_tween()
		tween.tween_interval(2.0) # Espera 2 segundos
		tween.tween_property(boss_health_bar, "modulate:a", 0.0, 1.0) # Desvanece
		await tween.finished
		boss_health_container.visible = false
		boss_health_bar.visible = false
		boss_health_bar.modulate.a = 1.0 # Reset para la próxima

func show_boss_bar_animated() -> void:
	# Verificamos que tengamos la barra y el boss
	if not boss_health_bar: return
	
	# Buscamos al boss para saber su vida máxima actual
	var current_scene = get_tree().current_scene
	if not current_scene or not current_scene.has_node("Final_Boss"): return
	var boss = current_scene.get_node("Final_Boss")
	
	# Solo ejecutamos si la barra estaba oculta (para evitar reinicios por disparos)
	if not boss_health_container.visible:
		# Configuración inicial
		boss_health_container.visible = true
		
		boss_health_bar.max_value = boss.max_health
		boss_health_bar.value = 0 # Empieza vacía
		boss_health_bar.visible = true # ¡Ahora aparece!
		
		# Animación de llenado
		var fill_tween = create_tween()
		fill_tween.tween_property(boss_health_bar, "value", boss.current_health, 1.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
