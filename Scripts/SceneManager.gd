extends Node

var life_packs: int

var enemies_node: Node = null
var time_label: Label = null
var points_label: Label = null
var lives_sprites: Array = []
var packs_sprites: Array = []
var bullet_type: Array = []
var comic_page: Node = null
var player: Node = null
var gui: Node = null

# En las variables del principio
var boss_health_bar: TextureProgressBar = null
var boss_health_container:Sprite2D = null

var pause_menu: Node = null
var game_over_menu: Node = null

var current_level: int
var game_time: float
var points: int

var has_saved_game: bool = false

func _ready() -> void:
	check_saved_game()
	load_game_data()
	
	get_tree().tree_changed.connect(_on_tree_changed)
	initialize_scene()

func _on_tree_changed() -> void:
	call_deferred("initialize_scene")

func initialize_scene() -> void:
	var current_scene = get_tree().current_scene
	
	if current_scene:
		# --- LÓGICA DE ENEMIGOS ---
		if current_scene.has_node("Enemies"):
			enemies_node = current_scene.get_node("Enemies")
			for enemy in enemies_node.get_children():
				if enemy.has_signal("add_points") and not enemy.add_points.is_connected(add_new_points):
					enemy.add_points.connect(add_new_points)
		
		if current_scene.has_node("GUI"):
			gui = current_scene.get_node("GUI")
			time_label = gui.get_node("HBoxContainer/TimeLabel/Text")
			points_label = gui.get_node("HBoxContainer/PointsLabel/Text")
			
			#Bullet
			var bullet_type_container = gui.get_node("HBoxContainer/BulletIcon")
			bullet_type = bullet_type_container.get_children()
			
			#Lives
			var lives_container = gui.get_node("HBoxContainer/LivesLabel/HBoxContainer")
			lives_sprites = lives_container.get_children()
			var packs_container = gui.get_node("HBoxContainer/LifePacks/HBoxContainer")
			packs_sprites = packs_container.get_children()
			for i in range(len(packs_sprites)):
				packs_sprites[i].visible = i < life_packs
			
			# BUSCAR LA BARRA DEL JEFE EN LA GUI
			# Ajusta la ruta "Container/BossHealthBar" según donde la hayas puesto en tu escena GUI
			if gui.has_node("HBoxContainer/FinalBossContainer"): 
				boss_health_container = gui.get_node("HBoxContainer/FinalBossContainer")
				if gui.has_node("HBoxContainer/FinalBossContainer/BossHealthBar"):
					boss_health_bar = gui.get_node("HBoxContainer/FinalBossContainer/BossHealthBar")
			
		# Dentro de initialize_scene()
		if current_scene.has_node("Page_Comic"): # 
			comic_page = current_scene.get_node("Page_Comic") # [cite: 238]
			if comic_page.has_signal("winLevel"): # [cite: 239]
				if not comic_page.winLevel.is_connected(pass_to_nextlevel):
					comic_page.winLevel.connect(pass_to_nextlevel) # [cite: 240]
		
		# --- LÓGICA DEL JUGADOR ---
		if current_scene.has_node("Player"):
			player = current_scene.get_node("Player")
			if player:
				# Las conexiones comprueban is_connected, así que esto es seguro ejecutarlo muchas veces
				if not player.player_died.is_connected(on_player_died):
					player.player_died.connect(on_player_died)
				if not player.change_UI_lives.is_connected(update_lives):
					player.change_UI_lives.connect(update_lives)
				if not player.ammo_changed.is_connected(update_ammo_icon):
					player.ammo_changed.connect(update_ammo_icon)
					update_ammo_icon(player.current_ammo_type)
		
		# --- LÓGICA DEL JEFE (BOSS) ---
		# Usamos una bandera para saber si encontramos al jefe
		var boss_found = false
		
		if current_scene.has_node("Final_Boss"):
			boss_found = true
			var boss = current_scene.get_node("Final_Boss")
			
			if boss.has_signal("health_changed"):
				if not boss.health_changed.is_connected(update_boss_health):
					boss.health_changed.connect(update_boss_health)
				
			if boss.has_signal("boss_die"):
				if not boss.boss_die.is_connected(hide_boss_bar):
					boss.boss_die.connect(hide_boss_bar)
			
			if boss.has_signal("boss_intro_started"):
				# Conectamos la señal a una función nueva que crearemos abajo
				if not boss.boss_intro_started.is_connected(show_boss_bar_animated):
					boss.boss_intro_started.connect(show_boss_bar_animated)
			
			
			# Si NO hay un jefe en esta escena, nos aseguramos de ocultar la barra
			if not boss_found and boss_health_bar:
				boss_health_bar.visible = false
				boss_health_container.visible = false

func _process(delta):
	if gui and gui.visible:
		game_time += delta
		update_ui()

func _input(event):
	if event.is_action_pressed("ui_cancel") and gui and gui.visible and !ScenesTransitions.is_transitioning:
		gui.visible = false
		show_pause_menu()


func on_player_died():
	# El jugador ha perdido sus 5 vidas, así que le restamos un paquete.
	life_packs -= 1
	
	if life_packs <= 0:
		if current_level == 5:
			# NO borramos la partida.
			# Restauramos los packs a 3 (o el máximo) para guardar el estado "listo para reintentar"
			life_packs = 3 
			save_game_data() 
			
			if gui: gui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			show_game_over_menu()
		else:
			# ¡GAME OVER REAL! El jugador ha perdido todos sus paquetes.
			delete_saved_game()
			# Según el GDD, debe empezar la partida desde cero. [cite: 46]
			if gui: gui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			show_game_over_menu() # Este menú ahora significa "perdiste todo"
		
	else:
		# Aún le quedan paquetes. Hacemos "respawn".
		save_game_data() # Guardamos el progreso para que no pierda los puntos ganados.
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

# En la función restart_gameplay(), asegúrate de que reinicie el juego desde cero.
func restart_gameplay() -> void:
	if current_level == 5:
		# Lógica de Reintentar Jefe
		life_packs = 3
		
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
		# Recargamos el Nivel 5 directamente
		ScenesTransitions.change_scene("res://Scenes/Level_5.tscn")
	else:
		# Esta función es llamada desde el menú de Game Over.
		# Ahora significa empezar una partida completamente nueva.
		start_new_game() # Esto reiniciará puntos, nivel 1 y life_packs a 3.
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		ScenesTransitions.change_scene("res://Scenes/Level_1.tscn") # Siempre al nivel 1

func add_new_points(value: int):
	points += value
	update_ui()

func check_saved_game() -> void:
	has_saved_game = FileAccess.file_exists("user://save_data.json")

func pass_to_nextlevel():
	# Si el nivel actual es el 5 (el Jefe Final), vamos al lore de cierre
	if current_level == 5:
		# Borramos el archivo de guardado y ponemos has_saved_game en false
		delete_saved_game()
		current_level = 1
		ScenesTransitions.change_scene("res://Scenes/FinalLoreScene.tscn")
		return
	
	# Lógica normal para los niveles anteriores
	current_level += 1
	save_game_data()
	game_time = 0.0
	ScenesTransitions.change_scene("res://Scenes/Level_" + str(current_level) + ".tscn")

func update_ui():
	if time_label and points_label:
		var minuts = float(game_time) / 60
		var seconds = int(game_time) % 60
		time_label.text = "%02d:%02d" % [minuts, seconds]
		points_label.text = str(points)

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
	if not game_over_menu.press_playagain.is_connected(restart_gameplay):
		game_over_menu.press_playagain.connect(restart_gameplay)
	
	if not game_over_menu.press_mainmenu.is_connected(go_to_mainmenu):
		game_over_menu.press_mainmenu.connect(go_to_mainmenu)
	
	if game_over_menu.has_method("set_checkpoint_mode"):
		game_over_menu.set_checkpoint_mode(current_level == 5)
		
	get_tree().current_scene.add_child(game_over_menu)

func resuem_gameplay() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	if gui: gui.visible = true

func go_to_mainmenu() -> void:
	load_game_data()
	game_time = 0.0
	get_tree().paused = false
	ScenesTransitions.change_scene("res://Scenes/MainMenu.tscn")

func save_game_data() -> void:
	var data = {
		"score": points,
		"level": current_level,
		"life_packs": life_packs
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		has_saved_game = true

func load_game_data() -> void:
	var file = FileAccess.open("user://save_data.json", FileAccess.READ)
	if file and FileAccess.file_exists("user://save_data.json"):
		var data = JSON.parse_string(file.get_as_text())

		if data:
			points = data["score"]
			current_level = data["level"]
			life_packs = data.get("life_packs", 3)
		file.close()
	else:
		current_level = 1
		game_time = 0.0
		life_packs = 3
		points = 0

func start_new_game() -> void:
	points = 0
	current_level = 1
	life_packs = 3
	save_game_data()

# Se llama cada vez que el Boss recibe daño
func update_boss_health(new_health: int) -> void:
	if boss_health_bar:
		# Cambio suave (Más moderno/jugoso)
		var tween = create_tween()
		tween.tween_property(boss_health_bar, "value", new_health, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Se llama cuando el Boss muere
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

func delete_saved_game() -> void:
	# Verificamos si existe el archivo
	if FileAccess.file_exists("user://save_data.json"):
		# Lo borramos usando DirAccess
		DirAccess.remove_absolute("user://save_data.json")
	
	# Actualizamos la variable para que el Menú sepa que no hay nada
	has_saved_game = false
