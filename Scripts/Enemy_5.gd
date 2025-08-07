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
@export var patrol_distance: float = 65.0  # Distancia que sube y baja desde su punto inicial
@export var attack_cooldown: float = 2.0    # Tiempo entre ataques
@export var bullet_dir: Vector2 = Vector2.RIGHT

# --- Referencias a Nodos ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var projectile_spawn_point: Marker2D = $ProjectileSpawnPoint

var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")

# --- Variables Internas ---
var initial_position: Vector2
var patrol_direction: int = 1
var bullet_offset: Vector2 = Vector2(20,0)

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
			animated_sprite.play("Idle")
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
			# Al atacar, el enemigo se detiene y reproduce su animación.
			velocity = Vector2.ZERO
			animated_sprite.play("Attack")

	# Aplicamos el movimiento
	move_and_slide()

func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.mask = 2
	bullet.shooter = self
	 
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir
	get_tree().current_scene.add_child(bullet)

func _on_detection_area_body_entered(body: Node2D) -> void:
	# Esta función se ejecuta cuando algo entra en el área de detección.
	# Comprobamos si lo que entró es el jugador.
	if body.is_in_group("Player"):
		# Si es el jugador, cambiamos nuestro estado a ACTIVO.
		state = State.ACTIVE
		# Iniciamos el temporizador de ataque cuando el jugador entra.
		attack_timer.start()


func _on_detection_area_body_exited(body: Node2D) -> void:
	# Esta función se ejecuta cuando algo sale del área de detección.
	# Comprobamos si lo que salió es el jugador.
	
	if body.is_in_group("Player"):
		# Si es el jugador, volvemos al estado INACTIVO.
		state = State.INACTIVE
		# Detenemos el temporizador si el jugador se aleja.
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	# Cuando el temporizador se agota, cambiamos al estado de ataque.
	# Solo atacamos si seguimos en estado ACTIVO (no si el jugador ya se fue).
	if state == State.ACTIVE:
		state = State.ATTACKING

func _on_animated_sprite_animation_finished() -> void:
	# Esta función se llama cuando CUALQUIER animación termina.
	# Nos aseguramos de que la que terminó fue la de "attack".
	if animated_sprite.animation == "Attack":
		shoot_bullet()
		# 1. Creamos la instancia de la bala.
		#var bullet = bullet_scene.instantiate() as Area2D
		
		# 2. La posicionamos en el punto de spawn.
		#get_tree().current_scene.add_child(bullet)
		#bullet.global_position = projectile_spawn_point.global_position
		
		# 3. Le damos una dirección (asumimos que el enemigo mira a la derecha).
		#    Si tu sprite mira a la izquierda, cambia a Vector2.LEFT.
		#bullet.direction = Vector2.RIGHT
		
		# 4. Volvemos al estado activo y reiniciamos el temporizador para el próximo ataque.
		state = State.ACTIVE
		attack_timer.start()
