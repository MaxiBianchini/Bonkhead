extends CharacterBody2D

@onready var shoot_timer: Timer = $Timer
@onready var raycast_wall: RayCast2D = $RayCast2D
@onready var raycast_floor: RayCast2D = $RayCast2D2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

@onready var player = get_tree().current_scene.get_node_or_null("%Player") # Encuentra al jugador en la escena

@export var bullet_sprite: Texture2D # Aquí arrastras el asset específico de este enemigo
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2

var can_shoot: bool = true          # Indica si el enemigo puede disparar

var horizontal_speed: float = 100.0
var vertical_speed: float = 80.0
var patrol_range: float = 200.0
var patrol_direction: int = 1

var initial_height: float
var start_position: Vector2
var follow_player: bool = false

var chase_stop_distance_x: float = 80.0
var hover_offset_y: float = 25.0

var lives: int = 3
var is_alive: bool = true

signal add_points
var points = 30

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Walk Scan")
	walk_sound.play()
	start_position = position
	initial_height = position.y

func _physics_process(delta: float) -> void:
	if not is_alive:
		apply_gravity()
		return
	
	if follow_player and player.is_alive:
		if raycast_wall.is_colliding() and raycast_wall.get_collider().is_in_group("Floor") or raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Floor"):
			follow_player = false
		else:
			chase_player(delta)
	else:
		return_to_height(delta)
		patrol_horizontally(delta)

func apply_gravity() -> void:
	velocity.y += 15.0
	move_and_slide()

func chase_player(delta: float) -> void:
	var dx = player.position.x - position.x
	var desired_y = player.position.y - hover_offset_y
	
	if abs(dx) > chase_stop_distance_x:
		var horizontal_dir = sign(dx)
		animated_sprite.flip_h = (horizontal_dir < 0.0)
		velocity.x = horizontal_dir * horizontal_speed 
		
	else:
		velocity.x = 0
		animated_sprite.flip_h = (dx < 0.0)
		bullet_offset = Vector2(-10,15) if (dx < 0.0) else Vector2(10,15)
		if can_shoot:
			shoot_bullet()
			shoot_sound.play()
			can_shoot = false
			shoot_timer.start(1.0)  
		
	var vertical_dir = sign(desired_y - position.y)
	if abs(position.y - desired_y) > 2.0:
		position.y += vertical_dir * vertical_speed * delta
		
	move_and_slide()

func return_to_height(delta: float) -> void:
	if abs(position.y - initial_height) > 1.0:
		var vertical_dir = sign(initial_height - position.y)
		position.y += vertical_dir * (vertical_speed * delta)

func patrol_horizontally(delta: float) -> void:
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
	
	# Asegúrate de que el jugador todavía existe antes de disparar
	if not is_instance_valid(player):
		return

	var bullet = bullet_scene.instantiate()
	
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	
	# 1. Calculamos la dirección normalizada desde el enemigo hacia el jugador.
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# 2. Configuramos la bala con la nueva dirección.
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(2)
	
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction_to_player) # Usamos la dirección calculada

	# 3. Posicionamos la bala y la añadimos a la escena.
	bullet.position = position + bullet_offset
	get_tree().current_scene.add_child(bullet)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.is_alive and is_alive:
		animated_sprite.play("Walk")
		follow_player = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		animated_sprite.play("Walk Scan")
#		walk_sound.play()
		follow_player = false

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	emit_signal("add_points", points)
	
	# EFECTO DE DAÑO POR CÓDIGO
	var tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1) # Rojo puro
	
	# Volviendo a blanco en 0.2 segundos
	# set_trans(Tween.TRANS_SINE) hace que se vea suave
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		set_collision_layer_value(3,false)
		is_alive = false
		animated_sprite.play("Death")
		collision_shape.position.y = 9
		velocity.x = 0
		death_sound.play()
		await animated_sprite.animation_finished
		queue_free()
		
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
