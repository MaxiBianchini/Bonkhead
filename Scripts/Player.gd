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
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.play("Jump")
		else: 
			if primer_salto:
				primer_salto = false
				velocity.y = fuerza_salto
				$AnimatedSprite2D.stop()
				$AnimatedSprite2D.play("Double_Jump")
	else:
		velocity.y += gravedad * delta
	velocity.x = input_vector.x * velocidad_movimiento
	
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	if velocity.y > 0 && !is_on_floor():
		$AnimatedSprite2D.play("Fall")
	
	move_and_slide()
	
	if velocity.x == 0 && velocity.y == 0:
		$AnimatedSprite2D.play("Idle")
	
	if (Input.get_action_strength("ui_right") && velocity.y == 0):
		$AnimatedSprite2D.play("Walk")
		$AnimatedSprite2D.position = Vector2(10,0)
		$CollisionShape2D.position = Vector2(10,0)
	else:
		if (Input.get_action_strength("ui_left") && velocity.y == 0):
			$AnimatedSprite2D.play("Walk")
			$AnimatedSprite2D.position = Vector2(-10,0)
			$CollisionShape2D.position = Vector2(10,0)


