extends Area2D

@export var speed: float = 400.0
@export var max_pierces: int = 3
@export var time: float = 3
@onready var life_timer: Timer = $Timer

@onready var sprite: Sprite2D = $Sprite2D
var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
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

func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
		
	if body.is_in_group("Floor") or body.is_in_group("Grabbable Wall") or body.is_in_group("Jumpeable Wall"):
		queue_free()
	
	if shooter.is_in_group("Enemy"):
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()
			
	elif shooter.is_in_group("Player"):
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage()
		
		max_pierces -= 1
		
		if max_pierces <= 0:
			queue_free()

func set_mask(number: int) -> void:
	mask = number

func set_shooter(shooter_node: Node2D) -> void:
	shooter = shooter_node

func set_direction(dir: Vector2) -> void:
	direction = dir
