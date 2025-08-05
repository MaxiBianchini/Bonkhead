extends CharacterBody2D

# Definimos los estados de nuestro enemigo
enum State {
	INACTIVE,  # Inmóvil y camuflado en la pared
	ACTIVE,    # Despierto, patrullando la pared
	ATTACKING  # Detenido y a punto de disparar
}

# Variable para el estado actual
var state: State = State.INACTIVE

# --- Variables Exportables (para ajustar desde el editor) ---
@export var climb_speed: float = 50.0       # Velocidad de patrulla vertical
@export var patrol_distance: float = 100.0  # Distancia que sube y baja desde su punto inicial
@export var attack_cooldown: float = 2.0    # Tiempo entre ataques

# --- Referencias a Nodos ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var projectile_spawn_point: Marker2D = $ProjectileSpawnPoint

# --- Variables Internas ---
var initial_position: Vector2
var patrol_direction: int = 1

func _ready() -> void:
	# Guardamos la posición inicial para saber a dónde volver
	initial_position = position
	# Configuramos el temporizador de ataque
	attack_timer.wait_time = attack_cooldown

func _physics_process(_delta) -> void:
	# Máquina de estados para controlar el comportamiento.
	match state:
		State.INACTIVE:
			# En estado inactivo, el enemigo está quieto y "camuflado".
			animated_sprite.play("Death")
			velocity = Vector2.ZERO # Nos aseguramos de que no se mueva.

		State.ACTIVE:
			# En estado activo, el enemigo "despierta" y patrulla la pared.
			animated_sprite.play("Walk")
			
			# Lógica de movimiento vertical (patrulla)
			var target_y = initial_position.y + (patrol_distance * patrol_direction)
			
			# Cambiamos de dirección si llegamos al límite de la patrulla
			if (patrol_direction == 1 and position.y >= target_y) or \
			   (patrol_direction == -1 and position.y <= initial_position.y):
				patrol_direction *= -1

			velocity.y = climb_speed * patrol_direction

		State.ATTACKING:
			# Por ahora no hace nada, lo programaremos después.
			pass

	# Aplicamos el movimiento
	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	# Esta función se ejecuta cuando algo entra en el área de detección.
	# Comprobamos si lo que entró es el jugador.
	if body.is_in_group("Player"):
		# Si es el jugador, cambiamos nuestro estado a ACTIVO.
		state = State.ACTIVE


func _on_detection_area_body_exited(body: Node2D) -> void:
	# Esta función se ejecuta cuando algo sale del área de detección.
	# Comprobamos si lo que salió es el jugador.
	
	if body.is_in_group("Player"):
		# Si es el jugador, volvemos al estado INACTIVO.
		state = State.INACTIVE
