extends Node

# Referencias a nodos importantes
@onready var Resume_Button = $VBoxContainer/PlayButton  # Referencia al botón "PlayButton" dentro de VBoxContainer.
@onready var MainMenu_Button = $VBoxContainer/MainMenuButton  # Referencia al botón "MainMenuButton" dentro de VBoxContainer.

# Definición de señales personalizadas
# Estas señales se usarán para notificar a otros nodos cuando se presionen los botones.
signal press_playagain()  # Señal emitida al presionar el botón "PlayButton".
signal press_mainmenu()  # Señal emitida al presionar el botón "MainMenuButton".

func _ready() -> void: 
	# Configura un cursor personalizado para el mouse.
	Input.set_custom_mouse_cursor(preload("res://Graphics/GUI/Cursors/1.png"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Conecta la señal "pressed" de los botones
	MainMenu_Button.pressed.connect(_on_mainmenu_pressed)
	Resume_Button.pressed.connect(_on_playagain_pressed)

# Función que se ejecuta cuando se presiona el botón "PlayButton".
func _on_playagain_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Oculta el cursor del mouse.
	emit_signal("press_playagain")  # Emite la señal "press_playagain".
	queue_free()# Elimina este nodo (el menú).

# Función que se ejecuta cuando se presiona el botón "MainMenuButton".
func _on_mainmenu_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)# Asegura que el cursor del mouse siga visible para el menú principal.
	emit_signal("press_mainmenu")  # Emite la señal "press_mainmenu".
	queue_free() # Elimina este nodo (el menú) de la escena.
