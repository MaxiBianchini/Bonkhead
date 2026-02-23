extends Area2D

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var collisionshape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
var is_collected: bool = true


# ==============================================================================
# GESTIÓN DE COLISIONES Y EVENTOS
# ==============================================================================

# Se ejecuta cuando un cuerpo físico (Node2D) entra en el área
func _on_body_entered(body: Node2D) -> void:
	# Cláusula de guarda: Aborta la ejecución según el estado de recolección
	if not is_collected:
		return
	
	# Verifica si la entidad que entró en el área es explícitamente el jugador
	if body.name == "Player":
		# Llama a la función de curación en el jugador y verifica nuevamente la bandera
		if body.increase_life() and is_collected:
			# Actualiza el estado de recolección
			is_collected = true
			
			# Desactiva la colisión de forma segura (diferida) para evitar conflictos en el motor físico
			collisionshape.set_deferred("disabled", true)
			
			# Oculta el gráfico del objeto instantáneamente para dar feedback visual
			sprite.visible = false
			
			# Reproduce el efecto de sonido de recolección
			$AudioStreamPlayer2D.play()
			
			# Detiene la ejecución de esta función hasta que el sonido haya terminado
			await $AudioStreamPlayer2D.finished
			
			# Destruye el nodo liberándolo de la memoria
			queue_free()
