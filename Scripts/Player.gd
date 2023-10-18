extends CharacterBody2D

var gravedad: int
var fuerza_salto: float
var velocidad_movimiento: int
var primer_salto: bool

func _ready():
	gravedad = 2000
	fuerza_salto = -600
	velocidad_movimiento = 400
	primer_salto = false

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if Input.is_action_just_pressed("ui_jump"):
		if is_on_floor():
			primer_salto = true
			velocity.y = fuerza_salto
		else: 
			if primer_salto:
				primer_salto = false
				velocity.y = fuerza_salto
				
	else:
		velocity.y += gravedad * delta
	velocity.x = input_vector.x * velocidad_movimiento
	move_and_slide()
	
	if velocity.x == 0 && velocity.y == 0:
		$AnimationPlayer.play("Idle")
	else: 
		$AnimationPlayer.stop()
		$Sprite2D.frame = 0
	
	
