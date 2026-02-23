extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast_detection: RayCast2D = $RayCast2D
@onready var raycast_floor: RayCast2D = $RayCast2D2

@onready var idle_sound: AudioStreamPlayer2D = $AudioStream_Idle
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

var direction: int = 1
var is_driving: bool = false
var points: float = 20
var speed: float = 285

signal add_points

const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(50, 27.5)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-50, 27.5)

var gravity_force: float = 1200.0 

var lives: int = 5
var is_alive: bool = true

var damage_tween: Tween

func _ready() -> void:
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Idle")
	if idle_sound: idle_sound.play()
	
	raycast_floor.position = FLOOR_RAYCAST_RIGHT_POS

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity_force * delta
	
	if is_alive:
		_process_alive_state()
	else:
		_process_dead_state(delta)
	
	move_and_slide()

func _process_alive_state() -> void:
	if is_driving:
		if is_on_wall() or not raycast_floor.is_colliding():
			change_direction()
			raycast_floor.force_raycast_update()
			
		velocity.x = speed * direction
	else:
		velocity.x = 0
		
		if raycast_detection.is_colliding():
			var collider = raycast_detection.get_collider()
			if is_instance_valid(collider) and collider.is_in_group("Player"):
				if "is_alive" in collider and collider.is_alive:
					start_driving()

func start_driving() -> void:
	is_driving = true
	animated_sprite.play("Walk")
	
	if idle_sound: idle_sound.stop()
	if walk_sound and not walk_sound.playing:
		walk_sound.play()

func _process_dead_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * delta * 5)

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
	is_driving = false
	
	set_collision_layer_value(3, false)
	
	if idle_sound: idle_sound.stop()
	if walk_sound: walk_sound.stop()
	
	animated_sprite.play("Death")
	if death_sound: death_sound.play()
	
	await animated_sprite.animation_finished
	queue_free()
