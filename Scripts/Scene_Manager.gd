extends Node

# Referencias a nodos importantes
#@onready var pause_menu = $PauseMenu
#@onready var button_background = $PauseMenu/ButtonBackground
@onready var enemies_node = $Enemies  # Referencia al nodo que contiene los enemigos

@onready var time_label = $GUI/HBoxContainer/TimeLabel/Text
@onready var points_label = $GUI/HBoxContainer/PointsLabel/Text
@onready var lives_sprites = $GUI/HBoxContainer/LivesLabel/HBoxContainer.get_children()  # Obtiene todos los sprites dentro del HBoxContainer

# Conectamos las señales de los botones al script
#@onready var MainMenu_Button = $PauseMenu/VBoxContainer/MainMenuButton
#@onready var Option_Button = $PauseMenu/VBoxContainer/OptionButton
#@onready var Resume_Button = $PauseMenu/VBoxContainer/ResumeButtom
#@onready var Back_Button = $OptionsMenu/BackButtonContainer/BackButton
@onready var PlayAgain_Button = $GameOverMenu/VBoxContainer/PlayButton
@onready var MainMenu_Button2 = $GameOverMenu/VBoxContainer/MainMenuButton

@onready var doorway = $Doorway

# Variables varias
var option_is_pressed
var option_is_now_visible
var esc_activated

var game_time: float = 0.0
var points: int = 0

var textura_cursor = preload("res://Graphics/GUI/Cursors/1.png")  # Reemplaza con la ruta de tu imagen

func _ready() -> void: 
	Input.set_custom_mouse_cursor(textura_cursor)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Ocultar el cursor
	
	if doorway:
		doorway.has_signal("winLevel")
		doorway.winLevel.connect(LevelPass)
	
	#add_points.connect(new_points)
	for enemy in enemies_node.get_children():  # Obtiene todos los nodos hijos dentro de `enemies`
		if enemy.has_signal("add_points"):  # Asegura que el nodo tiene la señal
			enemy.add_points.connect(add_new_points)
			
	var player = $Player  # Asegúrate de que Player esté correctamente referenciado
	if player:
		player.player_died.connect(on_player_died)
		player.change_UI_lives.connect(update_lives)
	
	#MainMenu_Button.pressed.connect(_on_mainmenu_pressed)
	#Option_Button.pressed.connect(_on_options_pressed)
	#Resume_Button.pressed.connect(_on_resume_pressed)
	#Back_Button.pressed.connect(_on_back_pressed)
	MainMenu_Button2.pressed.connect(_on_mainmenu_pressed)
	PlayAgain_Button.pressed.connect(_on_playagain_pressed)
	esc_activated = false

func _process(delta):
	# Aumentar el tiempo jugado
	if $GUI.visible:
		game_time += delta
		update_ui()

func _on_mainmenu_pressed():
	get_tree().paused = false  # Reanuda el juego
	# Cambia de escena o realiza alguna acción para iniciar el juego
	ScenesTransitions.change_scene("res://Scenes/Main_Menu.tscn")

# Función para manejar la animación del menú, tomando un parámetro para determinar si es de entrada o salida
func animate_menu(enter: bool):
	var size = Vector2(1430, 1080) if enter else Vector2(540, 700)
	var position = Vector2(245, 0) if enter else Vector2(690, 190)
	var tween = create_tween()
	#tween.tween_property(button_background, "size", size, 0.5)#.set_trans(Tween.TRANS_SINE)
	#tween.parallel().tween_property(button_background, "position", position, 0.5)
	await tween.finished

# Cierra el juego
func _on_exit_pressed():
	get_tree().quit()

func _on_options_pressed():
	option_is_pressed = true
	$PauseMenu/VBoxContainer.hide()
	await animate_menu(true)
	$OptionsMenu.show()
	option_is_now_visible = true
	esc_activated = false

func _on_resume_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$GUI.visible = true
	#pause_menu.hide()
	get_tree().paused = false  # Reanuda el juego

#func _on_back_pressed():
	#$OptionsMenu.hide()
	#await animate_menu(false)
	
	#$PauseMenu/VBoxContainer.show()
	#option_is_pressed = false
	#option_is_now_visible = false
	#esc_activated = false

# Método para manejar la pausa
func _input(event):
	if event.is_action_pressed("ui_cancel") and !esc_activated and !$GameOverMenu.visible:  # Detecta la tecla "Esc"
		toggle_pause_menu()

# Mostrar u ocultar el menú de pausa
func toggle_pause_menu():
	esc_activated  = true
	if option_is_pressed:
		if !option_is_now_visible:
			# Si se presionó el botón de opciones y el menú de opciones aún no es visible,
			# esperamos a que termine de mostrarse
			return
		#else:
			# Si el menú de opciones ya es visible, volvemos al menú de pausa
			#_on_back_pressed()
	else:#
		# Si no se ha presionado el botón de opciones, manejamos el menú de pausa
		show_pause_menu()
		#pause_menu.visible = !pause_menu.visible
		#get_tree().paused = pause_menu.visible
		#$GUI.visible = !pause_menu.visible
		#if pause_menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		#else:Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		esc_activated = false

# Ir al menú principal (cambiar escena)
func _on_return_to_menu_pressed():
	get_tree().paused = false  # Reanuda el juego
	$GUI.visible = true

func on_player_died():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$GameOverMenu.visible = true
	$GUI.visible = false
	#get_tree().paused = true
	

func _on_playagain_pressed():
	get_tree().paused = false
	ScenesTransitions.change_scene(get_tree().current_scene.scene_file_path)

# Continuar el juego (ocultar el menú)
func _on_continue_pressed():
	toggle_pause_menu()

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) # Activa pantalla completa
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED) # Cambia a modo ventana

func add_new_points(value: int):
	points += value
	update_ui()

func LevelPass():
	ScenesTransitions.change_scene("res://Scenes/Main_Menu.tscn")

func update_ui():
	# Actualizar el cronómetro en formato mm:ss
	var minuts = int(game_time) / 60
	var seconds = int(game_time) % 60
	time_label.text = "%02d:%02d" % [minuts, seconds]
	
	# Actualizar puntos y vidas
	points_label.text = str(points)
	
func update_lives(lives):
	for i in range(len(lives_sprites)):
		lives_sprites[i].visible = i < lives  # Muestra/oculta según la cantidad de vidas
		


func show_pause_menu() -> void:
	var pause_menu = preload("res://Scenes/PauseMenu.tscn").instantiate()
	get_tree().current_scene.add_child(pause_menu)
