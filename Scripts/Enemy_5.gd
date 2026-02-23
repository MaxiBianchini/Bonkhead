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

var player: Node2D = null

var points: int = 30
signal add_points

@export var bullet_sprite: Texture2D
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
var initial_position: Vector2
var patrol_direction: int = 1

var is_alive: bool = true 
var lives: int = 3

var damage_tween: Tween

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	initial_position = global_position
	attack_timer.wait_time = attack_cooldown
	
	player = get_tree().current_scene.get_node_or_null("%Player")

func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
		
	match state:
		State.INACTIVE:
			if animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")
			velocity = Vector2.ZERO 
		
		State.ACTIVE:
			var player_valid = is_instance_valid(player) and "is_alive" in player and player.is_alive
			if not player_valid:
				_deactivate_enemy()
				return
			
			if animated_sprite.animation != "Walk":
				animated_sprite.play("Walk")
			
			if (patrol_direction == 1 and global_position.y >= initial_position.y + patrol_distance) or \
			   (patrol_direction == -1 and global_position.y <= initial_position.y):
				patrol_direction *= -1
			
			if patrol_direction == -1: 
				animated_sprite.flip_h = true
				animated_sprite.offset.x = -8
				
			else: 
				animated_sprite.flip_h = false
				animated_sprite.offset.x = 8
				
			velocity.y = climb_speed * patrol_direction
			velocity.x = 0
			
	move_and_slide()

func _deactivate_enemy() -> void:
	if state != State.DEAD:
		state = State.INACTIVE
		attack_timer.stop()

func take_damage() -> void:
	if not is_alive: return
	
	lives -= 1
	
	emit_signal("add_points", points)
	
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()

func die() -> void:
	is_alive = false
	state = State.DEAD
	velocity = Vector2.ZERO
	
	set_collision_layer_value(3, false)
	attack_timer.stop()
	
	animated_sprite.play("Death")
	if death_sound: death_sound.play()
	
	await animated_sprite.animation_finished
	queue_free()

func _on_attack_timer_timeout() -> void:
	if state == State.ACTIVE and is_alive:
		shoot()

func shoot() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	
	bullet.global_position = projectile_spawn_point.global_position
	
	var calculated_bullet_dir = Vector2.RIGHT
	if projectile_spawn_point.global_position.x < global_position.x:
		calculated_bullet_dir = Vector2.LEFT
		
	if shoot_sound: shoot_sound.play()
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	if bullet.has_method("set_direction"):
		bullet.set_direction(calculated_bullet_dir)
		
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bullet)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			if state != State.ACTIVE:
				if activ_sound: activ_sound.play()
				state = State.ACTIVE
				attack_timer.start()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and body.is_in_group("Player"):
		_deactivate_enemy()
