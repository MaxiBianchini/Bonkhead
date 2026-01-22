extends CharacterBody2D

# --- SEÑALES ---
signal health_changed(new_health)
signal phase_changed(new_phase)

# --- CONFIGURACIÓN GENERAL ---
@export_group("Stats")
@export var max_health: int = 300
var current_health: int

@export_group("Velocidades")
@export var ground_speed: float = 100.0
@export var dash_speed: float = 400.0
@export var air_patrol_speed: float = 150.0
@export var stomp_speed: float = 600.0

# --- CONFIGURACIÓN FASE 2 (AIRE) ---
@export_group("Fase 2: Configuración")
@export var hover_height: float = 200.0 # Altura Y a la que vuela (ajusta según tu nivel)
@export var patrol_min_x: float = 1600.0 # Límite Izquierdo de la pantalla
@export var patrol_max_x: float = 2145.0 # Límite Derecho de la pantalla
@export var bomb_scene: PackedScene # ¡ARRASTRA TU ESCENA BOMB.TSCN AQUÍ!

# Tiempos de ataque (Frecuencia de disparos/golpes)
@export var min_attack_cooldown: float = 2.0
@export var max_attack_cooldown: float = 4.0

# Tiempos de Modo (Cuánto dura la estrategia de solo aplastar o solo bombas)
@export var min_mode_duration: float = 20.0
@export var max_mode_duration: float = 45.0

# --- VARIABLES INTERNAS ---
var player: Node2D = null
@onready var animated_sprite = $AnimatedSprite2D
# @onready var claw = $MechanicalClaw # Descomenta cuando agregues la garra

# Máquina de Estados Principal
enum States { PHASE_1_GROUND, PHASE_2_AIR, PHASE_3_CHAOS }
var current_state: States = States.PHASE_1_GROUND

# Máquina de Estados de Fase 2 (Modos de Ataque)
enum AttackModes { STOMP_MODE, BOMB_MODE }
var current_attack_mode: AttackModes = AttackModes.STOMP_MODE

# Variables de Control
var can_attack: bool = true
var is_dashing: bool = false # Fase 1
var is_hovering: bool = false # Fase 2
var is_attacking: bool = false # Fase 2 (Bloqueo de movimiento)

# Timers (Se crean por código)
var attack_cooldown_timer: Timer = null
var mode_switch_timer: Timer = null

# Control de Patrulla Fase 2
var moving_right: bool = true # Dirección actual de la patrulla aérea

signal add_points
var is_alive: bool = true
var points: int = 20

# --- INICIO ---
func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	
	# El jefe empieza oculto y desactivado (esperando a la cinemática)
	visible = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

# --- CINEMÁTICA DE ENTRADA ---
func play_intro_sequence():
	visible = true
	var tween = create_tween()
	
	# Parpadeo rápido (Glitch effect)
	for i in 6:
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished

func start_battle():
	print("Jefe: ¡Hora de luchar!")
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	change_state(States.PHASE_1_GROUND)

# --- BUCLE FÍSICO ---
func _physics_process(delta):
	if not player or current_health <= 0: return

	match current_state:
		States.PHASE_1_GROUND:
			_process_phase_1(delta)
		States.PHASE_2_AIR:
			_process_phase_2(delta)
		States.PHASE_3_CHAOS:
			_process_phase_3(delta)

# --- GESTIÓN DE ESTADOS ---
func change_state(new_state: States):
	current_state = new_state
	
	match current_state:
		States.PHASE_1_GROUND:
			print(">> FASE 1: TIERRA <<")
		
		States.PHASE_2_AIR:
			print(">> FASE 2: AIRE <<")
			emit_signal("phase_changed", 2)
			
			# Configurar Timer de Frecuencia de Ataque
			attack_cooldown_timer = Timer.new()
			attack_cooldown_timer.one_shot = true
			attack_cooldown_timer.timeout.connect(_on_attack_timer_timeout)
			add_child(attack_cooldown_timer)
			
			# Configurar Timer de Cambio de Modo (Estrategia)
			mode_switch_timer = Timer.new()
			mode_switch_timer.one_shot = true
			mode_switch_timer.timeout.connect(_swap_attack_mode)
			add_child(mode_switch_timer)
			
			# Iniciamos el primer modo y la subida
			_swap_attack_mode()
			fly_to_hover_position()
			
		States.PHASE_3_CHAOS:
			print(">> FASE 3: CAOS <<")
			emit_signal("phase_changed", 3)
			# Aquí iría la lógica futura de la fase 3

# ========================================================
#                     FASE 1: TIERRA
# ========================================================
func _process_phase_1(_delta):
	# Si está haciendo Dash, solo se mueve recto
	if is_dashing:
		move_and_slide()
		if is_on_wall(): # Si choca pared, corta el dash
			is_dashing = false
		return

	# Lógica de persecución / preparación
	var direction_to_player = global_position.direction_to(player.global_position)
	
	# Mirar al jugador
	if direction_to_player.x > 0: animated_sprite.play("Right")
	else: animated_sprite.play("Left")

	if can_attack:
		start_dash_attack()
	else:
		# Movimiento lento de "acecho"
		velocity.x = direction_to_player.x * 50
		move_and_slide()

func start_dash_attack():
	can_attack = false
	velocity = Vector2.ZERO
	
	# 1. Telegrafía (Rojo)
	animated_sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(1.0).timeout
	
	if current_state != States.PHASE_1_GROUND: return
	
	# 2. Dash
	animated_sprite.modulate = Color(1, 1, 1)
	is_dashing = true
	var dir = 1 if player.global_position.x > global_position.x else -1
	velocity = Vector2(dir * dash_speed, 0) # Asignamos velocidad constante
	
	await get_tree().create_timer(0.8).timeout # Duración del dash
	
	is_dashing = false
	velocity = Vector2.ZERO
	
	# 3. Enfriamiento
	await get_tree().create_timer(2.0).timeout
	can_attack = true

# ========================================================
#                     FASE 2: AIRE
# ========================================================
func _process_phase_2(_delta):
	# Si está atacando o subiendo, no patrulla
	if is_attacking or not is_hovering:
		move_and_slide()
		return

	# Patrulla simple
	if moving_right:
		velocity.x = air_patrol_speed
		animated_sprite.play("Right")
		# Si llegamos al límite derecho, cambiamos dirección
		if global_position.x >= patrol_max_x:
			moving_right = false
	else:
		velocity.x = -air_patrol_speed
		animated_sprite.play("Left")
		# Si llegamos al límite izquierdo, cambiamos dirección
		if global_position.x <= patrol_min_x:
			moving_right = true
			
	velocity.y = 0
	
	move_and_slide()
	
	# Iniciar timer de ataque con tiempo aleatorio si no está corriendo
	if attack_cooldown_timer.is_stopped():
		var random_time = randf_range(min_attack_cooldown, max_attack_cooldown)
		attack_cooldown_timer.wait_time = random_time
		attack_cooldown_timer.start()

# --- Lógica de Cambio de Modos (Aplastar vs Bombas) ---
func _swap_attack_mode():
	if current_state != States.PHASE_2_AIR: return
	
	# Alternar modo
	if current_attack_mode == AttackModes.STOMP_MODE:
		current_attack_mode = AttackModes.BOMB_MODE
		print("Modo: BOMBARDEO")
	else:
		current_attack_mode = AttackModes.STOMP_MODE
		print("Modo: APLASTAR")
	
	# Configurar duración aleatoria de este modo
	var random_duration = randf_range(min_mode_duration, max_mode_duration)
	mode_switch_timer.wait_time = random_duration
	mode_switch_timer.start()

# --- Ejecutar ataque según el modo actual ---
func _on_attack_timer_timeout():
	if current_state != States.PHASE_2_AIR: return
	if not player: return
	
	if current_attack_mode == AttackModes.STOMP_MODE:
		perform_stomp_attack()
	else:
		perform_bomb_attack()

# --- Ataque 1: Aplastar ---
func perform_stomp_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	
	print("¡Ataque Aplastar!")
	animated_sprite.play("Attack")
	await get_tree().create_timer(0.5).timeout
	
	velocity.y = stomp_speed
	
	# Caer hasta tocar suelo
	while not is_on_floor():
		move_and_slide()
		await get_tree().physics_frame
		if current_state != States.PHASE_2_AIR: return
	
	# Impacto
	print("¡PUM!")
	await get_tree().create_timer(1.0).timeout
	fly_to_hover_position()

# --- Ataque 2: Bombas ---
func perform_bomb_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	
	print("¡Ataque Bombas!")
	animated_sprite.play("Attack 2")
	await get_tree().create_timer(0.5).timeout # Sincronizar con animación
	
	if bomb_scene:
		var bomb = bomb_scene.instantiate()
		bomb.global_position = global_position + Vector2(0, 30)
		get_parent().add_child(bomb)
	else:
		print("ERROR: No has asignado la Bomb Scene en el Inspector")
		
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	animated_sprite.play("Idle")

# --- Utilidad: Volar a posición segura ---
func fly_to_hover_position():
	is_hovering = false
	is_attacking = true
	
	var tween = create_tween()
	# Subir suavemente a la altura definida en hover_height
	tween.tween_property(self, "position:y", hover_height, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	is_hovering = true
	is_attacking = false

# ========================================================
#                     FASE 3: CAOS (Placeholder)
# ========================================================
func _process_phase_3(_delta):
	# Aquí irá la lógica de la última fase
	pass

# ========================================================
#                     DAÑO Y VIDA
# ========================================================
func take_damage():
	if not is_alive:
		return
	
	current_health -= 10
	emit_signal("add_points", points)
	emit_signal("health_changed", current_health)
	
	# EFECTO DE DAÑO POR CÓDIGO
	var tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1) # Rojo puro
	
	# Volviendo a blanco en 0.2 segundos
	# set_trans(Tween.TRANS_SINE) hace que se vea suave
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	
	if current_health <= 0:
		is_alive = false
		print("Jefe Derrotado")
		animated_sprite.play("Death")
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
		# Detener timers si existen
		if attack_cooldown_timer: attack_cooldown_timer.stop()
		if mode_switch_timer: mode_switch_timer.stop()
		queue_free()
	
	# Verificar cambio de fase
	check_for_phase_change()
	

func check_for_phase_change():
	var pct = float(current_health) / float(max_health)
	
	# Cambio a Fase 3 (33% vida)
	if pct < 0.33 and current_state != States.PHASE_3_CHAOS:
		change_state(States.PHASE_3_CHAOS)
	
	# Cambio a Fase 2 (66% vida)
	elif pct < 0.66 and current_state == States.PHASE_1_GROUND:
		change_state(States.PHASE_2_AIR)

func die():
	print("Jefe Derrotado")
	animated_sprite.play("Death")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	# Detener timers si existen
	if attack_cooldown_timer: attack_cooldown_timer.stop()
	if mode_switch_timer: mode_switch_timer.stop()
