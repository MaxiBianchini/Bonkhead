extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast_floor: RayCast2D = $RayCast2D
@onready var shoot_timer: Timer = $Timer

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

@onready var player = get_tree().current_scene.get_node_or_null("%Player")  

const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(22, 12)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-5, 12)

var direction: int = 1
const gravity: int = 2000
const movement_velocity: int = 60

signal add_points
var points: int = 20

var lives: int = 3
var is_alive: bool = true
var enemy_is_near: bool = false

@export var bullet_sprite: Texture2D # Aquí arrastras el asset específico de este enemigo
var bullet_scene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2

var can_shoot: bool = true

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Walk")
	walk_sound.play()

func _physics_process(delta) -> void:
	if is_alive:
		if enemy_is_near:
			update_sprite_direction(player.position.x < position.x)
		else:
			update_sprite_direction(velocity.x < 0)
		
		if not is_on_floor():
			velocity.y += gravity * delta
		
		if is_on_wall() or not raycast_floor.is_colliding():
			direction *= -1
			raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS
		
		if not enemy_is_near:
			velocity.x = direction * movement_velocity
		else:
			velocity.x = 0
		
		move_and_slide()
		
		if enemy_is_near and player and player.is_alive:
			animated_sprite.play("Shoot")
			if can_shoot:
				shoot_bullet()
				shoot_sound.play()
				can_shoot = false
				shoot_timer.start(0.75)
		elif is_alive:
			animated_sprite.play("Walk")
			#$AudioStream_Walk.play() CAMBIAR LA FORMA EN ALQUE SE DA CUENTA QUE VOLVIO A CAMINAR DESPUES DE DISPARAR
			enemy_is_near = false

func update_sprite_direction(is_facing_left: bool) -> void:
	var offset = 10
	if is_facing_left:
		animated_sprite.flip_h = true
		animated_sprite.position.x = -offset
		collision_shape.position.x = offset
		bullet_offset = Vector2(-15, -9)
		bullet_dir = Vector2.LEFT
	else:
		animated_sprite.flip_h = false
		animated_sprite.position.x = offset
		collision_shape.position.x = offset
		bullet_offset = Vector2(35, -9)
		bullet_dir = Vector2.RIGHT

func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	 
	if bullet.has_method("set_direction"):
		bullet.set_direction( bullet_dir)
	bullet.position = position + bullet_offset
	
	get_tree().current_scene.add_child(bullet)

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
		velocity.x = 0
		animated_sprite.play("Death")
		death_sound.play()
		await death_sound.finished
		queue_free()
		
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.is_alive:
		enemy_is_near = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body.is_alive:
		enemy_is_near = false

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
