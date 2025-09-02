extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shoot_timer: Timer = $Timer
@onready var area2d: Area2D = $Area2D

@onready var player = get_tree().current_scene.get_node_or_null("%Player")

var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2 

var detection_width: float = 10000.0
var detection_height: float = 180.0
var enemy_is_near: bool = false
var can_shoot: bool = true

var lives: int = 3
var is_alive: bool = true

signal add_points
var points = 25

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Idle")

func _physics_process(_delta: float) -> void:
	if not (player and is_alive):
		return
	
	var detection_rect = Rect2(
		position - Vector2(detection_width * 0.5, detection_height * 0.5),
		Vector2(detection_width, detection_height)
	)
	
	if detection_rect.has_point(player.position):
		if player.position.x < position.x:
			animated_sprite.flip_h = true
			animated_sprite.position = Vector2(-8, 0)
			bullet_offset = Vector2(-25, 5)
			bullet_dir = Vector2.LEFT
		else:
			animated_sprite.flip_h = false
			animated_sprite.position = Vector2(7, 0)
			bullet_offset = Vector2(25, 5)
			bullet_dir = Vector2.RIGHT
	
	if enemy_is_near and player.is_alive:
		if can_shoot:
			shoot_bullet()
			can_shoot = false
			shoot_timer.start(0.75)

func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
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
	
	if lives <= 0:
		is_alive = false
		animated_sprite.play("Death")
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

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.is_alive and is_alive:
		animated_sprite.play("Atack")
		enemy_is_near = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		animated_sprite.play("Idle")
		enemy_is_near = false

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
