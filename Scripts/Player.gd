extends CharacterBody2D

# Variables para controlar física y movimiento
var gravedad: int = 2000
var fuerza_salto: float = -550.0
var velocidad_movimiento: int = 200
var velocidad_dash: int = 400

var primer_salto_realizado: bool = false
var doble_salto_habilitado: bool = false
var puede_dashear: bool = true
var esta_dasheando: bool = false

@export var animatedSprite2D: AnimatedSprite2D
@export var rayCast2D: RayCast2D

func _ready():
	# Inicialización de variables
	primer_salto_realizado = false
	puede_dashear = true
	esta_dasheando = false

func _physics_process(delta):
	# Obtener la entrada del jugador
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Manejar el salto
	if Input.is_action_just_pressed("ui_jump"):
		if is_on_floor():
			primer_salto_realizado = true
			velocity.y = fuerza_salto
			animatedSprite2D.play("Jump")
		elif doble_salto_habilitado and primer_salto_realizado:
			primer_salto_realizado = false
			velocity.y = fuerza_salto
			animatedSprite2D.play("Double_Jump")
	else:
		# Aplicar gravedad
		velocity.y += gravedad * delta

	# Manejar el dash
	if Input.is_action_just_pressed("Dash") and puede_dashear:
		puede_dashear = false
		esta_dasheando = true
		animatedSprite2D.stop()
		animatedSprite2D.play("Dash")
		$DashTimer.start()
		$PuedeDashear.start()

	# Actualizar la velocidad según el estado del dash
	velocity.x = input_vector.x * (velocidad_dash if esta_dasheando else velocidad_movimiento)
	move_and_slide()

	# Actualizar la dirección del sprite y otros elementos según la velocidad
	update_sprite_direction()

	# Cambiar animaciones según la velocidad
	update_animation()

	# Manejar el estado del doble salto
	handle_double_jump()

func update_sprite_direction():
	var offset = 10
	if velocity.x < 0:
		animatedSprite2D.flip_h = true
		rayCast2D.position.x = offset
		rayCast2D.target_position.x = -offset
		animatedSprite2D.position.x = -offset
		$CollisionShape2D.position.x = offset
	elif velocity.x > 0:
		animatedSprite2D.flip_h = false
		rayCast2D.position.x = offset
		rayCast2D.target_position.x = offset
		animatedSprite2D.position.x = offset
		$CollisionShape2D.position.x = offset

func update_animation():
	if velocity.y > 350 and not is_on_floor():
		animatedSprite2D.play("Fall")
	elif velocity.x == 0 and velocity.y == 0:
		animatedSprite2D.play("Idle")
	elif (Input.get_action_strength("ui_left") or Input.get_action_strength("ui_right")) and is_on_floor() and not esta_dasheando:
		animatedSprite2D.play("Walk")

func handle_double_jump():
	if rayCast2D.is_colliding():
		var collider = rayCast2D.get_collider()
		if collider.is_in_group("Wall"):
			doble_salto_habilitado = true
		if collider.is_in_group("Floor"):
			doble_salto_habilitado = false
	else:
		doble_salto_habilitado = false

func _on_dash_timer_timeout():
	esta_dasheando = false

func _on_puede_dashear_timeout():
	puede_dashear = true
