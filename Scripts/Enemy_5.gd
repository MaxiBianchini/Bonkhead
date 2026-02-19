extends CharacterBody2D

enum State {
	INACTIVE,
	ACTIVE,
	DEAD
}

var state: State = State.INACTIVE

@export var climb_speed: float = 50.0       
@export var patrol_distance: float = 65.0  
@export var attack_cooldown: float = 2.0    

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var projectile_spawn_point: Marker2D = $ProjectileSpawnPoint

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var activ_sound: AudioStreamPlayer2D = $AudioStream_Activated
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

@onready var player = get_tree().current_scene.get_node_or_null("%Player")
var points: int = 20
signal add_points

@export var bullet_sprite: Texture2D
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
var initial_position: Vector2
var patrol_direction: int = 1
var is_alive: float = true
var lives: int = 3

func _ready() -> void:
	initial_position = position
	attack_timer.wait_time = attack_cooldown

func _physics_process(_delta) -> void:
	match state:
		State.INACTIVE:
			animated_sprite.play("Idle")
			velocity = Vector2.ZERO 
		
		State.ACTIVE:
			animated_sprite.play("Walk")
			
			var target_y = initial_position.y + (patrol_distance * patrol_direction)
			
			if (patrol_direction == 1 and position.y >= target_y) or \
			   (patrol_direction == -1 and position.y <= initial_position.y):
				patrol_direction *= -1
			
			if patrol_direction == -1: 
				animated_sprite.flip_h = true
				animated_sprite.offset.x = -8
			else: 
				animated_sprite.flip_h = false
				animated_sprite.offset.x = 8
				
			velocity.y = climb_speed * patrol_direction
		
		State.DEAD:
			death_sound.play()
			animated_sprite.play("Death")
			await animated_sprite.animation_finished
			queue_free()
			
	move_and_slide()

func take_damage() -> void:
	if not is_alive: return
	
	lives -= 1
	emit_signal("add_points", points)
	
	var tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		set_collision_layer_value(3,false)
		is_alive = false
		velocity.x = 0
		state = State.DEAD

func _on_attack_timer_timeout() -> void:
	if state == State.ACTIVE and is_alive:
		shoot()

func shoot() -> void:
	var bullet = bullet_scene.instantiate() 
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	
	bullet.global_position = projectile_spawn_point.global_position
	
	var calculated_bullet_dir = Vector2.RIGHT
	
	if projectile_spawn_point.global_position.x < global_position.x:
		calculated_bullet_dir = Vector2.LEFT
	else:
		calculated_bullet_dir = Vector2.RIGHT
		
	shoot_sound.play()
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	 
	if bullet.has_method("set_direction"):
		bullet.set_direction(calculated_bullet_dir)
		
	get_tree().current_scene.add_child(bullet)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if state != State.ACTIVE:
			activ_sound.play()
			state = State.ACTIVE
			attack_timer.start()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		state = State.INACTIVE
		attack_timer.stop()
