extends Area2D

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
# Guarda la referencia del jugador mientras se encuentre dentro del área de peligro
var player_inside: Node2D = null


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Se ejecuta al instanciar el nodo en la escena
func _ready() -> void:
	# Conecta las señales de colisión dinámicamente, previniendo duplicados
	# en caso de que ya hayan sido conectadas manualmente desde el editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

# Bucle de físicas: Se ejecuta a un ritmo fijo (usualmente 60 veces por segundo)
func _physics_process(_delta: float) -> void:
	# Inflige daño continuo siempre y cuando el jugador esté dentro del área
	if player_inside != null:
		if player_inside.has_method("take_damage"):
			player_inside.take_damage()


# ==============================================================================
# GESTIÓN DE COLISIONES Y EVENTOS (SEÑALES)
# ==============================================================================

# Se dispara cuando un cuerpo físico entra al Area2D
func _on_body_entered(body: Node2D) -> void:
	# Filtra la colisión para reaccionar únicamente ante el jugador
	if body.is_in_group("Player"):
		player_inside = body

# Se dispara cuando un cuerpo físico abandona el Area2D
func _on_body_exited(body: Node2D) -> void:
	# Libera la referencia del jugador al salir, deteniendo el daño continuo
	if body.is_in_group("Player"):
		player_inside = null
