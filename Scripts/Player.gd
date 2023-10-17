extends CharacterBody2D

const gravedad = 2000
const fuerza_salto = -600
const velocidad_movimiento = 400

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if is_on_floor():
		if Input.is_action_just_pressed("ui_jump"):
			velocity.y = fuerza_salto
	else:
		velocity.y += gravedad * delta
	velocity.x = input_vector.x * velocidad_movimiento
	move_and_slide()
