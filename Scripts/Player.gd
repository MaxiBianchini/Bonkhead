extends CharacterBody2D

# Variables para controlar física y movimiento
var gravity: int = 2000
var jump_force: float = -550.0
var movement_velocity: int = 200
var dash_velocity: int = 400
var fall_through_time: float = 0.8  # Tiempo durante el cual se desactiva la colisión

var first_jump_completed: bool = false
var double_jump_enabled: bool = false
var can_dash: bool = true
var is_dashing: bool = false

var animatedSprite2D
var collisionshape2D
var raycast_wall
var raycast_floor

func _ready():
	animatedSprite2D = $AnimatedSprite2D
	collisionshape2D = $CollisionShape2D
	raycast_wall = $RayCast2D
	raycast_floor = $RayCast2D2
	
	# Inicialización de variables
	first_jump_completed = false
	can_dash = true
	is_dashing = false

func _physics_process(delta):
	# Obtener la entrada del jugador
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Manejar el salto
	if Input.is_action_just_pressed("ui_jump"):
		if Input.is_action_pressed("ui_down"):
			print("LLEGA AL DOWN")
			ignore_platform_collision()
			
		elif is_on_floor():
			first_jump_completed = true
			velocity.y = jump_force
			animatedSprite2D.play("Jump")
		elif double_jump_enabled and first_jump_completed:
			first_jump_completed = false
			velocity.y = jump_force
			animatedSprite2D.play("Double_Jump")
	
	if !is_on_floor():
		velocity.y += gravity * delta
	# Manejar el dash
	if Input.is_action_just_pressed("Dash") and can_dash:
		can_dash = false
		is_dashing = true
		animatedSprite2D.stop()
		animatedSprite2D.play("Dash")
		$DashTimer.start()
		$CanDash.start()

	# Actualizar la velocidad según el estado del dash
	velocity.x = input_vector.x * (dash_velocity if is_dashing else movement_velocity)
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
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = -offset
		animatedSprite2D.position.x = -offset
		$CollisionShape2D.position.x = offset
	elif velocity.x > 0:
		animatedSprite2D.flip_h = false
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = offset
		animatedSprite2D.position.x = offset
		$CollisionShape2D.position.x = offset

func update_animation():
	if velocity.y > 350 and not is_on_floor():
		animatedSprite2D.play("Fall")
	elif velocity.x == 0 and velocity.y == 0:
		animatedSprite2D.play("Idle")
	elif (Input.get_action_strength("ui_left") or Input.get_action_strength("ui_right")) and is_on_floor() and not is_dashing:
		animatedSprite2D.play("Walk")

func handle_double_jump():
	if raycast_wall.is_colliding():
		var collider = raycast_wall.get_collider()
		if collider.is_in_group("Wall"):
			double_jump_enabled = true
		if collider.is_in_group("Floor"):
			double_jump_enabled = false
	else:
		double_jump_enabled = false

func ignore_platform_collision():
	collisionshape2D.disabled = true
	velocity.y = jump_force * -1.5
	print ("INGORA")
	await (get_tree().create_timer(fall_through_time))
	#collisionshape2D.disabled = false
	print("NO IGNORA")
func _on_dash_timer_timeout():
	is_dashing = false

func _on_can_dash_timeout():
	can_dash = true
