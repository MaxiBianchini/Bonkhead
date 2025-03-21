extends Area2D

@onready var sprite = $"Bullet Sprite"

# Variables para velocidad y dirección
var speed: float = 275
var acceleration: float = 400  # Velocidad adicional por segundo
var direction: Vector2   # Direccion

var shooter: Node = null  # O un tipo más específico si lo deseass
var mask: int = 1
# Timer para autodestruir la bala
var life_time: float = 0.7

func _ready():
	set_collision_mask_value(mask,true)
	
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
	elif body.is_in_group("Floor"):
		queue_free()  # Eliminar la bala
	
	if (body.is_in_group("Enemy") or body.is_in_group("Player")) and body.is_alive:  # Verificar si colisionó con un enemigo o el player
		body.take_damage()  # Función de daño
		queue_free()  # Eliminar la bala
