extends CharacterBody2D

@onready var shoot_timer: Timer = $Timer
@onready var raycast_wall: RayCast2D = $RayCast2D
@onready var raycast_floor: RayCast2D = $RayCast2D2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var player = get_tree().current_scene.get_node_or_null("%Player") # Encuentra al jugador en la escena

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
		if horizontal_dir < 0.0:
			bullet_dir = Vector2.LEFT
			bullet_offset = Vector2(-14, 12.5)
		else:
			bullet_dir = Vector2.RIGHT
			bullet_offset = Vector2(14, 12.5)
	else:
		velocity.x = 0
		animated_sprite.flip_h = (dx < 0.0)
		if can_shoot:
			shoot_bullet()
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
	var bullet = bullet_scene.instantiate() as Area2D
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	 
	if bullet.has_method("set_direction"):
		bullet.set_direction( bullet_dir)
	bullet.position = position + bullet_offset
	
	get_tree().current_scene.add_child(bullet)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.is_alive and is_alive:
		animated_sprite.play("Walk")
		follow_player = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		animated_sprite.play("Walk Scan")
		follow_player = false

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	if lives <= 0:
		is_alive = false
		animated_sprite.play("Death")
		collision_shape.position.y = 9
		velocity.x = 0
		await animated_sprite.animation_finished
		queue_free()
	else:
		animation_player.play("Hurt")
		emit_signal("add_points", points)
		
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
