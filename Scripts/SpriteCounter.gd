extends HBoxContainer

# En el Inspector, verás esto como una lista.
# Arrastra tus imágenes en orden: Índice 0 -> Imagen del 0, Índice 1 -> Imagen del 1, etc.
@export var digit_textures: Array[Texture2D]

# Arrastra aquí tu imagen del PUNTO (o dos puntos)
@export var dot_texture: Texture2D

# Cuántos píxeles de separación quieres entre números
@export var padding: int = 1

func _ready() -> void:
	# Aplicamos la separación automáticamente al iniciar
	add_theme_constant_override("separation", padding)

func set_text(text_value: String) -> void:
	# 1. Crear hijos si faltan
	while get_child_count() < text_value.length():
		var rect = TextureRect.new()
		rect.stretch_mode = TextureRect.STRETCH_KEEP
		add_child(rect)
	
	# 2. Asignar texturas
	var children = get_children()
	
	for i in range(children.size()):
		var rect = children[i]
		
		if i < text_value.length():
			rect.visible = true
			var char_ = text_value[i]
			
			# LÓGICA DEL PUNTO
			# Si el caracter es ":" o ".", usamos la textura del punto
			if char_ == ":" or char_ == ".":
				if dot_texture:
					rect.texture = dot_texture
				else:
					print("Advertencia: Falta asignar la imagen 'dot_texture'")
			
			# LÓGICA DE NÚMEROS
			elif char_.is_valid_int():
				var digit_index = int(char_)
				if digit_index >= 0 and digit_index < digit_textures.size():
					rect.texture = digit_textures[digit_index]
		else:
			rect.visible = false
