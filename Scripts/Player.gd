extends CharacterBody2D

@onready var animatedSprite2D = $AnimatedSprite2D

var gravedad: int
var fuerza_salto: float
var velocidad_movimiento: int
var primer_salto: bool

var puede_dashear: bool
var esta_dasheando: bool
var velocidad_dash: int

func _ready():
	gravedad = 2000
	fuerza_salto = -600
	velocidad_movimiento = 400
	primer_salto = false
	
	puede_dashear = true
	esta_dasheando = false
	velocidad_dash = 700

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if Input.is_action_just_pressed("ui_jump"):
		if is_on_floor():
			primer_salto = true
			velocity.y = fuerza_salto
			animatedSprite2D.play("Jump")
		else: 
			if primer_salto:
				primer_salto = false
				velocity.y = fuerza_salto
				animatedSprite2D.play("Double_Jump")
	else:
		velocity.y += gravedad * delta
	
	if Input.is_action_just_pressed("Dash") and puede_dashear:
		puede_dashear = false
		esta_dasheando = true
		animatedSprite2D.stop()
		animatedSprite2D.play("Dash")
		$DashTimer.start()
		$PuedeDashear.start()
	
	if esta_dasheando:
		velocity.x = input_vector.x * velocidad_dash
	else:
		velocity.x = input_vector.x * velocidad_movimiento
	move_and_slide()
	
	if velocity.x < 0:
		animatedSprite2D.flip_h = true
		animatedSprite2D.position = Vector2(-10,0)
		$CollisionShape2D.position = Vector2(10,0)
	if velocity.x > 0:
		animatedSprite2D.flip_h = false
		animatedSprite2D.position = Vector2(10,0)
		$CollisionShape2D.position = Vector2(10,0)
		
	if velocity.y > 350 && !is_on_floor():
		animatedSprite2D.play("Fall")
	
	if velocity.x == 0 && velocity.y == 0:
		animatedSprite2D.play("Idle")
	
	if ((Input.get_action_strength("ui_left") || Input.get_action_strength("ui_right")) && is_on_floor()):
		animatedSprite2D.play("Walk")
	

func _on_dash_timer_timeout():
	esta_dasheando = false

func _on_puede_dashear_timeout():
	puede_dashear = true
