extends Area2D

# Variables para la velocidad y dirección de la bala
var bullet_speed: float = 400
var direction: Vector2

func _ready():
	# Conectar la señal de colisión
	connect("body_entered", Callable (self, "_on_body_entered"))

func _physics_process(delta):
	# Movimiento de la bala
	position += direction * bullet_speed * delta

	# Limitar el área donde la bala puede existir
	if position.x > 500 or position.x < -500 or position.y > 500 or position.y < -500:
		queue_free()  # Eliminar la bala si sale del área visible

# Manejar la colisión con un cuerpo
func _on_body_entered(body):
	if body.is_in_group("Enemy"):  # Verificar si colisionó con un enemigo
		body.take_damage()  # Función de daño en el enemigo
		queue_free()  # Eliminar la bala
