extends CharacterBody2D

const velocidad_movimiento = 250
const velocidad_maxima = 500

const fuerza_salto = -300

const up = Vector2(0,-1)


const gravedad = 2000

#var velocidad_movimiento: int
#var primer_salto: bool

@onready var animatedSprite2D = $AnimatedSprite2D

var movimiento = Vector2()

#func _ready():
	#gravedad = 2000
	#fuerza_salto = -600
	#velocidad_movimiento = 400
	#primer_salto = false
	
	#animatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	
	movimiento.y += gravedad
	var friccion = false
	
	if Input.is_action_pressed("ui_right"):
		animatedSprite2D.flip_h = true
		#animacion de walk
		movimiento.X = min(movimiento.x + velocidad_movimiento, velocidad_maxima)
	elif Input.is_action_pressed("ui_left"):
		animatedSprite2D.flip_h = false
		#animacion de walk
		movimiento.X = max(movimiento.x - velocidad_movimiento, -velocidad_maxima)
	else:
		#animacion de idle
		friccion = true
		
	
	if is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			movimiento.y = fuerza_salto
		if friccion == true:
			movimiento.x = lerp(movimiento.x, 0.0,0.5)
	else:
		if friccion == true:
			movimiento.x = lerp(movimiento.x, 0.0,0.1)
	
	movimiento = move_and_slide()
	
	
	
	
	
	#var input_vector = Vector2.ZERO
	#input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	#var jmp = $RayCast2D.get_collider()
	
	#if Input.is_action_just_pressed("ui_jump"):
		#if jmp.is_in_grup("Wall"):
	#	velocity.y = fuerza_salto
		#if is_on_floor():
		#	primer_salto = true
		#	velocity.y = fuerza_salto
		#	animatedSprite2D.stop()
		#	animatedSprite2D.play("Jump")
		#else: 
		#	if primer_salto:
		#		primer_salto = false
		#		velocity.y = fuerza_salto
		#		animatedSprite2D.stop()
		#		animatedSprite2D.play("Double_Jump")
				
	#	if velocity.y > 250 && !is_on_floor():
	#		animatedSprite2D.play("Fall")
			
	#else:
	#	velocity.y += gravedad * delta
	#velocity.x = input_vector.x * velocidad_movimiento
	
	#move_and_slide()
	
	if velocity.x < 0:
		animatedSprite2D.flip_h = true
	if velocity.x > 0:
		animatedSprite2D.flip_h = false
	if velocity.y > 350 && !is_on_floor():
		animatedSprite2D.play("Fall")
	
	
	if velocity.x == 0 && velocity.y == 0:
		animatedSprite2D.play("Idle")
	
	if (Input.get_action_strength("ui_right") && velocity.y == 0):
		animatedSprite2D.play("Walk")
		animatedSprite2D.position = Vector2(10,0)
		$CollisionShape2D.position = Vector2(10,0)
	
	if (Input.get_action_strength("ui_left") && velocity.y == 0):
		animatedSprite2D.play("Walk")
		animatedSprite2D.position = Vector2(-10,0)
		$CollisionShape2D.position = Vector2(10,0)
	
	
		


