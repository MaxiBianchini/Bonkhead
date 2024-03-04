extends CharacterBody2D

var gravedad: int
var fuerza_salto: float
var velocidad_movimiento: int

var primer_salto_realizado: bool
var doble_salto_habilitado:bool

var puede_dashear: bool
var esta_dasheando: bool
var velocidad_dash: int

@export var animatedSprite2D:AnimatedSprite2D
@export var rayCast2D:RayCast2D

func _ready():
	gravedad = 2000
	fuerza_salto = -550
	velocidad_movimiento = 200
	primer_salto_realizado = false
	
	puede_dashear = true
	esta_dasheando = false
	velocidad_dash = 400

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if Input.is_action_just_pressed("ui_jump"):
		if is_on_floor():
			primer_salto_realizado = true
			velocity.y = fuerza_salto
			animatedSprite2D.play("Jump")
		elif doble_salto_habilitado && primer_salto_realizado:
				primer_salto_realizado = false
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
		rayCast2D.position.x = 10
		rayCast2D.target_position.x = -10
		animatedSprite2D.position = Vector2(-10,0)
		$CollisionShape2D.position = Vector2(10,0)
	elif velocity.x > 0:
		animatedSprite2D.flip_h = false
		rayCast2D.position.x = 10
		rayCast2D.target_position.x = 10
		animatedSprite2D.position = Vector2(10,0)
		$CollisionShape2D.position = Vector2(10,0)
		
	if velocity.y > 350 && !is_on_floor():
		animatedSprite2D.play("Fall")
	
	if velocity.x == 0 && velocity.y == 0:
		animatedSprite2D.play("Idle")
	
	if ((Input.get_action_strength("ui_left") || Input.get_action_strength("ui_right")) && is_on_floor()) && !esta_dasheando:
		animatedSprite2D.play("Walk")
	
	if rayCast2D.is_colliding():
		var col =  rayCast2D.get_collider()
		if col.is_in_group("Wall"):
			doble_salto_habilitado = true
		if col.is_in_group("Floor"):
			doble_salto_habilitado = false
	else:
		doble_salto_habilitado = false

func _on_dash_timer_timeout():
	esta_dasheando = false

func _on_puede_dashear_timeout():
	puede_dashear = true
