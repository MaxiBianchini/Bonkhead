extends AnimatableBody2D

@export var speed: float = 100.0  # Velocidad de movimiento
var start_position: Vector2  # Posición inicial
var target_position: Vector2  # Posición destino
var direction: int = 1  # 1: hacia el destino, -1: regreso

func _ready():
	start_position = global_position  # Guarda la posición inicial
	var marker = find_child("Marker2D", true, false)  # Busca un Marker2D dentro de la plataforma
	
	if marker:
		target_position = marker.global_position  # Usa su posición como destino
	else:
		push_error("No se encontró un Marker2D dentro de la plataforma.")

func _physics_process(delta):
	if target_position == Vector2.ZERO:
		return  # No hay destino válido, evitar errores

	# Movimiento de la plataforma
	global_position = global_position.move_toward(target_position if direction == 1 else start_position, speed * delta)

	# Cambio de dirección al llegar al destino
	if global_position.is_equal_approx(target_position) and direction == 1:
		direction = -1
	elif global_position.is_equal_approx(start_position) and direction == -1:
		direction = 1
