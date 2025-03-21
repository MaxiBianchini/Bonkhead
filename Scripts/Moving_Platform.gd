extends Node2D

@export var speed: float = 100.0  # Velocidad de movimiento

var start_position: Vector2  # Guarda la posición inicial
var target_position: Vector2  # Guarda la posición destino
var direction: int = 1  # 1: hacia el destino, -1: regreso
var player: Node2D = null  # Referencia al jugador si está sobre la plataforma

func _ready():
	start_position = global_position  # Guarda la posición inicial
	var marker = find_child("Marker2D", true, false)  # Busca un Marker2D dentro de la plataforma
	
	if marker:
		target_position = marker.global_position  # Usa su posición como destino
	else:
		push_error("No se encontró un Marker2D dentro de la plataforma.")

func _process(delta):
	if target_position == Vector2.ZERO:
		return  # No hay destino válido, evitar errores

	# Movimiento de la plataforma
	global_position = global_position.move_toward(target_position if direction == 1 else start_position, speed * delta)

	# Si hay un jugador sobre la plataforma, moverlo con ella
	if player:
		player.global_position += global_position - global_position.move_toward(target_position if direction == 1 else start_position, speed * delta)

	# Cambio de dirección al llegar al destino
	if global_position.is_equal_approx(target_position) and direction == 1:
		direction = -1
	elif global_position.is_equal_approx(start_position) and direction == -1:
		direction = 1

func _on_body_entered(body):
	if body.is_in_group("Player"):  # Asegura que solo afecte al jugador
		player = body
		player.reparent(self)  # Hace al jugador hijo de la plataforma

func _on_body_exited(body):
	if body == player:
		player.reparent(get_tree().root)  # Quita al jugador de la plataforma
		player = null
