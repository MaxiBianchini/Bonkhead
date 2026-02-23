extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $Timer
@onready var area2d: Area2D = $Area2D

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var idle_sound: AudioStreamPlayer2D = $AudioStream_Idle 
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

var player: Node2D = null

@export var bullet_sprite: Texture2D
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2 

var detection_width: float = 10000.0
var enemy_is_near: bool = false
var can_shoot: bool = true

var lives: int = 3
var is_alive: bool = true

signal add_points
var points = 25

var damage_tween: Tween

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Idle")
	if idle_sound: idle_sound.play()
	
	player = get_tree().current_scene.get_node_or_null("%Player")

func _physics_process(_delta: float) -> void:
	if not is_alive or not is_instance_valid(player):
		return
		
	var is_player_alive = "is_alive" in player and player.is_alive
	if not is_player_alive:
		return
	
	var distance_x = player.global_position.x - global_position.x
	
	if abs(distance_x) < (detection_width * 0.5):
		if distance_x < 0:
			animated_sprite.flip_h = true
			animated_sprite.position.x = -8
			bullet_offset = Vector2(-25, 5)
			bullet_dir = Vector2.LEFT
		else:
			animated_sprite.flip_h = false
			animated_sprite.position.x = 7
			bullet_offset = Vector2(25, 5)
			bullet_dir = Vector2.RIGHT
	
	if enemy_is_near and can_shoot:
		shoot_bullet()
		can_shoot = false
		shoot_timer.start(0.75)

func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	if shoot_sound: shoot_sound.play()
	
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
		
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	 
	if bullet.has_method("set_direction"):
		bullet.set_direction(bullet_dir)
		
	bullet.global_position = global_position + bullet_offset
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bullet)

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	
	emit_signal("add_points", points)
	
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()
	else:
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

func die() -> void:
	is_alive = false
	
	if idle_sound: idle_sound.stop()
	
	set_collision_layer_value(3, false)
	shoot_timer.stop()
	can_shoot = false
	
	animated_sprite.play("Death")
	if death_sound: death_sound.play()
	
	await animated_sprite.animation_finished
	queue_free()

func _on_body_entered(body: Node) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			animated_sprite.play("Atack")
			enemy_is_near = true

func _on_body_exited(body: Node) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		animated_sprite.play("Idle")
		if idle_sound and not idle_sound.playing: 
			idle_sound.play()
		enemy_is_near = false

func _on_shoot_timer_timeout() -> void:
	if is_alive:
		can_shoot = true
