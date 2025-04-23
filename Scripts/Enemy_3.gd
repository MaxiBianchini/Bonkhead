extends CharacterBody2D

@onready var raycast_wall: RayCast2D = $RayCast2D
@onready var raycast_floor: RayCast2D = $RayCast2D2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var player = get_tree().current_scene.get_node_or_null("%Player") # Encuentra al jugador en la escena
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet_1.tscn")

var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2 = Vector2(-15, 5)
var shoot_now: bool = true

var horizontal_speed: float = 100.0
var vertical_speed: float = 80.0
var patrol_range: float = 200.0
var patrol_direction: int = 1  # 1 = derecha, -1 = izquierda

var initial_height: float
var start_position: Vector2
var follow_player: bool = false

var chase_stop_distance_x: float = 80.0 # Distancia mínima en X
var hover_offset_y: float = 25.0 # Offset en Y

var lives: int = 3
var is_alive: bool = true

signal add_points
var points = 30

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	
	animated_sprite.play("Walk Scan")
	start_position = position
	initial_height = position.y

func _physics_process(delta: float) -> void:
	if not is_alive:
		_apply_gravity()
		return
	
	if follow_player and player.is_alive:
		if raycast_wall.is_colliding() and raycast_wall.get_collider().is_in_group("Floor") or raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Floor"):
			follow_player = false
		else:
			_chase_player(delta)
	else:
		_return_to_height(delta)
		_patrol_horizontally(delta)

func _apply_gravity() -> void:
	velocity.y += 15.0
	move_and_slide()

func _chase_player(delta: float) -> void:
	# Diferencia horizontal y vertical respecto al jugador
	var dx = player.position.x - position.x
	var desired_y = player.position.y - hover_offset_y

	# Persecución en X solo si estamos fuera de la distancia mínima
	if abs(dx) > chase_stop_distance_x:
		var horizontal_dir = sign(dx)
		animated_sprite.flip_h = (horizontal_dir < 0.0)
		velocity.x = horizontal_dir * horizontal_speed 
		if horizontal_dir < 0.0:
			bullet_dir = Vector2.LEFT
			bullet_offset = Vector2(-14, 12.5)
		else:
			bullet_dir = Vector2.RIGHT
			bullet_offset = Vector2(14, 12.5)
	else:
		velocity.x = 0
		animated_sprite.flip_h = (dx < 0.0)
		if shoot_now:
			pass
			#shoot_bullet()
			#shoot_now = false
			#await get_tree().create_timer(1.5).timeout  # Pausa de 3 segundos antes de volver a la normalidad
			#shoot_now = true
		
	# Ajustar Y para estar un poquito por encima del jugador
	var vertical_dir = sign(desired_y - position.y)
	if abs(position.y - desired_y) > 2.0:  # Pequeña tolerancia
		position.y += vertical_dir * vertical_speed * delta
		
	move_and_slide()

func _return_to_height(delta: float) -> void:
	# El dron regresa a su Y inicial de patrulla:
	if abs(position.y - initial_height) > 1.0:
		var vertical_dir = sign(initial_height - position.y)
		position.y += vertical_dir * (vertical_speed * delta)

func _patrol_horizontally(delta: float) -> void:
	if raycast_wall.is_colliding() and raycast_wall.get_collider().is_in_group("Floor"):
		patrol_direction *=  -1
	elif position.x > start_position.x + patrol_range:
		patrol_direction = -1
	elif position.x < start_position.x - patrol_range:
		patrol_direction = 1
	
	raycast_wall.target_position = Vector2 (50 * patrol_direction,0)
	position.x += patrol_direction * (horizontal_speed * delta)
	animated_sprite.flip_h = (patrol_direction < 0)

func shoot_bullet() -> void:
	animated_sprite.play("Attack")
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.mask = 2
	bullet.shooter = self # Le indicamos quién la disparó
	
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir  # Asegúrate de que la bala tenga una variable 'direction'
	get_tree().current_scene.add_child(bullet)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.is_alive:
		animated_sprite.play("Walk")
		follow_player = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		animated_sprite.play("Walk Scan")
		follow_player = false

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	if lives <= 0:
		is_alive = false
		animated_sprite.play("Death")
		#collision_shape.position.y = 9
		await animated_sprite.animation_finished  # Espera a que la animación termine
		queue_free()
	else:
		animation_player.play("Hurt")
		emit_signal("add_points", points)  # Enviar la señal a la UI
