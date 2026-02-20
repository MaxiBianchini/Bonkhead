class_name Player
extends CharacterBody2D

enum State {
	IDLE, RUN, JUMP, FALL, DASH, WALL_GRAB, DEAD
}

var state: State = State.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite3: AnimatedSprite2D = $AnimatedSprite2D3
var animated_sprites: Array[AnimatedSprite2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast_edge_left: RayCast2D = $RayCast_Edge_Left
@onready var raycast_edge_right: RayCast2D = $RayCast_Edge_Right
@onready var raycast_floor: RayCast2D = $Raycast_floor
@onready var raycast_wall: RayCast2D = $Raycast_wall
@onready var area2D: Area2D = $Area2D

@onready var audio_dash: AudioStreamPlayer2D = $AudioStream_Dash
@onready var audio_jump: AudioStreamPlayer2D = $AudioStream_Jump
@onready var audio_hurts: AudioStreamPlayer2D = $AudioStream_Hurts
@onready var audio_shoot: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var audio_landing: AudioStreamPlayer2D = $AudioStream_Landing
@onready var audio_packUp: AudioStreamPlayer2D = $AudioStream_PackUp

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var dead_timer: Timer = $DeadTimer
@onready var hurt_timer: Timer = $HurtTimer
@onready var dash_duration_timer: Timer = $DashDurationTimer 
@onready var dash_cool_down_timer: Timer = $DashCooldownTimer
@onready var shoot_cooldown_timer: Timer = $ShootCooldownTimer

@export var wall_slide_speed: float = 12.5
@export var wall_jump_force: Vector2 = Vector2(450, -550)
@export var slip_speed: float = 100.0

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
var is_invincible: bool = false
var is_cutscene: bool = false

var lives: int = 5
var can_shoot: bool = true

# --- SISTEMA DE ARMAS LIMPIO ---
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
@export var bullet_sprite: Texture2D

var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2 = Vector2(32, -9)
var hurt_jump_force: float = -200
var current_level: int
var wall_grab_power_activated: bool = false
var is_stunned: bool = false
var just_double_jumped: bool = false
var double_jump_enabled: bool = false
var can_dash = true

const OFFSET_IDLE_RIGHT: Vector2 = Vector2(40, -9)
const OFFSET_RUN_RIGHT: Vector2 = Vector2(45, -9) 
const OFFSET_JUMP_RIGHT: Vector2 = Vector2(40, -5)
const OFFSET_FALL_RIGHT: Vector2 = Vector2(40, -25)
const OFFSET_UP_RIGHT: Vector2 = Vector2(13.5, -30)
const OFFSET_RUNUP_RIGHT: Vector2 = Vector2(22, -30)

const OFFSET_IDLE_LEFT: Vector2 = Vector2(-20, OFFSET_IDLE_RIGHT.y)
const OFFSET_RUN_LEFT: Vector2 = Vector2(-25, OFFSET_RUN_RIGHT.y)
const OFFSET_JUMP_LEFT: Vector2 = Vector2(-20, OFFSET_JUMP_RIGHT.y)
const OFFSET_FALL_LEFT: Vector2 = Vector2(-20, OFFSET_JUMP_RIGHT.y)
const OFFSET_UP_LEFT: Vector2 = Vector2(6.5, OFFSET_UP_RIGHT.y)
const OFFSET_RUNUP_LEFT: Vector2 = Vector2(0, OFFSET_UP_RIGHT.y)

func _ready() -> void:
	current_level = SceneManager.current_level
	if current_level >= 2: double_jump_power_activated = true
	if current_level >= 3: dash_power_activated = true
	if current_level >= 4: wall_grab_power_activated = true
		
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
		
	var input_vector = Vector2.ZERO
	var is_jump_pressed = false
	var is_dash_pressed = false
	var is_shoot_pressed = false

	if is_cutscene:
		# Solucionado: Fricción basada en tiempo delta para evitar comportamiento errático de frenado
		velocity.x = move_toward(velocity.x, 0, movement_velocity * delta * 10)
	elif not is_stunned:
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
			
			var is_center_supported = raycast_floor.is_colliding()
			var is_left_supported = raycast_edge_left.is_colliding()
			var is_right_supported = raycast_edge_right.is_colliding()
			
			if is_on_floor() and not is_center_supported:
				if is_left_supported and not is_right_supported: velocity.x = slip_speed
				elif is_right_supported and not is_left_supported: velocity.x = -slip_speed
			
			if Input.is_action_pressed("ui_down") and is_jump_pressed and raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Platform"):
				ignore_platform_collision()
			elif is_jump_pressed:
				audio_jump.play() 
				state = State.JUMP
				velocity.y = jump_force
			elif not is_on_floor(): state = State.FALL
			elif input_vector.x != 0: state = State.RUN
			elif is_dash_pressed and dash_power_activated and can_dash:
				_start_dash()
				
		State.RUN:
			velocity.y += gravity * delta
			velocity.x = input_vector.x * movement_velocity
			
			if Input.is_action_pressed("ui_down") and is_jump_pressed and raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Platform"):
				ignore_platform_collision()
			elif is_jump_pressed:
				audio_jump.play()
				state = State.JUMP
				velocity.y = jump_force
			elif not is_on_floor(): state = State.FALL
			elif input_vector.x == 0: state = State.IDLE
			elif is_dash_pressed and dash_power_activated and can_dash:
				_start_dash()

		State.JUMP, State.FALL:
			velocity.y += gravity * delta
			velocity.x = input_vector.x * movement_velocity
			
			if is_dash_pressed and dash_power_activated and can_dash:
				_start_dash()
			
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
			if wall_grab_power_activated  and on_wall and collider and collider.is_in_group("Grabbable Wall") and is_moving_towards_wall:
				state = State.WALL_GRAB
		
		State.WALL_GRAB:
			if is_on_floor():
				state = State.IDLE
				return 
			
			var collider = raycast_wall.get_collider()
			var is_still_on_grabbable_wall = on_wall and collider and collider.is_in_group("Grabbable Wall")
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
		
		State.DASH:
			velocity.y = 0
			velocity.x = dash_velocity * (1.0 if player_dir == "RIGHT" else -1.0)
			
		State.DEAD:
			velocity.x = 0
			velocity.y += gravity * delta

	# Control de altura de salto (Jump Cut)
	if state == State.JUMP and Input.is_action_just_released("ui_jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
	
	# --- LÓGICA DE DISPARO OPTIMIZADA ---
	var can_fire_state = (state == State.IDLE or state == State.RUN or state == State.JUMP or state == State.FALL)
	if is_shoot_pressed and can_shoot and not is_stunned and can_fire_state:
		can_shoot = false # Bloquea el disparo
		audio_shoot.play()
		shoot_bullet()
		shoot_cooldown_timer.start() # Inicia el temporizador de forma segura
	
	move_and_slide()
	
	if is_alive:
		update_sprite_direction()
		handle_double_jump()
	update_animation()

func _start_dash() -> void:
	state = State.DASH
	audio_dash.play()
	velocity.y = 0
	dash_duration_timer.start()

func update_sprite_direction() -> void:
	var offset := 10
	var dir_mult := 1 if player_dir == "RIGHT" else -1
	var edge_offset_x = 10
	
	if state == State.WALL_GRAB:
		animated_sprite.flip_h = (player_dir == "RIGHT")
		for s in animated_sprites: s.position.x = -offset * dir_mult
		return
	
	if velocity.x < 0: player_dir = "LEFT"
	elif velocity.x > 0: player_dir = "RIGHT"
		
	var flip := (player_dir == "LEFT")
	for s in animated_sprites: s.flip_h = flip
	
	bullet_dir = Vector2.LEFT if player_dir == "LEFT" else Vector2.RIGHT
	dir_mult = -1 if player_dir == "LEFT" else 1

	for s in animated_sprites: s.position.x = offset * dir_mult
	
	raycast_wall.target_position.x = offset * dir_mult
	raycast_wall.position.x = offset
	raycast_floor.position.x = offset
	collision_shape.position.x = offset
	area2D.position.x = offset
	raycast_edge_left.position.x = offset - edge_offset_x 
	raycast_edge_right.position.x = offset + edge_offset_x
	
func update_animation() -> void:
	match state:
		State.IDLE:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					bullet_dir = Vector2.UP
					bullet_offset = OFFSET_UP_RIGHT if player_dir == "RIGHT" else OFFSET_UP_LEFT
					if animated_sprite3.animation != "SIdle Shooting Up":
						animated_sprite3.play("SIdle Shooting Up")
					switch_animation(3)
				else:
					bullet_dir = check_direction()
					bullet_offset = OFFSET_IDLE_RIGHT if player_dir == "RIGHT" else OFFSET_IDLE_LEFT
					if animated_sprite2.animation != "SIdle Shooting Rect":
						animated_sprite2.play("SIdle Shooting Rect")
					switch_animation(2)
			else:
				if animated_sprite.animation != "SIdle with Gun":
					animated_sprite.play("SIdle with Gun")
				switch_animation(1)

		State.RUN:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					bullet_dir = Vector2.UP
					bullet_offset = OFFSET_RUNUP_RIGHT if player_dir == "RIGHT" else OFFSET_RUNUP_LEFT
					if animated_sprite3.animation != "SRun Shooting Up":
						animated_sprite3.play("SRun Shooting Up")
					switch_animation(3)
				else:
					bullet_dir = check_direction()
					bullet_offset = OFFSET_RUN_RIGHT if player_dir == "RIGHT" else OFFSET_RUN_LEFT
					if animated_sprite2.animation != "SRun Shooting Rect":
						animated_sprite2.play("SRun Shooting Rect")
					switch_animation(2)
			else:
				if animated_sprite.animation != "SRun with Gun":
					animated_sprite.play("SRun with Gun")
				switch_animation(1)

		State.JUMP:
			if just_double_jumped:
				bullet_offset = OFFSET_JUMP_RIGHT if player_dir == "RIGHT" else OFFSET_JUMP_LEFT
				if animated_sprite.animation != "Double_Jump":
					animated_sprite.play("Double_Jump")
				just_double_jumped = false
			else:
				bullet_offset = OFFSET_JUMP_RIGHT if player_dir == "RIGHT" else OFFSET_JUMP_LEFT
				if animated_sprite.animation != "Double_Jump" and animated_sprite.animation != "SJump":
					animated_sprite.play("SJump")
			switch_animation(1)

		State.FALL:
			bullet_offset = OFFSET_JUMP_RIGHT if player_dir == "RIGHT" else OFFSET_JUMP_LEFT
			if animated_sprite.animation != "SFall":
				animated_sprite.play("SFall")
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
		1: animated_sprite.visible = true
		2: animated_sprite2.visible = true
		3: animated_sprite3.visible = true

func hide_all_sprites() -> void:
	animated_sprite.visible = false
	animated_sprite2.visible = false
	animated_sprite3.visible = false

func handle_double_jump() -> void:
	if not double_jump_power_activated: return
	
	if is_on_floor():
		double_jump_enabled = false
		first_jump_completed = false
		return
		
	if raycast_wall.is_colliding():
		var collider = raycast_wall.get_collider()
		if collider and collider.is_in_group("Jumpeable Wall"):
			double_jump_enabled = true
			first_jump_completed = true
		else:
			double_jump_enabled = false
	else:
		double_jump_enabled = false

func shoot_bullet() -> void:
	update_animation() # Fuerza la actualización de offsets de bala antes de instanciar
	
	var bullet = bullet_scene.instantiate() as Area2D
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	if bullet.has_method("set_mask"):
		bullet.set_mask(3)
	if bullet.has_method("set_direction"):
		bullet.set_direction(bullet_dir)
			
	bullet.global_position = global_position + bullet_offset
	
	var current_scene = get_tree().current_scene
	if current_scene: current_scene.add_child(bullet)

func ignore_platform_collision() -> void:
	state = State.FALL
	collision_shape.disabled = true
	velocity.y = jump_force * -1.5
	await (get_tree().create_timer(fall_through_time).timeout)
	collision_shape.disabled = false

func take_damage(force_death: bool = false, damage: int = 1) -> void:
	return
	if (is_invincible and not force_death) or not is_alive:
		return
		
	if force_death: lives = 0
	else:
		lives -= damage
		audio_hurts.play()
	
	emit_signal("change_UI_lives", lives)
	
	if lives <= 0:
		is_alive = false
		state = State.DEAD
		call_deferred("disable_player_collision")
		dead_timer.start()
		animation_player.stop() 
		
		if animation_player.has_animation("RESET"):
			animation_player.play("RESET")
	else:
		is_invincible = true
		hurt_timer.start(1) 
		is_stunned = true
		velocity.y = hurt_jump_force
		animation_player.play("Hurt")
		
		await get_tree().create_timer(0.5).timeout
		is_stunned = false

func increase_life() -> bool:
	if lives < 5:
		lives += 1
		emit_signal("change_UI_lives", lives)
		return true
	else:
		if SceneManager.life_packs < 3:
			SceneManager.life_packs += 1
			SceneManager.save_game_data()
			emit_signal("change_UI_lives", lives)
			audio_packUp.play()
			return true
		else:
			return false

func disable_player_collision() -> void:
	area2D.set_collision_mask_value(3, false)
	area2D.set_collision_mask_value(4, false)
	area2D.set_collision_mask_value(5, false)

func _on_body_entered(body) -> void:
	if is_instance_valid(body) and body.is_in_group("Enemy") and body.is_alive:
		take_damage()

func check_direction()-> Vector2:
	return Vector2.LEFT if (player_dir == "LEFT") else Vector2.RIGHT

func _on_dash_duration_timer_timeout() -> void:
	dash_cool_down_timer.start()
	can_dash = false
	state = State.IDLE if is_on_floor() else State.FALL

func _on_dash_cool_down_timeout() -> void:
	can_dash = true

func _on_dead_timer_timeout() -> void:
	player_died.emit()

func _on_area_entered(area: Area2D) -> void:
	if is_instance_valid(area) and area.is_in_group("Dead"):
		take_damage(true)

func _on_hurt_timer_timeout() -> void:
	is_invincible = false
	is_stunned = false

func _on_shoot_cooldown_timer_timeout() -> void:
	can_shoot = true
