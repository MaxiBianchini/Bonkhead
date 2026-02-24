extends HBoxContainer

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN VISUAL)
# ==============================================================================
# Arreglo que contiene las texturas de los dígitos (idealmente del 0 al 9 en orden)
@export var digit_textures: Array[Texture2D]

# Textura utilizada para representar separadores como puntos o dos puntos
@export var dot_texture: Texture2D

# Espaciado horizontal entre cada dígito/carácter
@export var padding: int = 1


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del contenedor al cargar la escena
func _ready() -> void:
	# Aplica el espaciado definido al HBoxContainer sobrescribiendo su tema por defecto
	add_theme_constant_override("separation", padding)


# ==============================================================================
# LÓGICA DE ACTUALIZACIÓN DE INTERFAZ (RENDERIZADO DE TEXTO)
# ==============================================================================

# Actualiza dinámicamente los TextureRects hijos para representar el texto ingresado
func set_text(text_value: String) -> void:
	# 1. Creación dinámica de nodos:
	# Instancia nuevos TextureRect si el texto entrante es más largo que la cantidad actual de hijos
	while get_child_count() < text_value.length():
		var rect = TextureRect.new()
		rect.stretch_mode = TextureRect.STRETCH_KEEP
		add_child(rect)
	
	# Captura todos los nodos hijos (los preexistentes y los recién creados)
	var children = get_children()
	
	# 2. Asignación de texturas y visibilidad:
	# Itera sobre la totalidad de los hijos en el contenedor
	for i in range(children.size()):
		var rect = children[i]
		
		# Si el índice corresponde a un carácter dentro de la longitud del texto entrante
		if i < text_value.length():
			rect.visible = true
			var char_ = text_value[i]
			
			# Evaluación de caracteres separadores (Ej: Reloj "12:30" o decimales "1.5")
			if char_ == ":" or char_ == ".":
				if dot_texture:
					rect.texture = dot_texture
				else:
					print("Advertencia: Falta asignar la imagen 'dot_texture'")
			
			# Evaluación de caracteres numéricos
			elif char_.is_valid_int():
				var digit_index = int(char_)
				
				# Valida de forma segura que el dígito exista en el arreglo de texturas
				if digit_index >= 0 and digit_index < digit_textures.size():
					rect.texture = digit_textures[digit_index]
					
		# 3. Ocultamiento de nodos sobrantes:
		# Si el texto nuevo es más corto, oculta los TextureRect excedentes en lugar de borrarlos
		else:
			rect.visible = false
