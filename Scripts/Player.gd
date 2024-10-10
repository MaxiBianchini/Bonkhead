extends CharacterBody2D

# Variables para controlar física y movimiento
var gravity: int = 2000
var jump_force: float = -550.0
var movement_velocity: int = 200
var dash_velocity: int = 400
var fall_through_time: float = 0.05  # Tiempo durante el cual se desactiva la colisión

var lives: int = 3 
var is_alive: bool

var first_jump_completed: bool = false
var double_jump_enabled: bool = false
var can_dash: bool = true
var is_dashing: bool = false

@onready var animatedSprite2D = $AnimatedSprite2D
@onready var collisionshape2D = $CollisionShape2D
@onready var raycast_wall = $RayCast2D
@onready var raycast_floor = $RayCast2D2
@onready var area2D = $Area2D

func _ready():
	area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	is_alive = true

func _physics_process(delta):
	# Verificar si el jugador tiene vidas antes de procesar la lógica del movimiento
	if lives != 0:
		# Obtener la entrada del jugador
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
		# Manejar el salto
		if Input.is_action_just_pressed("ui_jump"):
			if Input.is_action_pressed("ui_down") && raycast_floor.is_colliding():
				var collider = raycast_floor.get_collider()
				if collider.is_in_group("Platform"):
					ignore_platform_collision()
			elif is_on_floor():
				first_jump_completed = true
				velocity.y = jump_force
				animatedSprite2D.play("Jump")
			elif double_jump_enabled and first_jump_completed:
				first_jump_completed = false
				velocity.y = jump_force
				animatedSprite2D.play("Double_Jump")
		
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
	
	else:
		# Si no tiene vidas, se detiene el movimiento horizontal
		velocity.x = 0
	
	# Siempre aplica la gravedad
	velocity.y += gravity * delta
	
	# Mover el personaje
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
		raycast_floor.position.x = offset
		animatedSprite2D.position.x = -offset
		collisionshape2D.position.x = offset
		area2D.position.x = offset
	elif velocity.x > 0:
		
		animatedSprite2D.flip_h = false
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = offset
		raycast_floor.position.x = offset
		animatedSprite2D.position.x = offset
		collisionshape2D.position.x = offset
		area2D.position.x = offset

func update_animation():
	if animatedSprite2D.animation != "Hurt" and lives !=0:
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
	await (get_tree().create_timer(fall_through_time).timeout)
	collisionshape2D.disabled = false

func _on_dash_timer_timeout():
	is_dashing = false

func _on_can_dash_timeout():
	can_dash = true

func _on_body_entered(body):
	if body.is_in_group("Enemy"): # Asegúrate de que el enemigo esté en el grupo "Enemy"
		lives -= 1
		check_death()
		
func disable_player_collision():
	area2D.set_collision_mask_value(3,false)
	area2D.set_collision_mask_value(4,false)
	area2D.set_collision_mask_value(5,false)
	
func enable_player_collision():
	area2D.set_collision_mask_value(3,true)
	area2D.set_collision_mask_value(4,true)
	area2D.set_collision_mask_value(5,true)

func check_death():
	if lives == 0:
		is_alive = false
		animatedSprite2D.play("Death")
		call_deferred("disable_player_collision")
	else:
		$AnimationPlayer.play("Hurt")
		call_deferred("disable_player_collision")
		await (get_tree().create_timer(3.0).timeout)
		call_deferred("enable_player_collision")
