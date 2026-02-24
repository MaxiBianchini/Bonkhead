extends Area2D

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del área interactiva al cargar la escena
func _ready() -> void:
	# Asegura que los elementos visuales estén ocultos por defecto 
	# hasta que el jugador interactúe con el área
	sprite.visible = false
	label.visible = false


# ==============================================================================
# GESTIÓN DE COLISIONES Y EVENTOS (SEÑALES)
# ==============================================================================

# Se dispara automáticamente cuando un cuerpo físico entra en el Area2D
func _on_body_entered(body: Node2D) -> void:
	# Valida que el cuerpo que detonó la colisión sea estrictamente el jugador
	if body.is_in_group("Player"):
		# Despliega la información visual (Ej. un ícono de tecla y un texto)
		sprite.show()
		label.show()

# Se dispara automáticamente cuando un cuerpo físico sale del Area2D
func _on_body_exited(body: Node2D) -> void:
	# Valida que el cuerpo que abandonó el área sea estrictamente el jugador
	if body.is_in_group("Player"):
		# Retira la información visual de la pantalla
		sprite.hide()
		label.hide()
