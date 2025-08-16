extends Area2D

# --- Variables Ajustables ---
@export var speed: float = 350.0      # Velocidad horizontal inicial
@export var gravit: float = 800.0      # Fuerza de gravedad que afecta a la bala
@export var initial_upward_kick: float = -300.0 # Impulso vertical inicial para crear el arco

# --- Variables Internas ---
var velocity: Vector2 = Vector2.ZERO  # Vector para controlar el movimiento
var direction: Vector2 = Vector2.RIGHT # Dirección inicial (será establecida por el jugador)


func _ready() -> void:
	# Iniciamos el temporizador de vida. Cuando termine, la bala se destruirá.
	$LifetimeTimer.start()
	
	# Calculamos la velocidad inicial cuando la bala es creada.
	# El jugador nos dará la dirección horizontal (derecha o izquierda).
	velocity.x = direction.x * speed
	# Le damos un "empujón" hacia arriba para que comience el arco.
	velocity.y = initial_upward_kick


func _physics_process(delta: float) -> void:
	# Aplicamos la gravedad en cada fotograma para crear la curva.
	velocity.y += gravit * delta
	
	# Movemos la bala basándonos en su velocidad actual.
	position += velocity * delta


# Esta función se conectará a la señal "body_entered".
func _on_body_entered(body: Node2D) -> void:
	# Si la bala choca con un enemigo, le hace daño y se destruye.
	if body.is_in_group("Enemy"):
		body.take_damage()
		# (Aquí iría la lógica para que el enemigo reciba daño, si es necesario)
		queue_free() # La bala se autodestruye.
	
	# Si choca con el suelo, también se destruye.
	if body.is_in_group("Floor"):
		queue_free()


# Esta función se conectará a la señal "timeout" del Timer.
func _on_lifetime_timer_timeout() -> void:
	# Si el tiempo de vida se acaba, la bala se destruye.
	queue_free()
