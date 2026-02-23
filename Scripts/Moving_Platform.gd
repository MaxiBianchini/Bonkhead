extends AnimatableBody2D

@onready var sprite_1: Sprite2D = $Sprite2D
@onready var sprite_2: Sprite2D = $Sprite2D2
@onready var sprite_3: Sprite2D = $Sprite2D3

# --- CONFIGURACIÓN ESTÉTICA AUTOMÁTICA ---
@export_group("Texturas por Nivel")
@export var texturas_sprite_1: Array[Texture2D]
@export var texturas_sprite_2: Array[Texture2D]
@export var texturas_sprite_3: Array[Texture2D]

var direction: int = 1
@export var speed: float = 100.0
var start_position: Vector2
var target_position: Vector2

func _ready() -> void:
	# 1. Adaptamos el aspecto al nivel actual
	configurar_estetica()
	
	# 2. Inicializamos el movimiento
	start_position = global_position
	var marker = find_child("Marker2D", true, false)
	
	if marker:
		# Guardamos la posición global inicial del marker.
		# Como esto se lee solo en el _ready, no importa que el marker 
		# se mueva junto con la plataforma después.
		target_position = marker.global_position
	else:
		push_error("No se encontró un Marker2D dentro de la plataforma.")

func configurar_estetica() -> void:
	var nivel_index = SceneManager.current_level - 1
	
	# Cambiamos Sprite 1
	if nivel_index < texturas_sprite_1.size() and texturas_sprite_1[nivel_index]:
		sprite_1.texture = texturas_sprite_1[nivel_index]
		sprite_1.visible = true
	else:
		sprite_1.visible = false
		
	# Cambiamos Sprite 2
	if nivel_index < texturas_sprite_2.size() and texturas_sprite_2[nivel_index]:
		sprite_2.texture = texturas_sprite_2[nivel_index]
		sprite_2.visible = true
	else:
		sprite_2.visible = false
		
	# Cambiamos Sprite 3
	if nivel_index < texturas_sprite_3.size() and texturas_sprite_3[nivel_index]:
		sprite_3.texture = texturas_sprite_3[nivel_index]
		sprite_3.visible = true
	else:
		sprite_3.visible = false

func _physics_process(delta) -> void:
	if target_position == Vector2.ZERO:
		return
	
	global_position = global_position.move_toward(target_position if direction == 1 else start_position, speed * delta)
	
	if global_position.is_equal_approx(target_position) and direction == 1:
		direction = -1
	elif global_position.is_equal_approx(start_position) and direction == -1:
		direction = 1
