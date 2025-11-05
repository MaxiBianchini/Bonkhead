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
	MORTAR,
	PIERCING,
	BURST
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

@onready var dead_timer: Timer = $DeadTimer
@onready var hurt_timer: Timer = $HurtTimer
@onready var dash_duration_timer: Timer = $DashDurationTimer 
@onready var dash_cool_down_timer: Timer = $DashCooldownTimer
@onready var shoot_cooldown_timer: Timer = $ShootCooldownTimer

@export var wall_slide_speed: float = 12.5
@export var wall_jump_force: Vector2 = Vector2(450, -550)

signal player_died
signal change_UI_lives(change_lives)
signal ammo_changed(new_ammo_type)

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
var can_shoot: bool = true

var ammo_scenes: Dictionary = {
	AmmoType.NORMAL: preload("res://Prefabs/Bullet.tscn"),
	AmmoType.MORTAR: preload("res://Prefabs/MortarBullet.tscn"),
	AmmoType.PIERCING: preload("res://Prefabs/PiercingBullet.tscn"),
	AmmoType.BURST: preload("res://Prefabs/Bullet.tscn"),
}
var current_ammo_type: AmmoType = AmmoType.NORMAL

var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2 = Vector2(32, -9)
var gun_type: String ="Small"
var change_gun_type: bool = false
var hurt_jump_force: float = -200
var current_level: int
var wall_grab_power_activated: bool = false
var is_stunned: bool = false
var just_double_jumped: bool = false
var double_jump_enabled: bool = false
var can_dash = true

var is_burst_mode_active: bool = false
var burst_charges_left: int = 0
const BURST_SHOT_COUNT: int = 3       # Balas por ráfaga
const BURST_DELAY_SECONDS: float = 0.1  # Tiempo entre cada bala de la ráfaga
const TOTAL_BURST_CHARGES: int = 6    # Cuántas ráfagas puede disparar


const OFFSET_IDLE_RIGHT: Vector2 = Vector2(40, -9)
const OFFSET_RUN_RIGHT: Vector2 = Vector2(45, -9) 
const OFFSET_JUMP_RIGHT: Vector2 = Vector2(40, -5)
const OFFSET_FALL_RIGHT: Vector2 = Vector2(40, -25)
const OFFSET_UP_RIGHT: Vector2 = Vector2(13.5, -30)
const OFFSET_RUNUP_RIGHT: Vector2 = Vector2(22, -30)

# Creamos las versiones para la izquierda simplemente invirtiendo el valor X
const OFFSET_IDLE_LEFT: Vector2 = Vector2(-20, OFFSET_IDLE_RIGHT.y)
const OFFSET_RUN_LEFT: Vector2 = Vector2(-25, OFFSET_RUN_RIGHT.y)
const OFFSET_JUMP_LEFT: Vector2 = Vector2(-20, OFFSET_JUMP_RIGHT.y)
const OFFSET_FALL_LEFT: Vector2 = Vector2(-20, OFFSET_JUMP_RIGHT.y)
const OFFSET_UP_LEFT: Vector2 = Vector2(6.5, OFFSET_UP_RIGHT.y)
const OFFSET_RUNUP_LEFT: Vector2 = Vector2(0, OFFSET_UP_RIGHT.y)

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

func update_visuals() -> void:
	# --- BLOQUE 1: DETERMINAR LA DIRECCIÓN ---
	if velocity.x < 0:
		player_dir = "LEFT"
	elif velocity.x > 0:
		player_dir = "RIGHT"

	# --- BLOQUE 2: CONFIGURACIÓN VISUAL ---
	
	# Variable ÚNICA para la posición X por defecto.
	# Si es DERECHA, la posición es 10. Si es IZQUIERDA, es -10.
	var final_pos_x: float = 10.0 if player_dir == "RIGHT" else -10.0
	
	var is_flipped: bool = (player_dir == "LEFT")
	var sprite_offset_vector: Vector2 = Vector2(10, -7)

	# --- BLOQUE 3: MANEJAR CASO ESPECIAL: WALL_GRAB ---
	if state == State.WALL_GRAB:
		# En Wall Grab, FORZAMOS la posición final a 0
		final_pos_x = 0
		sprite_offset_vector = Vector2.ZERO
		is_flipped = (player_dir == "RIGHT") # Lógica de flip opuesta para mirar hacia afuera

	# --- BLOQUE 4: APLICAR TODAS LAS PROPIEDADES VISUALES ---
	
	# Usamos la misma variable 'final_pos_x' para TODO.
	# Esto garantiza que siempre estarán sincronizados.
	for s in animated_sprites:
		s.flip_h = is_flipped
		s.position.x = final_pos_x
	
	animated_sprite.offset = sprite_offset_vector
	
	collision_shape.position.x = 10
	raycast_wall.position.x = 10
	raycast_floor.position.x = 10
	area2D.position.x = 10
	
	raycast_wall.target_position.x = final_pos_x

	# --- BLOQUE 5: REPRODUCIR LA ANIMACIÓN ---
	# (El resto de la función para reproducir las animaciones no cambia)
	var anim_name = ""
	var current_sprite_node = animated_sprite
	
	match state:
		State.IDLE:
			anim_name = "SIdle with Gun"
		State.RUN:
			anim_name = "SRun with Gun"
		State.JUMP:
			anim_name = "Double_Jump" if just_double_jumped else "SJump"
			if just_double_jumped: just_double_jumped = false
		State.FALL:
			anim_name = "SFall"
		State.WALL_GRAB:
			anim_name = "GrabWall"
		State.DASH:
			anim_name = "Dash"
		State.DEAD:
			anim_name = "Death"

	if Input.is_action_pressed("Shoot") and (state == State.IDLE or state == State.RUN):
		if Input.is_action_pressed("ui_up"):
			anim_name = "SRun Shooting Up" if state == State.RUN else "SIdle Shooting Up"
			current_sprite_node = animated_sprite3
		else:
			anim_name = "SRun Shooting Rect" if state == State.RUN else "SIdle Shooting Rect"
			current_sprite_node = animated_sprite2
	
	if anim_name != "" and current_sprite_node.animation != anim_name:
		current_sprite_node.play(anim_name)

	if current_sprite_node == animated_sprite: switch_animation(1)
	elif current_sprite_node == animated_sprite2: switch_animation(2)
	elif current_sprite_node == animated_sprite3: switch_animation(3)

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
			elif not is_on_floor():
				state = State.FALL
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
			elif not is_on_floor():
				state = State.FALL
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
			if is_on_floor():
				state = State.IDLE
				return 
			
			var is_still_on_grabbable_wall = on_wall and raycast_wall.get_collider().is_in_group("Grabbable Wall")
			var is_letting_go = input_vector.x != 0 and not is_moving_towards_wall
			if not is_still_on_grabbable_wall or is_letting_go:
				state = State.FALL
				return
			
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
	
	if is_shoot_pressed and can_shoot and not is_stunned and (state == State.IDLE or state == State.RUN or state == State.JUMP or state == State.FALL):

	# Bloqueamos nuevos disparos hasta que el cooldown termine
		can_shoot = false
		
		if current_ammo_type == AmmoType.BURST:
			shoot_cooldown_timer.start() # Inicia el temporizador de 0.5s (o lo que configures)
			# Llamamos a la función de ráfaga (que es asíncrona)
			start_burst_fire() 
		else:
		# Disparo normal (como antes)
			audio_shoot.play()
			shoot_bullet()
			can_shoot = true
	
	move_and_slide()
	
	if is_alive:
		update_sprite_direction()
		handle_double_jump()
	update_animation()

func update_sprite_direction() -> void:
	var offset := 10
	var dir_mult := 1 if player_dir == "RIGHT" else -1
	
	if state == State.WALL_GRAB:
		# Flip en pared
		animated_sprite.flip_h = (player_dir == "RIGHT")
		for s in animated_sprites:
			s.position.x = -offset * dir_mult
		return
	
	# Determinar dirección según velocidad
	if velocity.x < 0:
		player_dir = "LEFT"
	elif velocity.x > 0:
		player_dir = "RIGHT"

	# Actualizar flip
	var flip := (player_dir == "LEFT")
	for s in animated_sprites:
		s.flip_h = flip

	# Direcciones auxiliares
	bullet_dir = Vector2.LEFT if player_dir == "LEFT" else Vector2.RIGHT
	dir_mult = -1 if player_dir == "LEFT" else 1

	for s in animated_sprites:
		s.position.x = offset * dir_mult
	
	raycast_wall.target_position.x = offset * dir_mult
	raycast_wall.position.x = offset
	raycast_floor.position.x = offset
	collision_shape.position.x = offset
	area2D.position.x = offset
	
func update_animation() -> void:
	match state:
		State.IDLE:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					bullet_dir = Vector2.UP
					bullet_offset = OFFSET_UP_RIGHT if player_dir == "RIGHT" else OFFSET_UP_LEFT
					var anim_name = "SIdle Shooting Up" if gun_type == "Small" else "BIdle Shooting Up"
					if animated_sprite3.animation != anim_name:
						animated_sprite3.play(anim_name)
					switch_animation(3)
				else:
					bullet_dir = check_direction()
					bullet_offset = OFFSET_IDLE_RIGHT if player_dir == "RIGHT" else OFFSET_IDLE_LEFT
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
					bullet_offset = OFFSET_RUNUP_RIGHT if player_dir == "RIGHT" else OFFSET_RUNUP_LEFT
					var anim_name = "SRun Shooting Up" if gun_type == "Small" else "BRun Shooting Up"
					if animated_sprite3.animation != anim_name:
						animated_sprite3.play(anim_name)
					switch_animation(3)
				else:
					bullet_dir = check_direction()
					bullet_offset = OFFSET_RUN_RIGHT if player_dir == "RIGHT" else OFFSET_RUN_LEFT
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
				bullet_offset = OFFSET_JUMP_RIGHT if player_dir == "RIGHT" else OFFSET_JUMP_LEFT
				if animated_sprite.animation != "Double_Jump":
					animated_sprite.play("Double_Jump")
				just_double_jumped = false
			else:
				bullet_offset = OFFSET_JUMP_RIGHT if player_dir == "RIGHT" else OFFSET_JUMP_LEFT
				var anim_name = "SJump" if gun_type == "Small" else "BJump"
				if animated_sprite.animation != "Double_Jump" and animated_sprite.animation != anim_name:
					animated_sprite.play(anim_name)
			switch_animation(1)

		State.FALL:
			bullet_offset = OFFSET_JUMP_RIGHT if player_dir == "RIGHT" else OFFSET_JUMP_LEFT
			var anim_name = "SFall" if gun_type == "Small" else "BFall"
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)
			switch_animation(1)

		State.WALL_GRAB:
			if animated_sprite.animation != "GrabWall":
				animated_sprite.play("GrabWall")
			switch_animation(1)

		State.DASH:
			if animated_sprite.animation != "Dash":
				animated_sprite.play("Dash")
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
	update_animation() # (Esto ya lo tenías, actualiza los offsets de bala)
	
	# 1. Determinamos qué tipo de bala instanciar
	var ammo_type_to_spawn = current_ammo_type
	if current_ammo_type == AmmoType.BURST:
		# El modo Ráfaga dispara la bala Normal
		ammo_type_to_spawn = AmmoType.NORMAL 

	# 2. Obtenemos la escena de la bala a instanciar
	var bullet_scene_to_spawn = ammo_scenes[ammo_type_to_spawn]
	var bullet = bullet_scene_to_spawn.instantiate() as Area2D
	
	# 3. El resto de tu función de configuración de la bala...
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
		
	if bullet.has_method("set_mask"):
		bullet.set_mask(3)
	
	if bullet.has_method("set_direction"):
		# (Tu lógica de disparo de mortero hacia arriba sigue funcionando aquí)
		if (current_ammo_type == AmmoType.MORTAR and bullet_dir == Vector2.UP and bullet.has_method("set_aim_state")):
			bullet.set_aim_state(true)
			bullet.set_direction(check_direction())
		else:
			bullet.set_direction(bullet_dir)
			
	bullet.global_position = global_position + bullet_offset
	get_tree().current_scene.add_child(bullet)

func set_ammo_type(new_type: AmmoType) -> void:
	# Evitamos acciones redundantes si ya tenemos ese tipo
	if current_ammo_type == new_type:
		return

	current_ammo_type = new_type

	# Usamos un 'match' para manejar la lógica de cada tipo
	match current_ammo_type:
		AmmoType.NORMAL, AmmoType.MORTAR, AmmoType.PIERCING:
			# Si cambiamos a cualquier bala normal, volvemos al arma "Small"
			if gun_type == "Big":
				change_weapon()
		
		AmmoType.BURST:
			# Activamos el modo ráfaga
			burst_charges_left = TOTAL_BURST_CHARGES
			# Cambiamos al arma "Big"
			if gun_type == "Small":
				change_weapon()
	
	# Emitimos la señal para que el SceneManager actualice la UI
	ammo_changed.emit(current_ammo_type)

func ignore_platform_collision() -> void:
	state = State.FALL
	collision_shape.disabled = true
	velocity.y = jump_force * -1.5
	await (get_tree().create_timer(fall_through_time).timeout)
	collision_shape.disabled = false


func change_weapon() -> void:
	if gun_type == "Small":
		gun_type = "Big"
	else:
		gun_type = "Small"
		set_ammo_type(AmmoType.NORMAL)


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

# --- FUNCIONES DEL MODO RÁFAGA ---

# Esta es la función que debe llamar tu "AmmoPickup" especial
func activate_burst_mode() -> void:
	is_burst_mode_active = true
	burst_charges_left = TOTAL_BURST_CHARGES
	
	# Cambiamos al arma grande si no la tenemos ya
	if gun_type == "Small":
		change_weapon() # Llama a tu función existente

# Esta función es asíncrona (async) para poder usar 'await'
# Se encarga de disparar las 3 balas
func start_burst_fire() -> void:
	burst_charges_left -= 1 # Gastamos una carga de ráfaga
	
	for i in range(BURST_SHOT_COUNT):
		audio_shoot.play()
		shoot_bullet() # Llama a tu función de disparo existente
		
		# Esperamos un breve momento antes de la siguiente bala
		await get_tree().create_timer(BURST_DELAY_SECONDS).timeout
	
	# Comprobamos si se acabaron las cargas
	if burst_charges_left <= 0:
		deactivate_burst_mode()
		can_shoot = true

# Se llama para volver al estado normal
func deactivate_burst_mode() -> void:
	is_burst_mode_active = false
	
	# Volvemos al arma pequeña
	if gun_type == "Big":
		change_weapon()

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

func _on_shoot_cooldown_timer_timeout() -> void:
	can_shoot = true # Permitimos que el jugador vuelva a disparar
