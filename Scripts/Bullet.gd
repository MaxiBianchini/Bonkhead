extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var life_timer: Timer = $Timer

@export var speed: float = 245
@export var acceleration: float = 300
@export var time: float = 1.3

var texture_to_apply: Texture2D = null
var direction: Vector2

var shooter: Node = null
var mask: int = 1

func _ready() -> void:
	if texture_to_apply != null:
		sprite.texture = texture_to_apply
	set_collision_mask_value(mask,true)
	life_timer.start(time)
	await life_timer.timeout
	queue_free()

func _physics_process(delta) -> void:
	speed += acceleration * delta
	position += direction * speed * delta

func set_sprite(texture: Texture2D):
	texture_to_apply = texture

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

func delete_mask(number: int) -> void:
	set_collision_mask_value(number, false)

func set_shooter(_shooter: Node) -> void:
	shooter = _shooter

func set_direction(_direction: Vector2) -> void:
	direction = _direction
	rotation = direction.angle()
