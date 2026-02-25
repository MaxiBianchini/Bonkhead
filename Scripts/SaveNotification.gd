extends CanvasLayer

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
# Apuntamos al fondo (TextureRect) y al texto (Label)
@onready var fondo_visual: TextureRect = $TextureRect
@onready var texto_label: Label = $Label


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

func _ready() -> void:
	# Espera 2 segundos mostrando el cartel respetando posibles pausas
	await get_tree().create_timer(2.0, false).timeout
	
	# Crea el animador de desvanecimiento suave (Fade out)
	var tween = create_tween()
	
	# Efecto de transparencia (modulate:a) a ambos nodos en paralelo.
	# Al usar parallel(), Godot ejecuta ambas animaciones exactamente al mismo tiempo,
	# garantizando que el texto y el fondo desaparezcan en perfecta sincronía.
	tween.tween_property(fondo_visual, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(texto_label, "modulate:a", 0.0, 0.5)
	
	# Esperamos a que el conjunto de animaciones termine por completo
	await tween.finished
	
	# Libera la memoria destruyendo el CanvasLayer y todos sus hijos
	queue_free()
