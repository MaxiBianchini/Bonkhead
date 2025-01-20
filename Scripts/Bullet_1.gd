extends Area2D

# Variables para velocidad y dirección
var speed: float = 170
var acceleration: float = 175  # Velocidad adicional por segundo
var direction: Vector2   # Direccion

# Timer para autodestruir la bala
var life_time: float = 1.5

@onready var sprite = $"Bullet Sprite"

func _ready():
	# Configura el timer para autodestruir la bala
	await get_tree().create_timer(life_time).timeout
	queue_free()

func _physics_process(delta):
	
	if direction.x < 0:
		sprite.flip_h = true
		
	if direction.y != 0:
		sprite.rotation_degrees = -90
	
	# Aumenta gradualmente la velocidad de la bala
	speed += acceleration * delta
	
	# Mueve la bala en la dirección indicada
	position += direction * speed * delta

# Manejar la colisión con un cuerpo
func _on_body_entered(body):
	if body.is_in_group("Enemy") or body.is_in_group("Player"):  # Verificar si colisionó con un enemigo
		body.take_damage()  # Función de daño en el enemigo
		queue_free()  # Eliminar la bala
