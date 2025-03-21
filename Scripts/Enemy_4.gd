extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var raycast_detection = $RayCast2D
@onready var raycast_floor = $RayCast2D2

# Variables para el movimiento
var direction: int = 1 # 1 para derecha, -1 para izquierda
var is_driving: bool = false

# Constantes para el movimiento
var speed: float = 250

signal add_points
var points = 35

# Posiciones iniciales del raycast_floor para derecha e izquierda
const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(50, 27.5)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-50, 27.5)

# Variables para controlar la vida
var lives: int = 5
var is_alive: bool = true

func _ready():
	var sprite = $AnimatedSprite2D 
	sprite.material = sprite.material.duplicate()
	
	animated_sprite.play("Idle")	# Reproducir la animación Idle al iniciar
	raycast_floor.position = FLOOR_RAYCAST_RIGHT_POS # Configurar la posición inicial del floor_raycast

func _physics_process(delta):
	if not is_alive:
		return # No hacer nada si el enemigo no está vivo
	
	# Detectar colisión con pared o ausencia de suelo
	if is_on_wall() or not raycast_floor.is_colliding():
		change_direction()
	
	# Controlar el movimiento basado en la variable is_driving
	if is_driving:
		# Movimiento horizontal del Enemy
		velocity.x = speed  * direction
	elif raycast_detection.is_colliding():	# Detectar colisión con el jugador
		var collider = raycast_detection.get_collider()
		if collider.is_in_group("Player"):
			# Reproducir la animación Walk y detener el movimiento
			animated_sprite.play("Walk")
			is_driving = true
	
	# Siempre aplica la gravedad
	velocity.y += 20
	move_and_slide()

# Función para cambiar la dirección del enemigo
func change_direction() -> void:
	direction *= -1
	update_sprite_direction()

# Controlador de la direccion del SpriteE
func update_sprite_direction():
 # Voltear el sprite horizontalmente según la dirección
	animated_sprite.flip_h = direction < 0
	# Actualizar la posición del floor_raycast para detectar el suelo en la nueva dirección
	raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS

# Función para manejar el daño recibido
func take_damage() -> void:
	if not is_alive:
		return # No hacer nada si ya está muerto
	
	lives -= 1
	emit_signal("add_points", points)  # Enviar la señal a la UI
	if lives <= 0:
		is_alive = false
		is_driving = false
		velocity.x = 0
		animated_sprite.play("Death") # Reproducir la animación de muerte
	else:
		animation_player.play("Hurt") # Reproducir la animación de daño

# Función para manejar la finalización de las animaciones
func _on_animation_finished() -> void:
	if animated_sprite.animation == "Death":
		queue_free()
