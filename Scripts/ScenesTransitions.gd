extends CanvasLayer

# ==============================================================================
# VARIABLES DE ESTADO GLOBALES
# ==============================================================================
# Bandera de control para saber si actualmente hay una transición en curso
var is_transitioning: bool = false

@onready var anim_player = $AnimationPlayer

# ==============================================================================
# GESTIÓN DE TRANSICIÓN DE ESCENAS
# ==============================================================================

# Orquesta la animación de fundido, el cambio de escena y la reapertura visual
func change_scene(target: String) -> void:
	# Marca el inicio de la transición
	is_transitioning = true
	
	# 1. Fundido de entrada: Oscurece la pantalla usando la animación "fade_in"
	anim_player.play("fade_in")
	await anim_player.animation_finished
	
	# 2. Cambio de escena: Intercambia el árbol de nodos por la escena objetivo
	get_tree().change_scene_to_file(target)
	
	# 3. Fundido de salida: Aclara la pantalla reproduciendo la animación a la inversa
	anim_player.play_backwards("fade_in")
	await anim_player.animation_finished
	
	# Marca el final de la transición, liberando el estado
	is_transitioning = false
