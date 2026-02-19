extends CharacterBody2D

@export var fuse_time: float = 1.0
@export var damage: int = 2

@onready var explosion_area: Area2D = $ExplosionArea
@onready var sprite = $AnimatedSprite2D # O AnimatedSprite2D
@onready var sound = $AudioStream_Exploit

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_exploded: bool = false

func _ready() -> void:
	get_tree().create_timer(fuse_time).timeout.connect(explode)
	sprite.play("Idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0, 10.0)
	
	move_and_slide()

func explode() -> void:
	if has_exploded: return
	has_exploded = true

	set_physics_process(false)
	sound.play()
	sprite.play("Explotion")
	
	explosion_area.monitoring = true
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(false, damage)
	
	await sprite.animation_finished
	queue_free()
