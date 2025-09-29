extends CharacterBody2D

# Definimos los estados de nuestro enemigo
enum State {
	INACTIVE,  # Inmóvil y camuflado en la pared
	ACTIVE,    # Despierto, patrullando la pared
	DEAD
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
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var activ_sound: AudioStreamPlayer2D = $AudioStream_Activated
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

@onready var player = get_tree().current_scene.get_node_or_null("%Player")

var points: int = 20
signal add_points

# --- Variables Internas ---
var initial_position: Vector2
var patrol_direction: int = 1
var bullet_offset: Vector2 = Vector2(20,0)
var is_alive: float = true
var lives: int = 3

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
			activ_sound.play()
			animated_sprite.play("Walk")
			
			# Lógica de movimiento vertical (patrulla)
			var target_y = initial_position.y + (patrol_distance * patrol_direction)
			
			# Cambiamos de dirección si llegamos al límite de la patrulla
			if (patrol_direction == 1 and position.y >= target_y) or \
			   (patrol_direction == -1 and position.y <= initial_position.y):
				patrol_direction *= -1
			
			if patrol_direction == -1: # -1 significa que va hacia ARRIBA
				animated_sprite.flip_h = true
				animated_sprite.offset.x = -8
			else: # 1 significa que va hacia ABAJO
				animated_sprite.flip_h = false
				animated_sprite.offset.x = 8
				
			velocity.y = climb_speed * patrol_direction
		
		State.DEAD:
			death_sound.play()
			animated_sprite.play("Death")
			await animated_sprite.animation_finished
			queue_free()

	# Aplicamos el movimiento
	move_and_slide()

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	if lives <= 0:
		is_alive = false
		velocity.x = 0
		state = State.DEAD
		
	else:
		animation_player.play("Hurt")
		emit_signal("add_points", points)
		



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
