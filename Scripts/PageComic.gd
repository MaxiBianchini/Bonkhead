extends Area2D

# ==============================================================================
# SEÑALES
# ==============================================================================
# Emitida para notificar a otros sistemas (como el SceneManager o la UI) 
# que el jugador ha completado el nivel.
signal winLevel


# ==============================================================================
# GESTIÓN DE COLISIONES Y EVENTOS
# ==============================================================================

# Se ejecuta automáticamente cuando un cuerpo físico (Node2D) entra en el área
func _on_body_entered(body: Node2D) -> void:
	# Verifica que la entidad que interactúa sea estrictamente el jugador
	if body.is_in_group("Player"):
		
		# Notifica el estado de victoria al resto del juego
		emit_signal("winLevel")
		
		# Inicia la reproducción del efecto de sonido de victoria
		$AudioStreamPlayer2D.play()
		
		# Pausa la ejecución del script hasta que el audio termine por completo
		await $AudioStreamPlayer2D.finished
		
		# Destruye el nodo liberando la memoria una vez finalizado el sonido
		queue_free()
