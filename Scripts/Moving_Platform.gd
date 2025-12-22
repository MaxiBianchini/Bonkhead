extends AnimatableBody2D

var direction: int = 1
@export var speed: float = 100.0
var start_position: Vector2
var target_position: Vector2

func _ready():
	start_position = global_position
	var marker = find_child("Marker2D", true, false)
	
	if marker:
		target_position = marker.global_position
	else:
		push_error("No se encontró un Marker2D dentro de la plataforma.")

func _physics_process(delta) -> void:
	if target_position == Vector2.ZERO:
		return
	
	global_position = global_position.move_toward(target_position if direction == 1 else start_position, speed * delta)
	
	if global_position.is_equal_approx(target_position) and direction == 1:
		direction = -1
	elif global_position.is_equal_approx(start_position) and direction == -1:
		direction = 1
