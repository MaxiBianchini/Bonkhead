class_name Player
extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH,
	WALL_GRAB,
	DEAD
}

enum AmmoType {
	NORMAL,
	MORTAR
	# Aquí añadiremos más tipos en el futuro (ej. RICOCHET)
}

var state: State = State.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite2:AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite3:AnimatedSprite2D = $AnimatedSprite2D3
var animated_sprites: Array[AnimatedSprite2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast_floor: RayCast2D = $Raycast_floor
@onready var raycast_wall: RayCast2D = $Raycast_wall
@onready var area2D: Area2D = $Area2D

@onready var audio_dash: AudioStreamPlayer2D = $AudioStream_Dash
@onready var audio_jump: AudioStreamPlayer2D = $AudioStream_Jump
@onready var audio_hurts: AudioStreamPlayer2D = $AudioStream_Hurts
@onready var audio_shoot: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var audio_landing: AudioStreamPlayer2D = $AudioStream_Landing

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hurt_timer: Timer = $HurtTimer
@onready var dash_duration_timer: Timer = $DashDurationTimer 
@onready var dash_cool_down_timer: Timer = $DashCooldownTimer
@onready var dead_timer: Timer = $DeadTimer

@export var wall_slide_speed: float = 12.5
@export var wall_jump_force: Vector2 = Vector2(450, -550)

signal player_died
signal change_UI_lives(change_lives)

var gravity: int = 2000
var jump_force: float = -550
var jump_cut_multiplier: float = 0.5
var player_dir: String = "RIGHT"
var dash_velocity: int = 400
var movement_velocity: int = 250
var fall_through_time: float = 0.05

var was_in_air: bool = false
var dash_power_activated: bool = false
var double_jump_power_activated: bool = false
var first_jump_completed: bool = false
var is_alive: bool = true

var lives: int = 5

var ammo_scenes: Dictionary = {
	AmmoType.NORMAL: preload("res://Prefabs/Bullet.tscn"),
	AmmoType.MORTAR: preload("res://Prefabs/MortarBullet.tscn")
}
var current_ammo_type: AmmoType = AmmoType.NORMAL

var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2
var gun_type: String ="Small"
var change_gun_type: bool = false
var hurt_jump_force: float = -200
var current_level: int
var wall_grab_power_activated: bool = false
var is_stunned: bool = false
var just_double_jumped: bool = false
var double_jump_enabled: bool = false
var can_dash = true

func _ready() -> void:
	current_level = SceneManager.current_level
	# Según el GDD, los poderes se desbloquean AL INICIAR el nivel siguiente.
	# Nivel 2: Se obtiene el Doble Salto
	if current_level >= 1:#2
		double_jump_power_activated = true
	
	# Nivel 3: Se obtiene el Dash
	if current_level >=1:#3
		dash_power_activated = true
	
	# Nivel 4: Se obtiene el Agarre en Pared
	if current_level >= 1:#4
		wall_grab_power_activated = true
		
	animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3]

func _physics_process(delta) -> void:
	if not is_alive:
		state = State.DEAD
	
	if is_on_floor():
		if was_in_air:
			audio_landing.play()
			was_in_air = false
	else:
		was_in_air = true

	# --- CAPTURA DE ENTRADAS (INPUTS) ---
	var input_vector = Vector2.ZERO
	var is_jump_pressed = false
	var is_dash_pressed = false
	var is_shoot_pressed = false

	# Solo leemos los controles si el jugador NO está aturdido
	if not is_stunned:
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		is_jump_pressed = Input.is_action_just_pressed("ui_jump")
		is_dash_pressed = Input.is_action_just_pressed("Dash")
		is_shoot_pressed = Input.is_action_just_pressed("Shoot")

	var on_wall = raycast_wall.is_colliding()
	var is_moving_towards_wall = (player_dir == "RIGHT" and input_vector.x > 0) or (player_dir == "LEFT" and input_vector.x < 0)
	
	match state:
		State.IDLE:
			velocity.y += gravity * delta
			velocity.x = 0
			if Input.is_action_pressed("ui_down") and is_jump_pressed and raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Platform"):
				ignore_platform_collision()
			elif is_jump_pressed:
				audio_jump.play() 
				state = State.JUMP
				velocity.y = jump_force
			elif input_vector.x != 0:
				state = State.RUN
			elif is_dash_pressed and dash_power_activated and can_dash:
				state = State.DASH
				audio_dash.play()
				velocity.y = 0
				dash_duration_timer.start()

		State.RUN:
			velocity.y += gravity * delta
			velocity.x = input_vector.x * movement_velocity
			
			if Input.is_action_pressed("ui_down") and is_jump_pressed and raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Platform"):
				ignore_platform_collision()
			elif is_jump_pressed:
				audio_jump.play()
				state = State.JUMP
				velocity.y = jump_force
			elif input_vector.x == 0:
				state = State.IDLE
			elif is_dash_pressed and dash_power_activated and can_dash:
				state = State.DASH
				audio_dash.play()
				velocity.y = 0
				dash_duration_timer.start()

		State.JUMP, State.FALL:
			velocity.y += gravity * delta
			velocity.x = input_vector.x * movement_velocity
			
			if is_dash_pressed and dash_power_activated and can_dash:
				state = State.DASH
				audio_dash.play()
				velocity.y = 0 # Mantiene el dash perfectamente horizontal en el aire
				dash_duration_timer.start()
			
			if is_jump_pressed and double_jump_enabled and first_jump_completed:
				first_jump_completed = false
				double_jump_enabled = false 
				velocity.y = jump_force
				just_double_jumped = true
				state = State.JUMP
			
			if state == State.JUMP and velocity.y > 0:
				state = State.FALL
				
			if is_on_floor():
				if was_in_air: 
					audio_landing.play()
					was_in_air = false
				state = State.IDLE if input_vector.x == 0 else State.RUN
			else:
				was_in_air = true 
			var collider = raycast_wall.get_collider()
			if wall_grab_power_activated  and on_wall and collider.is_in_group("Grabbable Wall") and is_moving_towards_wall:
				state = State.WALL_GRAB
		
		State.WALL_GRAB:
			velocity.y = min(velocity.y + (gravity * 0.5 * delta), wall_slide_speed)
			velocity.x = 0
			
			if is_jump_pressed:
				var jump_direction = -1.0 if player_dir == "RIGHT" else 1.0
				velocity.x = wall_jump_force.x * jump_direction
				velocity.y = wall_jump_force.y
				state = State.JUMP
			
			if not on_wall or (input_vector.x != 0 and not is_moving_towards_wall):
				state = State.FALL
		
		State.DASH:
			velocity.y = 0
			velocity.x = dash_velocity * (1.0 if player_dir == "RIGHT" else -1.0)
			
		State.DEAD:
			velocity.x = 0
			velocity.y += gravity * delta

	if state == State.JUMP and Input.is_action_just_released("ui_jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
	
	if is_shoot_pressed and (state == State.IDLE or state == State.RUN or state == State.JUMP or state == State.FALL):
		audio_shoot.play()
		shoot_bullet()

	move_and_slide()
	
	if is_alive:
		update_sprite_direction()
		handle_double_jump()
	update_animation()


func update_sprite_direction() -> void:
	var offset = 10
	if velocity.x < 0:
		for s in animated_sprites:
			s.position.x = -offset
			s.flip_h = true
		
		player_dir = "LEFT"
		bullet_offset = Vector2(-15, -9)
		bullet_dir = Vector2.LEFT
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = -offset
		raycast_floor.position.x = offset
		collision_shape.position.x = offset
		area2D.position.x = offset
	
	elif velocity.x > 0:
		for s in animated_sprites:
			s.position.x = offset
			s.flip_h = false
		
		player_dir = "RIGHT"
		bullet_offset = Vector2(35, -9)
		bullet_dir = Vector2.RIGHT
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = offset
		raycast_floor.position.x = offset
		collision_shape.position.x = offset
		area2D.position.x = offset


func update_animation() -> void:
	# (Hemos quitado la comprobación de animation_player.is_playing() como acordamos)
	match state:
		State.IDLE:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					bullet_dir = Vector2.UP
					var anim_name = "SIdle Shooting Up" if gun_type == "Small" else "BIdle Shooting Up"
					if animated_sprite3.animation != anim_name:
						animated_sprite3.play(anim_name)
					switch_animation(3)
				else:
					bullet_dir = check_direction()
					var anim_name = "SIdle Shooting Rect" if gun_type == "Small" else "BIdle Shooting Rect"
					if animated_sprite2.animation != anim_name:
						animated_sprite2.play(anim_name)
					switch_animation(2)
			else:

				var anim_name = "SIdle with Gun" if gun_type == "Small" else "BIdle with Gun"
				if animated_sprite.animation != anim_name:
					animated_sprite.play(anim_name)
				switch_animation(1)

		State.RUN:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					bullet_dir = Vector2.UP
					var anim_name = "SRun Shooting Up" if gun_type == "Small" else "BRun Shooting Up"
					if animated_sprite3.animation != anim_name:
						animated_sprite3.play(anim_name)
					switch_animation(3)
				else:
					bullet_dir = check_direction()
					var anim_name = "SRun Shooting Rect" if gun_type == "Small" else "BRun Shooting Rect"
					if animated_sprite2.animation != anim_name:
						animated_sprite2.play(anim_name)
					switch_animation(2)
			else:
				var anim_name = "SRun with Gun" if gun_type == "Small" else "BRun with Gun"
				if animated_sprite.animation != anim_name:
					animated_sprite.play(anim_name)
				switch_animation(1)

		State.JUMP:
			if just_double_jumped:
				if animated_sprite.animation != "Double_Jump":
					animated_sprite.play("Double_Jump")
				just_double_jumped = false
			else:
				var anim_name = "SJump" if gun_type == "Small" else "BJump"
				if animated_sprite.animation != "Double_Jump" and animated_sprite.animation != anim_name:
					animated_sprite.play(anim_name)
			switch_animation(1)

		State.FALL:
			var anim_name = "SFall" if gun_type == "Small" else "BFall"
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)
			switch_animation(1)

		State.WALL_GRAB:
			#if animated_sprite.animation != "WallGrab":
			#	animated_sprite.play("WallGrab")
			switch_animation(1)

		State.DASH:
			if animated_sprite.animation != "Dash":
				animated_sprite.play("Dash") # Aquí había un error, debería ser "Dash"
			switch_animation(1)

		State.DEAD:
			if animated_sprite.animation != "Death":
				animated_sprite.play("Death")
				animated_sprite2.play("Death")
				animated_sprite3.play("Death")
				switch_animation(1)


func switch_animation(animation_number: int) -> void:
	hide_all_sprites()
	match animation_number:
		1:
			animated_sprite.visible = true
		2:
			animated_sprite2.visible = true
		3:
			animated_sprite3.visible = true


func hide_all_sprites() -> void:
	animated_sprite.visible = false
	animated_sprite2.visible = false
	animated_sprite3.visible = false


func handle_double_jump() -> void:
	# Si el poder no está activado, salimos de la función.
	if not double_jump_power_activated:
		return
	
	# Si estamos en el suelo, siempre reseteamos el estado.
	if is_on_floor():
		double_jump_enabled = false
		first_jump_completed = false
		return

	# Si estamos en el aire y tocamos una pared "saltable", CONCEDEMOS el permiso.
	# No lo quitamos aquí, solo lo damos.
	if not double_jump_enabled and raycast_wall.is_colliding():
		var collider = raycast_wall.get_collider()
		if collider and collider.is_in_group("Jumpeable Wall"):
			double_jump_enabled = true
			first_jump_completed = true


func shoot_bullet() -> void:
	update_animation()
	
	var bullet_scene_to_spawn = ammo_scenes[current_ammo_type]
	var bullet = bullet_scene_to_spawn.instantiate() as Area2D
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(3) 
	
	if bullet.has_method("set_direction"):
		if (current_ammo_type == AmmoType.MORTAR and bullet_dir == Vector2.UP and bullet.has_method("set_aim_state")):
			bullet.set_aim_state(true)
			bullet.set_direction(check_direction())
		else:
			bullet.set_direction(bullet_dir)
	bullet.global_position = global_position + bullet_offset   
	get_tree().current_scene.add_child(bullet)

func set_ammo_type(new_type: AmmoType) -> void:
	current_ammo_type = new_type

func ignore_platform_collision() -> void:
	collision_shape.disabled = true
	velocity.y = jump_force * -1.5
	await (get_tree().create_timer(fall_through_time).timeout)
	collision_shape.disabled = false


func change_weapon() -> void:
	if gun_type == "Small":
		gun_type = "Big"
	else:
		gun_type = "Small"
	change_gun_type = true


func take_damage() -> void:
	# Evita recibir daño si ya estás aturdido o muerto
	if is_stunned or not is_alive:
		return

	audio_hurts.play()
	lives -= 1
	emit_signal("change_UI_lives", lives)
	
	if lives <= 0:
		is_alive = false
		state = State.DEAD
		call_deferred("disable_player_collision")
		dead_timer.start()
	else:
		# Activamos el aturdimiento y el temporizador
		is_stunned = true
		hurt_timer.start(0.5) # Duración del aturdimiento

		# Aplicamos el retroceso y la animación de flash
		velocity.y = hurt_jump_force
		animation_player.play("Hurt")

func increase_life() -> bool:
	if lives < 5:
		lives += 1
		emit_signal("change_UI_lives", lives)
		return true
	else:
		return false


func disable_player_collision() -> void:
	area2D.set_collision_mask_value(3,false)
	area2D.set_collision_mask_value(4,false)
	area2D.set_collision_mask_value(5,false)


func _on_body_entered(body) -> void:
	if body.is_in_group("Enemy") and body.is_alive:
		take_damage()

func check_direction()-> Vector2:
	if (player_dir == "LEFT"):
		return Vector2.LEFT
	else:
		return Vector2.RIGHT


func _on_dash_duration_timer_timeout() -> void:
	dash_cool_down_timer.start()
	can_dash = false
	
	if is_on_floor():
		state = State.IDLE
	else:
		state = State.FALL

func _on_dash_cool_down_timeout() -> void:
	can_dash = true

func _on_dead_timer_timeout() -> void:
	player_died.emit()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Dead"):
		lives = 0
		take_damage()

func _on_hurt_timer_timeout() -> void:
	is_stunned = false
