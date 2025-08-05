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

func _physics_process(delta: float) -> void:
	# Aquí irá la lógica de nuestra máquina de estados
	pass
