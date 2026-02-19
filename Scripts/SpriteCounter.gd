extends HBoxContainer

@export var digit_textures: Array[Texture2D]
@export var dot_texture: Texture2D
@export var padding: int = 1

func _ready() -> void:
	add_theme_constant_override("separation", padding)

func set_text(text_value: String) -> void:
	while get_child_count() < text_value.length():
		var rect = TextureRect.new()
		rect.stretch_mode = TextureRect.STRETCH_KEEP
		add_child(rect)
	
	var children = get_children()
	
	for i in range(children.size()):
		var rect = children[i]
		
		if i < text_value.length():
			rect.visible = true
			var char_ = text_value[i]
			
			if char_ == ":" or char_ == ".":
				if dot_texture:
					rect.texture = dot_texture
				else:
					print("Advertencia: Falta asignar la imagen 'dot_texture'")
			
			elif char_.is_valid_int():
				var digit_index = int(char_)
				if digit_index >= 0 and digit_index < digit_textures.size():
					rect.texture = digit_textures[digit_index]
		else:
			rect.visible = false
