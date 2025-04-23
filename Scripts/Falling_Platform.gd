extends RigidBody2D

@onready var collapse_timer: Timer = $Timer2
@onready var reset_timer: Timer = $Timer

# Variables
var player_on_platform: bool = false
var falling: bool = false
var initial_position: Vector2

func _ready() -> void:
	# Guardar la posición inicial cuando la plataforma es creada
	initial_position = position
	# Desactivar la gravedad inicialmente
	gravity_scale = 0

func _on_body_entered(body: Node) -> void:
	# Verificar si el cuerpo que entró es el jugador y la plataforma no está cayendo
	if body.name == "Player" and not falling:
		player_on_platform = true
		# Iniciar el temporizador solo si no está ya corriendo
		if collapse_timer.is_stopped():
			collapse_timer.start()

func start_falling() -> void:
	# Solo iniciar la caída si el jugador sigue en la plataforma
	if player_on_platform:
		gravity_scale = 1  # Activar la gravedad para que caiga
		falling = true
		# Iniciar el temporizador para resetear después de 2 segundos de caída
		reset_timer.start()

func reset_platform() -> void:
	# Resetear la plataforma a su estado inicial
	gravity_scale = 0  # Desactivar la gravedad
	linear_velocity = Vector2.ZERO  # Detener cualquier movimiento residual
	angular_velocity = 0  # Detener cualquier rotación residual
	position = initial_position  # Volver a la posición inicial
	falling = false
	player_on_platform = false
