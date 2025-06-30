extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite2:AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite3:AnimatedSprite2D = $AnimatedSprite2D3

var animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast_floor: RayCast2D = $RayCast2D2
@onready var raycast_wall: RayCast2D = $RayCast2D
@onready var area2D: Area2D = $Area2D

@onready var audio_dash: AudioStreamPlayer2D = $AudioStream_Dash
@onready var audio_jump: AudioStreamPlayer2D = $AudioStream_Jump
@onready var audio_hurts: AudioStreamPlayer2D = $AudioStream_Hurts
@onready var audio_shoot: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var audio_landing: AudioStreamPlayer2D = $AudioStream_Landing

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var dashing_timer: Timer = $Timer3
@onready var dash_timer: Timer = $Timer2
@onready var dead_timer: Timer = $Timer

signal player_died

var gravity: int = 2000
var jump_force: float = -550
var jump_cut_multiplier: float = 0.5
var player_dir: String = "RIGHT"
var dash_velocity: int = 400
var movement_velocity: int = 250
var fall_through_time: float = 0.05

var was_in_air: bool = false
var can_dash: bool = false
var is_dashing: bool = false
var double_jump_enabled: bool = false
var first_jump_completed: bool = false

var is_alive: bool = true
var lives: int = 5

var bullet_scene = preload("res://Prefabs/Bullet.tscn")
var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2

var gun_type: String ="Small"
var current_state: String = ""
var change_gun_type: bool = false

var hurt_jump_force: float = -200
var current_level: int

signal change_UI_lives(change_lives)

func _ready() -> void:
	current_level = SceneManager.current_level
	
	if current_level >= 3:
		can_dash = true

func _physics_process(delta) -> void:
	if is_alive:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
		if !is_on_floor() and velocity.y > 0:
			was_in_air = true
		elif raycast_floor.is_colliding() and was_in_air:
			audio_jump.stop()
			audio_landing.play()
			was_in_air = false
		
		if Input.is_action_just_pressed("Shoot"):
			audio_shoot.play()
			shoot_bullet()
		
		if Input.is_action_just_pressed("ui_jump"):
			if Input.is_action_pressed("ui_down") && raycast_floor.is_colliding():
				var collider = raycast_floor.get_collider()
				if collider.is_in_group("Platform"):
					ignore_platform_collision()
			elif is_on_floor():
				audio_jump.play()
				match player_dir:
						"RIGHT":
							bullet_offset = Vector2(35, -9)
							bullet_dir = Vector2.RIGHT
						"LEFT":
							bullet_offset = Vector2(-15, -9)
							bullet_dir = Vector2.LEFT
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
		
		if Input.is_action_just_pressed("Dash") and can_dash:
			audio_dash.play()
			can_dash = false
			is_dashing = true
			animated_sprite.stop()
			animated_sprite.play("Dash")
			current_state = "Dash"
			dashing_timer.start()
			dash_timer.start()
		
		velocity.x = input_vector.x * (dash_velocity if is_dashing else movement_velocity)
		
		if Input.is_action_just_released("ui_jump") and velocity.y < 0:
			velocity.y *= jump_cut_multiplier
		
	else:
		velocity.x = 0
	
	velocity.y += gravity * delta
	
	move_and_slide()                 
	if is_alive:update_sprite_direction()        
	update_animation()               
	handle_double_jump()

func update_sprite_direction() -> void:
	var offset = 10
	if velocity.x < 0:
		animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3]
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
		animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3]
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
	if not is_alive:
		return
	
	if animated_sprite.animation != "Hurt" and lives != 0:
		if not is_on_floor() and velocity.y > 250:
			match gun_type:
				"Small":
					animated_sprite.play("SFall")
				"Big":
					animated_sprite.play("BFall")
			current_state = "Fall"
			switch_animation(1)
		
		elif velocity.x == 0 and velocity.y == 0:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					animator_controller("Idle", 3)
					bullet_dir = Vector2.UP
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(12, -25)
						"LEFT":
							bullet_offset = Vector2(10, -25)
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
				
		
		elif is_on_floor() and not is_dashing and (
			Input.get_action_strength("ui_left") or Input.get_action_strength("ui_right")
			):
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					animator_controller("Run", 3)
					bullet_dir = Vector2.UP
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(25, -25)
						"LEFT":
							bullet_offset = Vector2(-5, -25)
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

func animator_controller(state_trigger: String, animation_number: int) -> void:
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
	
	switch_animation(animation_number)

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
	if current_level < 2:
		return
		
	if raycast_wall.is_colliding():
		var collider = raycast_wall.get_collider()
		if collider.is_in_group("Wall"):
			double_jump_enabled = true
		if collider.is_in_group("Floor"):
			double_jump_enabled = false
	else:
		double_jump_enabled = false

func shoot_bullet() -> void:
	update_animation()
	
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.mask = 3
	bullet.shooter = self
	
	bullet.change_bullet_speed(245)
	bullet.change_bullet_acceleration(300)  
	bullet.change_bullet_lifetime(0.7)   
	
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir
	
	get_tree().current_scene.add_child(bullet)

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
	if is_alive:
		audio_hurts.play()
		lives -= 1
		emit_signal("change_UI_lives", lives)
		if lives <= 0:
			is_alive = false
			animated_sprite.play("Death")
			animated_sprite2.play("Death")
			animated_sprite3.play("Death")
			
			current_state = "Death"
			call_deferred("disable_player_collision")
			dead_timer.start()
			
		else:
			animation_player.play("Hurt")
			velocity.y = hurt_jump_force

func _on_body_entered(body) -> void:
	if body.is_in_group("Enemy") and body.is_alive:
		take_damage()

func increase_life() -> bool:
	if lives < 3:
		lives += 1
		emit_signal("change_UI_lives", lives)
		return true
	else:
		return false

func disable_player_collision() -> void:
	area2D.set_collision_mask_value(3,false)
	area2D.set_collision_mask_value(4,false)
	area2D.set_collision_mask_value(5,false)

#func enable_player_collision() -> void:
#	area2D.set_collision_mask_value(3,true)
#	area2D.set_collision_mask_value(4,true)
#	area2D.set_collision_mask_value(5,true)

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_can_dash_timeout() -> void:
	can_dash = true

func _on_dead_timer_timeout() -> void:
	player_died.emit()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Dead"):
		lives = 0
		take_damage()
