extends Control

@onready var Exit_Button = $CanvasLayer/ExitButton
@onready var Button_background = $CanvasLayer/ButtonsBackground
@onready var Back_Button = $OthersMenu/BackButtonContainer/BackButton
@onready var Resume_Button = $CanvasLayer/ButtonsContainer/ResumeButton
@onready var Option_Button = $CanvasLayer/ButtonsContainer/OptionButton
@onready var Credit_Button = $CanvasLayer/ButtonsContainer/CreditButton
@onready var NewGame_Button = $CanvasLayer/ButtonsContainer/NewGameButton

@onready var audio_click = $AudioStreamPlayer
@onready var audio_entered = $AudioStreamPlayer2

var exist_file: SceneManager

func _ready():
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Resume_Button.pressed.connect(_on_continue_pressed)
	Option_Button.pressed.connect(_on_options_pressed)
	Credit_Button.pressed.connect(_on_credits_pressed)
	Exit_Button.pressed.connect(_on_exit_pressed)
	Back_Button.pressed.connect(_on_back_pressed)
	NewGame_Button.pressed.connect(_on_new_game_pressed)
	
	Resume_Button.visible = SceneManager.has_saved_game
	if Resume_Button.visible:
		$CanvasLayer/ButtonsContainer.size.y = 480.0
		$CanvasLayer/ButtonsContainer.position.y = 416.0
 
func _on_continue_pressed():
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var scene_path = "res://Scenes/Level_" + str(SceneManager.current_level) + ".tscn"
	ScenesTransitions.change_scene(scene_path)

func _on_new_game_pressed():
	audio_click.play()
	await  audio_click.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	SceneManager.start_new_game()
	var scene_path = "res://Scenes/Level_1.tscn"
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
		$CanvasLayer/ButtonsContainer.show()
		$CanvasLayer/Label.show()
	else:
		$CanvasLayer/Label.hide()
		$CanvasLayer/ExitButton.hide()
		$CanvasLayer/ButtonsContainer.hide()

func _on_fullscreen_checkbutton_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_mouse_entered() -> void:
	audio_entered.play()
