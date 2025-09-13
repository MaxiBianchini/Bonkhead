extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var raycast_detection: RayCast2D = $RayCast2D
@onready var raycast_floor: RayCast2D = $RayCast2D2

@onready var crash_sound: AudioStreamPlayer2D = $AudioStream_Crash
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

var direction: int = 1
var is_driving: bool = false
var points: float = 35
var speed: float = 250

signal add_points

const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(50, 27.5)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-50, 27.5)

var lives: int = 5
var is_alive: bool = true

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Idle")
	walk_sound.play()
	
	raycast_floor.position = FLOOR_RAYCAST_RIGHT_POS

func _physics_process(_delta) -> void:
	if not is_alive:
		return
	
	if is_on_wall() or not raycast_floor.is_colliding():
		change_direction()
	
	if is_driving:
		velocity.x = speed  * direction
	elif raycast_detection.is_colliding():
		var collider = raycast_detection.get_collider()
		if collider.is_in_group("Player"):
			animated_sprite.play("Walk")
			is_driving = true
	
	velocity.y += 20
	move_and_slide()

func change_direction() -> void:
	direction *= -1
	update_sprite_direction()

func update_sprite_direction() -> void:
	animated_sprite.flip_h = direction < 0
	raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	
	if lives <= 0:
		is_alive = false
		is_driving = false
		velocity.x = 0
		animated_sprite.play("Death")
		death_sound.play()
		await animated_sprite.animation_finished
		queue_free()
	else:
		animation_player.play("Hurt")
		emit_signal("add_points", points)
