extends Area2D

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN DEL PROYECTIL)
# ==============================================================================
@export var speed: float = 245
@export var acceleration: float = 300
@export var time: float = 1.3

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var life_timer: Timer = $Timer

# ==============================================================================
# VARIABLES DE ESTADO Y REFERENCIAS EXTERNAS
# ==============================================================================
var texture_to_apply: Texture2D = null
var direction: Vector2
var shooter: Node = null
var mask: int = 1


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del proyectil al entrar a la escena
func _ready() -> void:
	# Aplica la textura personalizada si fue asignada previamente por el tirador
	if texture_to_apply != null:
		sprite.texture = texture_to_apply
		
	# Configura la capa de colisión inicial
	set_collision_mask_value(mask, true)
	
	# Inicia el temporizador de vida útil y espera a que termine para autodestruirse
	life_timer.start(time)
	life_timer.timeout.connect(queue_free)

# Bucle de físicas: Calcula la aceleración y actualiza la posición
func _physics_process(delta) -> void:
	speed += acceleration * delta
	position += direction * speed * delta


# ==============================================================================
# MÉTODOS DE CONFIGURACIÓN (SETTERS)
# ==============================================================================
# Estas funciones son llamadas por el arma o enemigo que instancia la bala

func set_sprite(texture: Texture2D):
	texture_to_apply = texture

func set_mask(number: int) -> void:
	mask = number

func delete_mask(number: int) -> void:
	set_collision_mask_value(number, false)

func set_shooter(_shooter: Node) -> void:
	shooter = _shooter

func set_direction(_direction: Vector2) -> void:
	direction = _direction
	rotation = direction.angle()


# ==============================================================================
# GESTIÓN DE COLISIONES E IMPACTOS
# ==============================================================================

# Evaluador de impactos cuando un cuerpo entra en el área del proyectil
func _on_body_entered(body) -> void:
	# Cláusulas de guarda: Evita que el proyectil golpee a quien lo disparó
	# o destruye el proyectil si impacta contra el suelo/paredes
	if body == shooter:
		return
	elif body.is_in_group("Floor"):
		queue_free()
	
	# Lógica de daño si el tirador es un Enemigo
	if not is_instance_valid(shooter): return
	
	if shooter.is_in_group("Enemy"):
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()
			
	# Lógica de daño si el tirador es el Jugador
	elif shooter.is_in_group("Player"):
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage()
			queue_free()
