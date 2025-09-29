extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var life_timer: Timer = $Timer

@export var speed: float = 245
@export var acceleration: float = 300
@export var time: float = 1.3
var direction: Vector2

var shooter: Node = null
var mask: int = 1

func _ready() -> void:
	if direction.y != 0:
		sprite.rotation_degrees = -90
	elif direction.x < 0:
		sprite.flip_h = true
	
	set_collision_mask_value(mask,true)
	life_timer.start(time)
	await life_timer.timeout
	queue_free()

func _physics_process(delta) -> void:
	speed += acceleration * delta
	position += direction * speed * delta

func _on_body_entered(body) -> void:
	if body == shooter:
		return
	elif body.is_in_group("Floor"):
		queue_free()
	
	if shooter.is_in_group("Enemy"):
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()
			
	elif shooter.is_in_group("Player"):
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()

func set_mask(number: int) -> void:
	mask = number

func set_shooter(_shooter: Node) -> void:
	shooter = _shooter

func set_direction(_direction: Vector2) -> void:
	direction = _direction
