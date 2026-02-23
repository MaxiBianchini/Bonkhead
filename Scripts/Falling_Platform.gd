extends RigidBody2D

@onready var collapse_timer: Timer = $Timer2
@onready var reset_timer: Timer = $Timer

@onready var sprite_1: Sprite2D = $Sprite2D
@onready var sprite_2: Sprite2D = $Sprite2D2
@onready var sprite_3: Sprite2D = $Sprite2D3

@export_group("Texturas por Nivel")
@export var texturas_sprite_1: Array[Texture2D]
@export var texturas_sprite_2: Array[Texture2D]
@export var texturas_sprite_3: Array[Texture2D]

var player_on_platform: bool = false
var falling: bool = false
var initial_position: Vector2

func _ready() -> void:
	initial_position = position
	
	freeze = true
	
	configurar_estetica()

func configurar_estetica() -> void:
	var nivel_index = SceneManager.current_level - 1
	
	if nivel_index < texturas_sprite_1.size() and texturas_sprite_1[nivel_index]:
		sprite_1.texture = texturas_sprite_1[nivel_index]
		sprite_1.visible = true
	else:
		sprite_1.visible = false
		
	if nivel_index < texturas_sprite_2.size() and texturas_sprite_2[nivel_index]:
		sprite_2.texture = texturas_sprite_2[nivel_index]
		sprite_2.visible = true
	else:
		sprite_2.visible = false
		
	if nivel_index < texturas_sprite_3.size() and texturas_sprite_3[nivel_index]:
		sprite_3.texture = texturas_sprite_3[nivel_index]
		sprite_3.visible = true
	else:
		sprite_3.visible = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and not falling:
		player_on_platform = true
		if collapse_timer.is_stopped():
			collapse_timer.start()

func start_falling() -> void:
	if player_on_platform:
		freeze = false
		falling = true
		reset_timer.start()

func reset_platform() -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
	position = initial_position
	
	falling = false
	player_on_platform = false
