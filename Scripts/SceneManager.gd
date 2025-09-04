extends Node

var life_packs: int

var enemies_node: Node = null
var time_label: Label = null
var points_label: Label = null
var lives_sprites: Array = []
var packs_sprites: Array = []
var comic_page: Node = null
var player: Node = null
var gui: Node = null

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
		if current_scene.has_node("Enemies"):
			enemies_node = current_scene.get_node("Enemies")
			for enemy in enemies_node.get_children():
				if enemy.has_signal("add_points") and not enemy.add_points.is_connected(add_new_points):
					enemy.add_points.connect(add_new_points)
		
		if current_scene.has_node("GUI"):
			gui = current_scene.get_node("GUI")
			time_label = gui.get_node("HBoxContainer/TimeLabel/Text")
			points_label = gui.get_node("HBoxContainer/PointsLabel/Text")
			var lives_container = gui.get_node("HBoxContainer/LivesLabel/HBoxContainer")
			lives_sprites = lives_container.get_children()
			var packs_container = gui.get_node("HBoxContainer/LifePacks/HBoxContainer")
			packs_sprites = packs_container.get_children()
			for i in range(len(packs_sprites)):
				packs_sprites[i].visible = i < life_packs
		
		if current_scene.has_node("Page_Comic"):
			comic_page = current_scene.get_node("Page_Comic")
			if comic_page.has_signal("winLevel") and not comic_page.winLevel.is_connected(pass_to_nextlevel):
				comic_page.winLevel.connect(pass_to_nextlevel)
		
		if current_scene.has_node("Player"):
			player = current_scene.get_node("Player")
			if player:
				if not player.player_died.is_connected(on_player_died):
					player.player_died.connect(on_player_died)
				if not player.change_UI_lives.is_connected(update_lives):
					player.change_UI_lives.connect(update_lives)
					

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
	save_game_data() # Guardamos el progreso para que no pierda los puntos ganados.
	
	if life_packs <= 0:
		# ¡GAME OVER REAL! El jugador ha perdido todos sus paquetes.
		# Según el GDD, debe empezar la partida desde cero. [cite: 46]
		if gui: gui.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		show_game_over_menu() # Este menú ahora significa "perdiste todo"
	else:
		# Aún le quedan paquetes. Hacemos "respawn".
		respawn_player()

func respawn_player():
	# Esta función simplemente recarga la escena actual.
	# El jugador reaparecerá al inicio con sus vidas reseteadas.
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Reiniciamos el tiempo del nivel para que no se acumule tras la muerte.
	game_time = 0.0 
	ScenesTransitions.change_scene(get_tree().current_scene.scene_file_path)

# En la función restart_gameplay(), asegúrate de que reinicie el juego desde cero.
func restart_gameplay() -> void:
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
	if not game_over_menu.press_playagain.is_connected(restart_gameplay):
		game_over_menu.press_playagain.connect(restart_gameplay)
	if not game_over_menu.press_mainmenu.is_connected(go_to_mainmenu):
		game_over_menu.press_mainmenu.connect(go_to_mainmenu)
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
		print("Datos guardados correctamente")
	else:
		print("Error al guardar datos")
	

func load_game_data() -> void:
	var file = FileAccess.open("user://save_data.json", FileAccess.READ)
	if file and FileAccess.file_exists("user://save_data.json"):
		var data = JSON.parse_string(file.get_as_text())
		print("PACKS: ", data.get("life_packs"))
		if data:
			points = data["score"]
			current_level = data["level"]
			life_packs = data.get("life_packs", 3)
			print("Datos cargados correctamente")
		else:
			print("Error al parsear los datos")
		file.close()
	else:
		print("No hay datos guardados, usando valores por defecto")
		current_level = 1
		game_time = 0.0
		life_packs = 3
		points = 0

func start_new_game() -> void:
	points = 0
	current_level = 1
	life_packs = 3
	save_game_data()
