extends Area2D

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN)
# ==============================================================================
@export var flip: bool = false

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var signpost: Sprite2D = $Sprite2D

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
var is_activated: bool = false


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del Checkpoint al cargar la escena
func _ready() -> void:
	# Aplica la orientación del sprite según la configuración del inspector
	animated_sprite.flip_h = flip
	
	# Verifica si ya existe un checkpoint activo guardado en el gestor global
	if SceneManager.has_active_checkpoint:
		# Compara la posición de este nodo con la posición guardada (usando
		# distance_squared_to por ser más óptimo matemáticamente).
		# Si están prácticamente en el mismo lugar, este es el checkpoint activo.
		if global_position.distance_squared_to(SceneManager.active_checkpoint_pos) < 100:
			# Restaura el estado visual y lógico a "activado"
			is_activated = true
			signpost.visible = true
			animated_sprite.play("default")


# ==============================================================================
# GESTIÓN DE COLISIONES Y ACTIVACIÓN
# ==============================================================================

# Señal disparada cuando una entidad entra en el área del checkpoint
func _on_body_entered(body: Node2D) -> void:
	# Cláusula de seguridad: Solo el jugador puede activarlo, 
	# y solo si no ha sido activado previamente.
	if body.is_in_group("Player") and not is_activated:
		activate_me()

# Ejecuta los efectos visuales y guarda el progreso globalmente
func activate_me():
	# Despliegue visual del punto de control
	signpost.visible = true
	is_activated = true
	animated_sprite.play("default")
	
	# Envía la posición actual y los puntos al Singleton para el guardado global
	SceneManager.activate_checkpoint(global_position, SceneManager.points)
