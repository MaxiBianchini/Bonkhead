extends CharacterBody2D

# ==============================================================================
# SEÑALES
# ==============================================================================
signal health_changed(new_health)
signal toggle_hazards(is_active)
signal add_points(amount)
signal boss_die()
signal boss_intro_started()
signal phase_changed(new_state, current_health)


# ==============================================================================
# CONFIGURACIÓN Y ESTADÍSTICAS GLOBALES
# ==============================================================================
@export_group("Stats")
@export var max_health: int = 350
var current_health: float

@export_group("Daño Recibido por Fase")
@export var dmg_phase_1: float = 1.5
@export var dmg_phase_2: float = 1.5
@export var dmg_phase_3: float = 3

@export_group("Velocidades")
@export var ground_speed: float = 100.0
@export var dash_speed: float = 400.0
@export var air_patrol_speed: float = 650.0
@export var stomp_speed: float = 1300.0


# ==============================================================================
# CONFIGURACIÓN FASE 2
# ==============================================================================
@export_group("Fase 2: Configuración")
@export var hover_height: float = 1540
@export var patrol_min_x: float = 1600.0
@export var patrol_max_x: float = 2145.0
@export var high_hover_height: float = 1350
@export var bullet_scene: PackedScene
@export var bomb_scene: PackedScene
@export var bullet_sprite: Texture2D 

@export_group("Timers Config")
@export var min_attack_cooldown: float = 1.0
@export var max_attack_cooldown: float = 2.0
@export var min_mode_duration: float = 15.0
@export var max_mode_duration: float = 25.0


# ==============================================================================
# CONFIGURACIÓN FASE 3
# ==============================================================================
@export_group("Fase 3: Caos")
@export var center_position: Vector2 = Vector2(1875, 1350) 
@export var chaos_duration_shooting: float = 8.0 
@export var chaos_duration_chasing: float = 10.0 
@export var erratic_speed: float = 600.0
@export var p3_area_min: Vector2 = Vector2(1600, 1150) 
@export var p3_area_max: Vector2 = Vector2(2145, 1600) 


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var audio_shoot = $AudioStream_Shoot
@onready var audio_dash = $AudioStream_Dash
@onready var audio_death = $AudioStream_Death
@onready var audio_slam = $AudioStream_Slam
@onready var audio_hurt = $AudioStream_Hurt if has_node("AudioStream_Hurt") else null
@onready var animated_sprite = $AnimatedSprite2D


# ==============================================================================
# ENUMS Y VARIABLES DE ESTADO
# ==============================================================================
enum States { PHASE_1_GROUND, PHASE_2_AIR, PHASE_3_CHAOS }
var current_state: States = States.PHASE_1_GROUND

enum AttackModes { STOMP_MODE, BOMB_MODE }
var current_attack_mode: AttackModes = AttackModes.STOMP_MODE
var next_low_attack_mode: AttackModes = AttackModes.STOMP_MODE

enum Phase2SubState { LOW_ATTACK, TRANSITION_UP, HIGH_SHOOTING, TRANSITION_DOWN, STOMP_FALLING, STOMP_RECOVERING }
var p2_sub_state: Phase2SubState = Phase2SubState.LOW_ATTACK

enum Phase3SubState { BULLET_HELL, ERRATIC_CHASE }
var p3_sub_state: Phase3SubState = Phase3SubState.BULLET_HELL

enum BulletPatterns { SPIRAL, NOVA, AIMED }
var current_bullet_pattern: BulletPatterns = BulletPatterns.SPIRAL

# --- Variables de control general ---
var is_invulnerable: bool = false
var can_attack: bool = true
var is_dashing: bool = false
var is_hovering: bool = false
var is_attacking: bool = false 
var moving_right: bool = true
var is_alive: bool = true
var points: int = 1000

# --- Variables de la Fase 3 ---
var p3_target_position: Vector2 = Vector2.ZERO 
var spiral_angle: float = 0.0 
var p3_timer: float = 0.0
var p3_point_timeout: float = 0.0 
var p3_is_waiting: bool = false 
var last_bullet_pattern: int = -1
var pattern_bag: Array = []
var shoot_timer: float = 0.0
var shoot_delay: float = 0.1

# --- Referencias dinámicas ---
var player: Node2D = null
var current_tween: Tween
var damage_tween: Tween


# ==============================================================================
# FUNCIONES DE CICLO DE VIDA Y GESTIÓN DE ESTADOS GLOBALES
# ==============================================================================

func _ready():
	# Inicialización de estado y ocultamiento del jefe antes de la batalla
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	visible = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

func load_phase_checkpoint(saved_state: int, saved_health: int):
	# Restaura el estado guardado
	current_state = saved_state as States
	current_health = saved_health

func play_intro_sequence():
	# Maneja el parpadeo visual introductorio del jefe
	visible = true
	emit_signal("boss_intro_started")
	
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	for i in 6:
		current_tween.tween_property(self, "modulate:a", 1.0, 0.1)
		current_tween.tween_property(self, "modulate:a", 0.0, 0.1)
	
	current_tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await current_tween.finished

func start_battle():
	# Activa las físicas y las colisiones para iniciar el combate
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	change_state(current_state)

func _physics_process(delta):
	# Bucle principal que delega el procesamiento según la fase actual
	if not is_instance_valid(player) or current_health <= 0: 
		return
		
	match current_state:
		States.PHASE_1_GROUND: _process_phase_1(delta)
		States.PHASE_2_AIR: _process_phase_2(delta)
		States.PHASE_3_CHAOS: _process_phase_3(delta)

func change_state(new_state: States):
	# Gestiona las transiciones y la inicialización de cada nueva fase
	cleanup_timers()
	if current_tween: current_tween.kill()
	current_state = new_state
	
	match current_state:
		States.PHASE_1_GROUND: set_physics_process(true) 
		States.PHASE_2_AIR: start_low_attack_sequence()
		States.PHASE_3_CHAOS:
			emit_signal("toggle_hazards", true)
			start_p3_bullet_hell()

func cleanup_timers():
	# Restablece los flags de control de estado
	is_attacking = false
	is_dashing = false
	can_attack = true
	is_invulnerable = false


# ==============================================================================
# LÓGICA DE FASE 1: ATAQUE TERRESTRE (GROUND PHASE)
# ==============================================================================

func _process_phase_1(_delta):
	# Maneja el movimiento y persecución en el suelo
	if is_dashing:
		move_and_slide()
		if is_on_wall(): is_dashing = false
		return

	var direction_to_player = global_position.direction_to(player.global_position)
	if direction_to_player.x > 0: animated_sprite.play("Right")
	else: animated_sprite.play("Left")
	
	if can_attack: start_dash_attack()
	else:
		velocity.x = direction_to_player.x * 50
		velocity.y = 0 
		move_and_slide()

func start_dash_attack():
	# Ejecuta el ataque de embestida (Dash) con advertencia visual (color amarillo)
	audio_dash.play()
	can_attack = false
	velocity = Vector2.ZERO
	
	animated_sprite.modulate = Color(0.9, 0.9, 0.171, 1.0)
	await get_tree().create_timer(1.0).timeout
	if current_state != States.PHASE_1_GROUND: return
	
	animated_sprite.modulate = Color.WHITE
	is_dashing = true
	if audio_dash: audio_dash.play()
	
	var dir = 1 if player.global_position.x > global_position.x else -1
	velocity = Vector2(dir * dash_speed, 0)
	
	await get_tree().create_timer(0.8).timeout
	if current_state != States.PHASE_1_GROUND: return
	
	is_dashing = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(2.0).timeout
	can_attack = true


# ==============================================================================
# LÓGICA DE FASE 2: ATAQUE AÉREO Y PELIGROS (AIR PHASE)
# ==============================================================================

func _process_phase_2(_delta):
	# Delegador de comportamientos aéreos basado en sub-estados
	match p2_sub_state:
		Phase2SubState.LOW_ATTACK:
			_handle_patrol_movement()
		Phase2SubState.HIGH_SHOOTING:
			velocity = Vector2.ZERO
			animated_sprite.play("Idle") 
			move_and_slide()
		Phase2SubState.STOMP_FALLING:
			velocity.y = stomp_speed
			velocity.x = 0 
			move_and_slide()
			if is_on_floor(): _on_stomp_impact()

func start_low_attack_sequence():
	p2_sub_state = Phase2SubState.LOW_ATTACK
	is_invulnerable = false
	await fly_to_height(hover_height)
	if current_state != States.PHASE_2_AIR: return
	
	var duration = randf_range(min_mode_duration, max_mode_duration)
	get_tree().create_timer(duration).timeout.connect(start_high_hazard_sequence)
	start_attack_loop()

func start_high_hazard_sequence():
	if current_state != States.PHASE_2_AIR: return
	p2_sub_state = Phase2SubState.TRANSITION_UP
	is_invulnerable = true
	emit_signal("toggle_hazards", true)
	
	await fly_to_height(high_hover_height)
	if current_state != States.PHASE_2_AIR: return
	
	p2_sub_state = Phase2SubState.HIGH_SHOOTING
	start_shooting_loop()
	await get_tree().create_timer(8.0).timeout
	end_high_hazard_sequence()

func end_high_hazard_sequence():
	if current_state != States.PHASE_2_AIR: return
	p2_sub_state = Phase2SubState.TRANSITION_DOWN
	emit_signal("toggle_hazards", false)
	
	# Alterna entre pisotón (stomp) y bombas para el siguiente ciclo
	next_low_attack_mode = AttackModes.BOMB_MODE if next_low_attack_mode == AttackModes.STOMP_MODE else AttackModes.STOMP_MODE
	start_low_attack_sequence()

func start_attack_loop():
	# Maneja el ciclo ininterrumpido de ataques bajos
	if p2_sub_state != Phase2SubState.LOW_ATTACK or current_state != States.PHASE_2_AIR: return
		
	if next_low_attack_mode == AttackModes.STOMP_MODE: perform_stomp_attack() 
	else: perform_bomb_attack() 
	
	if next_low_attack_mode == AttackModes.BOMB_MODE:
		var cooldown = randf_range(min_attack_cooldown, max_attack_cooldown)
		await get_tree().create_timer(cooldown).timeout
		if p2_sub_state == Phase2SubState.LOW_ATTACK: start_attack_loop()

func start_shooting_loop():
	if p2_sub_state != Phase2SubState.HIGH_SHOOTING or current_state != States.PHASE_2_AIR: return
	shoot_bullet_at_player()
	await get_tree().create_timer(1.0).timeout
	start_shooting_loop() 

func shoot_bullet_at_player():
	# Lógica para instanciar y apuntar balas hacia el jugador
	if not bullet_scene or not is_instance_valid(player): return
	if audio_shoot: audio_shoot.play()
	
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.global_position = global_position
	if bullet.has_method("set_sprite"): bullet.set_sprite(bullet_sprite)
	if bullet.has_method("set_shooter"): bullet.set_shooter(self)
	
	var bullet_dir = global_position.direction_to(player.global_position)
	if bullet.has_method("set_direction"): bullet.set_direction(bullet_dir)
	if bullet.has_method("set_mask"): bullet.set_mask(2)
	
	var current_scene = get_tree().current_scene
	if current_scene: current_scene.add_child(bullet)
	if bullet.has_meta("delete_mask"): bullet.delete_mask(1)

func _handle_patrol_movement():
	# Patrullaje horizontal delimitado
	if is_attacking: 
		move_and_slide() 
		return
	
	if moving_right:
		velocity.x = air_patrol_speed
		animated_sprite.play("Right")
		if global_position.x >= patrol_max_x: moving_right = false
	else:
		velocity.x = -air_patrol_speed
		animated_sprite.play("Left")
		if global_position.x <= patrol_min_x: moving_right = true
	
	velocity.y = 0
	move_and_slide()

func perform_stomp_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("Attack")
	await get_tree().create_timer(0.5).timeout
	if current_state != States.PHASE_2_AIR: return
	p2_sub_state = Phase2SubState.STOMP_FALLING

func _on_stomp_impact():
	p2_sub_state = Phase2SubState.STOMP_RECOVERING 
	velocity = Vector2.ZERO
	if audio_slam: audio_slam.play()
	await get_tree().create_timer(1.0).timeout
	if current_state != States.PHASE_2_AIR: return
	fly_to_hover_position()

func perform_bomb_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("Attack 2")
	await get_tree().create_timer(0.5).timeout
	
	if bomb_scene:
		var bomb = bomb_scene.instantiate()
		bomb.global_position = global_position + Vector2(0, 30)
		var current_scene = get_tree().current_scene
		if current_scene: current_scene.add_child(bomb)
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	if p2_sub_state == Phase2SubState.LOW_ATTACK: animated_sprite.play("Idle") 

func fly_to_hover_position():
	# Recuperación post-ataques aéreos
	is_hovering = false
	is_attacking = true
	await fly_to_height(hover_height)
	is_hovering = true
	is_attacking = false 
	p2_sub_state = Phase2SubState.LOW_ATTACK 
	
	var cooldown = randf_range(min_attack_cooldown, max_attack_cooldown)
	await get_tree().create_timer(cooldown).timeout
	if current_state != States.PHASE_2_AIR: return
	start_attack_loop()


# ==============================================================================
# LÓGICA DE FASE 3: CAOS Y BULLET HELL (CHAOS PHASE)
# ==============================================================================

func _process_phase_3(delta):
	# Alterna cíclicamente entre patrones de disparos y persecuciones erráticas
	if p3_timer > 0:
		p3_timer -= delta
		if p3_timer <= 0: _swap_p3_sub_state()
	
	match p3_sub_state:
		Phase3SubState.BULLET_HELL:
			velocity = Vector2.ZERO
			animated_sprite.play("Idle") 
			move_and_slide()
			
			shoot_timer -= delta
			if shoot_timer <= 0:
				shoot_timer = shoot_delay 
				if audio_shoot: audio_shoot.play()
				
				# Selección del patrón actual
				match current_bullet_pattern:
					BulletPatterns.SPIRAL: perform_spiral_pattern(delta)
					BulletPatterns.NOVA: perform_nova_pattern()
					BulletPatterns.AIMED: perform_aimed_pattern()
						
		Phase3SubState.ERRATIC_CHASE:
			animated_sprite.play("Still")
			if p3_is_waiting:
				velocity = Vector2.ZERO
				move_and_slide()
				return
				
			var direction = global_position.direction_to(p3_target_position)
			velocity = direction * erratic_speed
			move_and_slide()
			
			p3_point_timeout -= delta
			if global_position.distance_to(p3_target_position) < 50.0 or p3_point_timeout <= 0:
				_wait_and_reposition()

func _wait_and_reposition():
	p3_is_waiting = true 
	velocity = Vector2.ZERO 
	animated_sprite.play("Still") 
	
	await get_tree().create_timer(1.0).timeout
	if current_state != States.PHASE_3_CHAOS or p3_sub_state != Phase3SubState.ERRATIC_CHASE: return
		
	pick_random_erratic_point()
	p3_is_waiting = false

func perform_spiral_pattern(delta):
	spiral_angle += 5.0 * delta 
	shoot_bullet_angle(spiral_angle)
	shoot_bullet_angle(spiral_angle + deg_to_rad(120))
	shoot_bullet_angle(spiral_angle + deg_to_rad(240))

func perform_nova_pattern():
	var bullets_amount = 12
	var angle_step = TAU / bullets_amount
	for i in range(bullets_amount):
		var angle = i * angle_step + randf_range(-0.1, 0.1) 
		shoot_bullet_angle(angle)

func perform_aimed_pattern():
	if not player: return
	var dir_to_player = global_position.direction_to(player.global_position)
	var base_angle = dir_to_player.angle()
	
	shoot_bullet_angle(base_angle)
	shoot_bullet_angle(base_angle + deg_to_rad(15))
	shoot_bullet_angle(base_angle - deg_to_rad(15))

func shoot_bullet_angle(angle_rad: float):
	if not bullet_scene: return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	if bullet.has_method("set_sprite"): bullet.set_sprite(bullet_sprite)
	if bullet.has_method("set_shooter"): bullet.set_shooter(self)
	
	var dir = Vector2(cos(angle_rad), sin(angle_rad))
	if bullet.has_method("set_direction"): bullet.set_direction(dir)
	if bullet.has_method("set_mask"): bullet.set_mask(2)
	
	var current_scene = get_tree().current_scene
	if current_scene: current_scene.add_child(bullet)
	if bullet.has_meta("delete_mask"): bullet.delete_mask(1)

func get_next_pattern_from_bag() -> int:
	# Sistema "Random Bag" para evitar la repetición del mismo patrón de ataque
	if pattern_bag.is_empty():
		pattern_bag = [0, 1, 2] 
		pattern_bag.shuffle()
		if last_bullet_pattern != -1 and pattern_bag.front() == last_bullet_pattern:
			var first = pattern_bag.pop_front()
			pattern_bag.push_back(first)
			
	return pattern_bag.pop_front()

func start_p3_bullet_hell():
	p3_sub_state = Phase3SubState.BULLET_HELL
	is_invulnerable = true
	shoot_timer = 9999.0
	
	await fly_to_position(center_position)
	
	var new_pick = get_next_pattern_from_bag()
	current_bullet_pattern = new_pick as BulletPatterns
	last_bullet_pattern = new_pick 
	
	match current_bullet_pattern:
		BulletPatterns.SPIRAL: shoot_delay = 0.1 
		BulletPatterns.NOVA: shoot_delay = 0.8 
		BulletPatterns.AIMED: shoot_delay = 1.0
			
	p3_timer = chaos_duration_shooting
	shoot_timer = 0.0

func start_p3_erratic_chase():
	p3_sub_state = Phase3SubState.ERRATIC_CHASE
	is_invulnerable = false 
	p3_is_waiting = false
	set_collision_mask_value(1, false) 
	pick_random_erratic_point()
	p3_timer = chaos_duration_chasing

func _swap_p3_sub_state():
	if current_state != States.PHASE_3_CHAOS: return
	if p3_sub_state == Phase3SubState.BULLET_HELL: start_p3_erratic_chase()
	else: start_p3_bullet_hell()

func pick_random_erratic_point():
	var random_x = randf_range(p3_area_min.x, p3_area_max.x)
	var random_y = randf_range(p3_area_min.y, p3_area_max.y)
	p3_target_position = Vector2(random_x, random_y)
	p3_point_timeout = 2.0


# ==============================================================================
# FUNCIONES AUXILIARES DE MOVIMIENTO (TWEENS)
# ==============================================================================

func fly_to_height(target_y: float):
	set_physics_process(false)
	animated_sprite.play("Still") 
	
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	var target_pos = Vector2(1875, target_y) if p2_sub_state == Phase2SubState.TRANSITION_UP else Vector2(position.x, target_y) 
	
	current_tween.tween_property(self, "position", target_pos, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await current_tween.finished
	
	if is_instance_valid(self) and current_health > 0:
		set_physics_process(true)

func fly_to_position(target: Vector2):
	set_physics_process(false)
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self, "position", target, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	await current_tween.finished
	if is_instance_valid(self) and current_health > 0:
		set_physics_process(true)


# ==============================================================================
# LÓGICA DE DAÑO, VIDA Y MUERTE
# ==============================================================================

func take_damage():
	if not is_alive or is_invulnerable: return
	
	var damage_taken: float = 2
	match current_state:
		States.PHASE_1_GROUND: damage_taken = dmg_phase_1
		States.PHASE_2_AIR: damage_taken = dmg_phase_2
		States.PHASE_3_CHAOS: damage_taken = dmg_phase_3
			
	current_health -= damage_taken
	emit_signal("health_changed", current_health)
	if audio_hurt: audio_hurt.play()
	
	if damage_tween: damage_tween.kill()
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	if current_health <= 0: die()
	else: check_for_phase_change()

func check_for_phase_change():
	var pct = float(current_health) / float(max_health)
	
	if pct < 0.33 and current_state != States.PHASE_3_CHAOS:
		change_state(States.PHASE_3_CHAOS)
		emit_signal("phase_changed", States.PHASE_3_CHAOS, current_health)
	elif pct < 0.66 and current_state == States.PHASE_1_GROUND:
		change_state(States.PHASE_2_AIR)
		emit_signal("phase_changed", States.PHASE_2_AIR, current_health)

func die():
	is_alive = false
	emit_signal("add_points", points)
	
	set_collision_mask_value(1, true)
	animated_sprite.play("Death")
	if audio_death: audio_death.play()
	
	emit_signal("boss_die")
	cleanup_timers()
	
	if current_tween: current_tween.kill()
	if damage_tween: damage_tween.kill()
	
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	await get_tree().create_timer(2.0).timeout
	queue_free()
