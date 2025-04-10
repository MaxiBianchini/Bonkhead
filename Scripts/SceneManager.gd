extends Node

# Referencias a nodos de la escena actual
var enemies_node: Node = null
var time_label: Label = null
var points_label: Label = null
var lives_sprites: Array = []
var doorway: Node = null
var player: Node = null
var gui: Node = null

# Menús
var pause_menu: Node = null
var game_over_menu: Node = null

# Datos globales
var game_time: float = 0.0
var points: int = 0

func _ready() -> void:
	# Conectar a la señal de cambio de escena
	get_tree().tree_changed.connect(_on_tree_changed)
	initialize_scene()

func _on_tree_changed() -> void:
	# Se llama cuando el árbol de nodos cambia (por ejemplo, al cargar una nueva escena)
	call_deferred("initialize_scene")

func initialize_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		# Buscar nodos en la escena actual
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
		
		if current_scene.has_node("Doorway"):
			doorway = current_scene.get_node("Doorway")
			if doorway.has_signal("winLevel") and not doorway.winLevel.is_connected(LevelPass):
				doorway.winLevel.connect(LevelPass)
		
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
	if event.is_action_pressed("ui_cancel") and gui and gui.visible:
		gui.visible = false
		show_pause_menu()

func on_player_died():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if gui:
		gui.visible = false
	show_game_over_menu()

func add_new_points(value: int):
	points += value
	update_ui()

func LevelPass():
	ScenesTransitions.change_scene("res://Scenes/Main_Menu.tscn")

func update_ui():
	if time_label and points_label:
		var minuts = int(game_time) / 60
		var seconds = int(game_time) % 60
		time_label.text = "%02d:%02d" % [minuts, seconds]
		points_label.text = str(points)

func update_lives(lives):
	for i in range(len(lives_sprites)):
		lives_sprites[i].visible = i < lives

# Mostrar menú de pausa
func show_pause_menu() -> void:
	get_tree().paused = true
	pause_menu = preload("res://Scenes/PauseMenu.tscn").instantiate()
	if not pause_menu.delete_pausemenu.is_connected(resuem_gameplay):
		pause_menu.delete_pausemenu.connect(resuem_gameplay)
	get_tree().current_scene.add_child(pause_menu)

# Mostrar menú de game over
func show_game_over_menu() -> void:
	get_tree().paused = true
	game_over_menu = preload("res://Scenes/GameOverMenu.tscn").instantiate()
	if not game_over_menu.press_mainmenu.is_connected(go_to_mainmenu):
		game_over_menu.press_mainmenu.connect(go_to_mainmenu)
	get_tree().current_scene.add_child(game_over_menu)

func resuem_gameplay() -> void:
	get_tree().paused = false
	if gui:
		gui.visible = true

func go_to_mainmenu() -> void:
	print("PASO")
	get_tree().paused = false
	print("PASO")
	ScenesTransitions.change_scene("res://Scenes/Main_Menu.tscn")
