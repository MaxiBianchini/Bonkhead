extends Area2D

# --- Variables Ajustables ---
@export var speed: float = 250.0
@export var _gravity: float = 800.0 # Renombré 'gravit' a 'gravity' por claridad
@export var initial_upward_kick: float = -250.0

# --- AÑADE ESTAS LÍNEAS ---
@export var aim_up_speed: float = 100.0         # Velocidad horizontal REDUCIDA al apuntar arriba
@export var aim_up_kick: float = -400.0         # Impulso vertical AUMENTADO al apuntar arriba

@export var time: float = 1.3
@onready var life_timer: Timer = $Timer

# --- Variables Internas ---
var velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var is_aimed_up: bool = false # La nueva bandera

var shooter: Node = null
var mask: int = 1

func _ready() -> void:
	if is_aimed_up:
		# Usamos los valores para el disparo hacia arriba (más alto, más corto)
		velocity.x = direction.x * aim_up_speed
		velocity.y = aim_up_kick
	else:
		# Usamos los valores normales para el disparo estándar
		velocity.x = direction.x * speed
		velocity.y = initial_upward_kick
	
	set_collision_mask_value(mask,true)
	life_timer.start(time)
	await life_timer.timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Aplicamos la gravedad en cada fotograma para crear la curva.
	velocity.y += _gravity * delta
	# Movemos la bala basándonos en su velocidad actual.
	position += velocity * delta

# Esta función se conectará a la señal "body_entered".
func _on_body_entered(body: Node2D) -> void:
	# Si la bala choca con un enemigo, le hace daño y se destruye.
	if body == shooter:
		return
	elif body.is_in_group("Floor"):
		queue_free()
	
	if shooter.is_in_group("Enemy"):
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()
			
	elif shooter.is_in_group("Player"):
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()

func set_mask(number: int) -> void:
	mask = number

func set_shooter(_shooter: Node) -> void:
	shooter = _shooter

func set_direction(_direction: Vector2) -> void:
	direction = _direction

func set_aim_state(_aim: bool) -> void:
	is_aimed_up = _aim
