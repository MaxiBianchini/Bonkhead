extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var animated_sprite2 = $AnimatedSprite2D2
@onready var animated_sprite3 = $AnimatedSprite2D3

var sprites = [animated_sprite, animated_sprite2, animated_sprite3]

@onready var collision_shape = $CollisionShape2D
@onready var raycast_floor = $RayCast2D2
@onready var raycast_wall = $RayCast2D
@onready var area2D = $Area2D

signal player_died

# Variables para controlar física y movimiento
var gravity: int = 2000
var jump_force: float = -550
var jump_cut_multiplier: float = 0.5  # Factor para cortar el salto al soltar el botón
var player_dir: String = "RIGHT"
var dash_velocity: int = 400
var movement_velocity: int = 250
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
var bullet_dir = Vector2.RIGHT
var bullet_offset: Vector2

var gun_type: String ="Small"
var current_state: String = ""
var change_gun_type: bool = false

signal change_UI_lives(change_lives)

func _ready():
	pass

func _physics_process(delta):
	if is_alive:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
		if Input.is_action_just_pressed("Shoot"):
			shoot_bullet()
		
		# Manejo del salto
		if Input.is_action_just_pressed("ui_jump"):
			if Input.is_action_pressed("ui_down") && raycast_floor.is_colliding():
				var collider = raycast_floor.get_collider()
				if collider.is_in_group("Platform"):
					ignore_platform_collision()
			elif is_on_floor():
				first_jump_completed = true
				velocity.y = jump_force
				match gun_type:
					"Small":
						animated_sprite.play("SJump")
					"Big":
						animated_sprite.play("BJump")
				current_state = "Jump"
				switch_animation(1)
			elif double_jump_enabled and first_jump_completed:
				first_jump_completed = false
				velocity.y = jump_force
				animated_sprite.play("Double_Jump")
				current_state = "Double_Jump"
				switch_animation(1)
		
		# Aquí podrías manejar el dash u otras acciones...
		if Input.is_action_just_pressed("Dash") and can_dash:
			can_dash = false
			is_dashing = true
			animated_sprite.stop()
			animated_sprite.play("Dash")
			current_state = "Dash"
			$DashTimer.start()
			$CanDash.start()
		
		velocity.x = input_vector.x * (dash_velocity if is_dashing else movement_velocity)
		
		# **Implementación del salto variable:**
		# Si se suelta el botón de salto y el jugador sigue subiendo, se reduce la velocidad vertical.
		if Input.is_action_just_released("ui_jump") and velocity.y < 0:
			velocity.y *= jump_cut_multiplier
		
	else:
		velocity.x = 0

	# Aplica la gravedad
	velocity.y += gravity * delta
	
	move_and_slide()                 
	if is_alive:update_sprite_direction()        
	update_animation()               
	handle_double_jump()

# Controlador de la direccion del Sprite
func update_sprite_direction():
	var offset = 10
	if velocity.x < 0:
		sprites = [animated_sprite, animated_sprite2, animated_sprite3]
		for s in sprites:
			s.position.x = -offset
			s.flip_h = true
		
		player_dir = "LEFT"
		
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = -offset
		raycast_floor.position.x = offset
		
		collision_shape.position.x = offset
		area2D.position.x = offset
	
	elif velocity.x > 0:
		sprites = [animated_sprite, animated_sprite2, animated_sprite3]
		for s in sprites:
			s.position.x = offset
			s.flip_h = false
		
		player_dir = "RIGHT"
		
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = offset
		raycast_floor.position.x = offset
		
		collision_shape.position.x = offset
		area2D.position.x = offset

func update_animation():
	if not is_alive:
		return  # No seguir actualizando animaciones si el jugador está muerto
	# Solo hacemos la lógica si no está en "Hurt" y aún tienes vidas.
	if animated_sprite.animation != "Hurt" and lives != 0:
		# Movimiento vertical de caída.
		if not is_on_floor() and velocity.y > 250:
			match gun_type:
				"Small":
					animated_sprite.play("SFall")
				"Big":
					animated_sprite.play("BFall")
			current_state = "Fall"
			switch_animation(1)
		
		# Quieto en x e y = 0 => Idle
		elif velocity.x == 0 and velocity.y == 0:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					animator_controller("Idle", 3)
					bullet_dir = Vector2.UP
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(12, -25)  # Ajusta la distancia en Y según tu sprite
						"LEFT":
							bullet_offset = Vector2(10, -25)  # Ajusta la distancia en Y según tu sprite
				else:
					animator_controller("Idle", 2)
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(35, -9)
							bullet_dir = Vector2.RIGHT
						"LEFT":
							bullet_offset = Vector2(-15, -9)
							bullet_dir = Vector2.LEFT
			else:
				animator_controller("Idle", 1)
				
		
		# Movimiento horizontal en el suelo (sin dash) => Walk
		elif is_on_floor() and not is_dashing and (
			Input.get_action_strength("ui_left") or Input.get_action_strength("ui_right")
			):
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					animator_controller("Run", 3)
					bullet_dir = Vector2.UP
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(25, -25)  # Ajusta la distancia en Y según tu sprite
						"LEFT":
							bullet_offset = Vector2(-5, -25)  # Ajusta la distancia en Y según tu sprite
				else:
					animator_controller("Run", 2)
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(60, -9)
							bullet_dir = Vector2.RIGHT
						"LEFT":
							bullet_offset = Vector2(-40, -9)
							bullet_dir = Vector2.LEFT
			else:
				animator_controller("Run", 1)

func animator_controller(state_trigger: String, animation_number: int):
	# Si el estado actual cambia, se reproducen las animaciones base de ese estado.
	if current_state != state_trigger or gun_type:
		change_gun_type = false
		match state_trigger:
			"Idle":
				match gun_type:
					"Small":
						animated_sprite.play("SIdle with Gun")
						animated_sprite2.play("SIdle Shooting Rect")
						animated_sprite3.play("SIdle Shooting Up")
					"Big":
						animated_sprite.play("BIdle with Gun")
						animated_sprite2.play("BIdle Shooting Rect")
						animated_sprite3.play("BIdle Shooting Up")
			
			"Run":
				match gun_type:
					"Small":
						animated_sprite.play("SRun with Gun")
						animated_sprite2.play("SRun Shooting Rect")
						animated_sprite3.play("SRun Shooting Up")
					"Big":
						animated_sprite.play("BRun with Gun")
						animated_sprite2.play("BRun Shooting Rect")
						animated_sprite3.play("BRun Shooting Up")
		
		current_state = state_trigger
	
	# Aquí decidimos cuál de las 3 variaciones (1,2,3) se muestra.
	switch_animation(animation_number)

func switch_animation(animation_number: int):
	# Ocultamos siempre todos los sprites antes de mostrar el que corresponda
	hide_all_sprites()
	match animation_number:
		1:
			animated_sprite.visible = true
		2:
			animated_sprite2.visible = true
		3:
			animated_sprite3.visible = true

func hide_all_sprites():
	animated_sprite.visible = false
	animated_sprite2.visible = false
	animated_sprite3.visible = false

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
	
	update_animation()
	
	var bullet = bullet_scene.instantiate() as Area2D # Instancia la bala
	bullet.mask = 3
	# Le indicamos quién la disparó:
	bullet.shooter = self
	
	 # Posición final de la bala y dirección
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir
	
	get_tree().current_scene.add_child(bullet) # Añade la bala a la escena actual

# Controlador de Colision con Plataforma
func ignore_platform_collision():
	collision_shape.disabled = true
	velocity.y = jump_force * -1.5
	await (get_tree().create_timer(fall_through_time).timeout)
	collision_shape.disabled = false

func change_weapon():
	if gun_type == "Small":
		gun_type = "Big"
	else:
		gun_type = "Small"
	change_gun_type = true

# Controlador del Daño
func take_damage():
	if is_alive:
		lives -= 1
		emit_signal("change_UI_lives", lives)  # Enviar la señal a la UI
		if lives <= 0:
			is_alive = false
			animated_sprite.play("Death")
			animated_sprite2.play("Death")
			animated_sprite3.play("Death")
			
			current_state = "Death"
			call_deferred("disable_player_collision")
			await (get_tree().create_timer(1.5).timeout)
			player_died.emit()
		else:
			$AnimationPlayer.play("Hurt")
			call_deferred("disable_player_collision")
			await (get_tree().create_timer(3.0).timeout)
			#call_deferred("enable_player_collision")

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

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Dead"):
		lives = 0
		emit_signal("change_UI_lives", lives)  # Enviar la señal a la UI
		await (get_tree().create_timer(1.0).timeout)
		player_died.emit()
