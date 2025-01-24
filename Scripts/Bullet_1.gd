extends Area2D

@onready var sprite = $"Bullet Sprite"

# Variables para velocidad y dirección
var speed: float = 170
var acceleration: float = 175  # Velocidad adicional por segundo
var direction: Vector2   # Direccion

var shooter: Node = null  # O un tipo más específico si lo deseass

# Timer para autodestruir la bala
var life_time: float = 1.5

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
	# SI LA BALA COLISIONA CON QUIEN LA DISPARÓ, NO HACER NADA
	if body == shooter:
		return
	
	if body.is_in_group("Enemy") or body.is_in_group("Player"):  # Verificar si colisionó con un enemigo
		body.take_damage()  # Función de daño en el enemigo
		queue_free()  # Eliminar la bala
