extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var life_timer: Timer = $Timer

var speed: float = 175
var acceleration: float = 100
var direction: Vector2

var shooter: Node = null
var mask: int = 1

var time: float = 1.3

func _ready() -> void:
	set_collision_mask_value(mask,true)
	life_timer.start(time)
	await life_timer.timeout
	queue_free()

func _physics_process(delta) -> void:
	if direction.x < 0:
		sprite.flip_h = true
		
	if direction.y != 0:
		sprite.rotation_degrees = -90
	
	speed += acceleration * delta
	
	position += direction * speed * delta

func _on_body_entered(body) -> void:
	if body == shooter:
		return
	elif body.is_in_group("Floor"):
		queue_free()
	
	if (body.is_in_group("Enemy") or body.is_in_group("Player")) and body.is_alive:
		body.take_damage()
		queue_free()

func change_bullet_acceleration(_acceleration: float) -> void:
	acceleration = _acceleration

func change_bullet_speed(_speed: float) -> void:
	speed = _speed

func change_bullet_lifetime(_time: float) -> void:
	time = _time
