extends RigidBody2D

# Variables
var player_on_platform := false
var falling := false
var initial_position: Vector2
var collapse_timer: Timer
var reset_timer: Timer

# Referencias a nodos
@onready var area_2d = $Area2D

func _ready() -> void:
	# Guardar la posición inicial cuando la plataforma es creada
	initial_position = position
	# Desactivar la gravedad inicialmente
	gravity_scale = 0
	
	# Crear el temporizador para esperar antes de caer
	collapse_timer = Timer.new()
	collapse_timer.wait_time = 2.0  # 2 segundos antes de colapsar
	collapse_timer.one_shot = true
	add_child(collapse_timer)
	collapse_timer.timeout.connect(_start_falling)
	
	# Crear el temporizador para resetear después de caer
	reset_timer = Timer.new()
	reset_timer.wait_time = 2.0  # 2 segundos de caída antes de resetear
	reset_timer.one_shot = true
	add_child(reset_timer)
	reset_timer.timeout.connect(_reset_platform)
	

func _on_body_entered(body: Node) -> void:
	# Verificar si el cuerpo que entró es el jugador y la plataforma no está cayendo
	if body.name == "Player" and not falling:
		player_on_platform = true
		# Iniciar el temporizador solo si no está ya corriendo
		if collapse_timer.is_stopped():
			collapse_timer.start()

func _start_falling() -> void:
	# Solo iniciar la caída si el jugador sigue en la plataforma
	if player_on_platform:
		gravity_scale = 1  # Activar la gravedad para que caiga
		falling = true
		# Iniciar el temporizador para resetear después de 2 segundos de caída
		reset_timer.start()

func _reset_platform() -> void:
	# Resetear la plataforma a su estado inicial
	gravity_scale = 0  # Desactivar la gravedad
	linear_velocity = Vector2.ZERO  # Detener cualquier movimiento residual
	angular_velocity = 0  # Detener cualquier rotación residual
	position = initial_position  # Volver a la posición inicial
	falling = false
	player_on_platform = false
