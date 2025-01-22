extends CharacterBody2D

@onready var drone_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $Area2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var player = get_node("../Player")

var horizontal_speed: float = 100.0
var vertical_speed: float = 80.0
var patrol_range: float = 200.0
var patrol_direction: int = 1  # 1 = derecha, -1 = izquierda

var initial_height: float
var start_position: Vector2
var follow_player: bool = false

var chase_stop_distance_x: float = 80.0 # Distancia mínima en X
var hover_offset_y: float = 30.0 # Offset en Y

var lives: int = 3
var is_alive: bool = true

func _ready() -> void:
	drone_sprite.play("Walk Scan")
	start_position = position
	initial_height = position.y

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	drone_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if not is_alive:
		_apply_gravity(delta)
		return

	if follow_player and player.is_alive:
		_chase_player(delta)
	else:
		_return_to_height(delta)
		_patrol_horizontally(delta)

func _apply_gravity(delta: float) -> void:
	velocity.y += 15.0 * delta
	move_and_slide()

func _chase_player(delta: float) -> void:
	# Diferencia horizontal y vertical respecto al jugador
	var dx = player.position.x - position.x
	var desired_y = player.position.y - hover_offset_y

	# 1. Persecución en X solo si estamos fuera de la distancia mínima
	if abs(dx) > chase_stop_distance_x:
		var horizontal_dir = sign(dx)
		drone_sprite.flip_h = (horizontal_dir < 0.0)
		position.x += horizontal_dir * horizontal_speed * delta
	else:
		# Si ya estamos a la distancia horizontal deseada,
		# opcionalmente podrías poner alguna animación de disparo, etc.
		drone_sprite.flip_h = (dx < 0.0)

	# 2. Ajustar Y para estar un poquito por encima del jugador
	var vertical_dir = sign(desired_y - position.y)
	if abs(position.y - desired_y) > 2.0:  # Pequeña tolerancia
		position.y += vertical_dir * vertical_speed * delta

func _return_to_height(delta: float) -> void:
	# (Opcional) Si tu intención es que, cuando no persigue, el dron regrese a su Y inicial de patrulla:
	if abs(position.y - initial_height) > 1.0:
		var vertical_dir = sign(initial_height - position.y)
		position.y += vertical_dir * (vertical_speed * delta)

func _patrol_horizontally(delta: float) -> void:
	if position.x > start_position.x + patrol_range:
		patrol_direction = -1
	elif position.x < start_position.x - patrol_range:
		patrol_direction = 1
	
	position.x += patrol_direction * (horizontal_speed * delta)
	drone_sprite.flip_h = (patrol_direction < 0)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		drone_sprite.play("Walk")
		follow_player = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		drone_sprite.play("Walk Scan")
		follow_player = false

func _on_animation_finished() -> void:
	if drone_sprite.animation == "Death":
		queue_free()

func take_damage() -> void:
	lives -= 1
	if lives <= 0:
		is_alive = false
		drone_sprite.play("Death")
		collision_shape.position.y = 9
	else:
		anim_player.play("Hurt")
		await get_tree().create_timer(3.0).timeout
