extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var raycast_floor = $RayCast2D2
@onready var raycast_wall = $RayCast2D
@onready var area2D = $Area2D

# Variables para controlar física y movimiento
var gravity: int = 2000
var dash_velocity: int = 400
var jump_force: float = -550
var movement_velocity: int = 200
var fall_through_time: float = 0.05  # Tiempo durante el cual se desactiva la colisión

var can_dash: bool = true
var is_dashing: bool = false
var double_jump_enabled: bool = false
var first_jump_completed: bool = false

# Variables para controlar la vida
var is_alive: bool = true
var lives: int = 3 

# Carga la escena de la bala
var bullet_scene = preload("res://Prefabs/Bullet_1.tscn")

func _ready():
	area2D.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	# Verificar si el jugador tiene vidas antes de procesar la lógica del movimiento
	if is_alive:
		# Obtener la entrada del jugador
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
		# Manejar la creacion de balas
		if Input.is_action_just_pressed("Shoot"):
			shoot_bullet()
		
		# Manejar el salto
		if Input.is_action_just_pressed("ui_jump"):
			if Input.is_action_pressed("ui_down") && raycast_floor.is_colliding():
				var collider = raycast_floor.get_collider()
				if collider.is_in_group("Platform"):
					ignore_platform_collision()
			elif is_on_floor():
				first_jump_completed = true
				velocity.y = jump_force
				animated_sprite.play("Jump")
			elif double_jump_enabled and first_jump_completed:
				first_jump_completed = false
				velocity.y = jump_force
				animated_sprite.play("Double_Jump")
		
		# Manejar el dash
		if Input.is_action_just_pressed("Dash") and can_dash:
			can_dash = false
			is_dashing = true
			animated_sprite.stop()
			animated_sprite.play("Dash")
			$DashTimer.start()
			$CanDash.start()
		
		# Actualizar la velocidad según el estado del dash
		velocity.x = input_vector.x * (dash_velocity if is_dashing else movement_velocity)
	
	else:
		# Si no tiene vidas, se detiene el movimiento horizontal
		velocity.x = 0
	
	# Siempre aplica la gravedad
	velocity.y += gravity * delta
	
	move_and_slide()                 # Mover el personaje
	update_sprite_direction()        # Actualizar la dirección del sprite
	update_animation()               # Cambiar animaciones según la velocidad
	handle_double_jump()             # Manejar el estado del doble salto


# Controlador de la direccion del Sprite
func update_sprite_direction():
	var offset = 10
	if velocity.x < 0:
		animated_sprite.flip_h = true
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = -offset
		raycast_floor.position.x = offset
		animated_sprite.position.x = -offset
		collision_shape.position.x = offset
		area2D.position.x = offset
	
	elif velocity.x > 0:
		animated_sprite.flip_h = false
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = offset
		raycast_floor.position.x = offset
		animated_sprite.position.x = offset
		collision_shape.position.x = offset
		area2D.position.x = offset


# Controlador de animaciones
func update_animation():
	if animated_sprite.animation != "Hurt" and lives !=0:
		if velocity.y > 350 and not is_on_floor():
			animated_sprite.play("Fall")
		elif velocity.x == 0 and velocity.y == 0:
			animated_sprite.play("Idle")
		elif (Input.get_action_strength("ui_left") or Input.get_action_strength("ui_right")) and is_on_floor() and not is_dashing:
			animated_sprite.play("Walk")


# Controlador del Doble Salto
func handle_double_jump():
	if raycast_wall.is_colliding():
		var collider = raycast_wall.get_collider()
		if collider.is_in_group("Wall"):
			double_jump_enabled = true
		if collider.is_in_group("Floor"):
			double_jump_enabled = false
	else:
		double_jump_enabled = false


# Controlador del Disparo
func shoot_bullet():
	var bullet = bullet_scene.instantiate() # Instancia la bala
	
	# Configura la posición de la bala (ajustar el offset para que salga separada)
	var offset = Vector2(30, 0)  # Ajusta la distancia
	bullet.position = position +  offset
	 # Configura la dirección en la que se moverá la bala
	bullet.direction = Vector2.RIGHT
	# Posiciona la bala en la posición del player + una distancia
	#bullet.position = position + offset
	get_tree().current_scene.add_child(bullet) # Añade la bala a la escena actual


# Controlador de Colision con Plataforma
func ignore_platform_collision():
	collision_shape.disabled = true
	velocity.y = jump_force * -1.5
	await (get_tree().create_timer(fall_through_time).timeout)
	collision_shape.disabled = false


# Controlador del Daño
func take_damage():
	lives -= 1
	if lives <= 0:
		is_alive = false
		animated_sprite.play("Death")
		call_deferred("disable_player_collision")
	else:
		$AnimationPlayer.play("Hurt")
		call_deferred("disable_player_collision")
		await (get_tree().create_timer(3.0).timeout)
		call_deferred("enable_player_collision")


func _on_body_entered(body):
	if body.is_in_group("Enemy") and is_alive:
		take_damage()


func disable_player_collision():
	area2D.set_collision_mask_value(3,false)
	area2D.set_collision_mask_value(4,false)
	area2D.set_collision_mask_value(5,false)


func enable_player_collision():
	area2D.set_collision_mask_value(3,true)
	area2D.set_collision_mask_value(4,true)
	area2D.set_collision_mask_value(5,true)


func _on_dash_timer_timeout():
	is_dashing = false


func _on_can_dash_timeout():
	can_dash = true
