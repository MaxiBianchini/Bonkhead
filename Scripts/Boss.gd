extends CharacterBody2D

# --- SEÑALES ---
signal health_changed(new_health)
signal phase_changed(new_phase)
signal toggle_hazards(is_active) # Avisa al nivel para prender/apagar lava y plataformas

# --- CONFIGURACIÓN GENERAL ---
@export_group("Stats")
@export var max_health: int = 300
var current_health: int

@export_group("Velocidades")
@export var ground_speed: float = 100.0
@export var dash_speed: float = 400.0
@export var air_patrol_speed: float = 350.0
@export var stomp_speed: float = 600.0

# --- CONFIGURACIÓN FASE 2 (AIRE) ---
@export_group("Fase 2: Configuración")
@export var hover_height: float = 1540 # Altura Y a la que vuela (ajusta según tu nivel)
@export var patrol_min_x: float = 1600.0 # Límite Izquierdo de la pantalla
@export var patrol_max_x: float = 2145.0 # Límite Derecho de la pantalla
@export var high_hover_height: float = 1350 # Altura máxima para la fase de disparo (más arriba)
@export var bullet_scene: PackedScene # Arrastra aquí tu escena de bala/proyectil
@export var bomb_scene: PackedScene # ¡ARRASTRA TU ESCENA BOMB.TSCN AQUÍ!

# Sub-Estados de la Fase 2
enum Phase2SubState { LOW_ATTACK, TRANSITION_UP, HIGH_SHOOTING, TRANSITION_DOWN }
var p2_sub_state: Phase2SubState = Phase2SubState.LOW_ATTACK

var is_invulnerable: bool = false # Para cuando sube
var next_low_attack_mode: AttackModes = AttackModes.STOMP_MODE # Para alternar

# Tiempos de ataque (Frecuencia de disparos/golpes)
@export var min_attack_cooldown: float = 1.0
@export var max_attack_cooldown: float = 2.0

# Tiempos de Modo (Cuánto dura la estrategia de solo aplastar o solo bombas)
@export var min_mode_duration: float = 15.0
@export var max_mode_duration: float = 35.0

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
			
			print(">> FASE 2: SECUENCIA AÉREA <<")
			emit_signal("phase_changed", 2)
			
			# Arrancamos con el ataque bajo
			start_low_attack_sequence()
		
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
	# Máquina de estados interna de la Fase 2
	match p2_sub_state:
		Phase2SubState.LOW_ATTACK:
			# Comportamiento normal: Patrulla de izquierda a derecha
			_handle_patrol_movement()
			
		Phase2SubState.HIGH_SHOOTING:
			# El jefe se queda quieto arriba o sigue suavemente al player
			# Aquí haremos que solo dispare, quieto en X o movimiento muy lento
			velocity = Vector2.ZERO
			move_and_slide()


# --- FUNCIONES DE CONTROL DEL CICLO ---

func start_low_attack_sequence():
	p2_sub_state = Phase2SubState.LOW_ATTACK
	is_invulnerable = false # Ya se le puede pegar
	
	# Volamos a la altura baja (hover_height normal)
	fly_to_height(hover_height)
	await get_tree().create_timer(2.0).timeout # Esperar a que baje
	
	print("Fase 2: Iniciando ataque tipo ", "APLASTAR" if next_low_attack_mode == AttackModes.STOMP_MODE else "BOMBAS")
	
	# Iniciamos el Timer que decide cuánto dura esta fase de ataque antes de activar la lava
	# Usamos el timer de modos que ya tenías o creamos uno temporal
	var duration = randf_range(min_mode_duration, max_mode_duration)
	get_tree().create_timer(duration).timeout.connect(start_high_hazard_sequence)
	
	# Iniciamos el timer de los ataques individuales
	start_attack_loop()

func start_high_hazard_sequence():
	if current_state != States.PHASE_2_AIR: return
	
	print("Fase 2: ¡SUBIENDO! Activando Lava y Plataformas.")
	p2_sub_state = Phase2SubState.TRANSITION_UP
	is_invulnerable = true # ¡Escudo activado!
	
	# 1. Avisar al Nivel
	emit_signal("toggle_hazards", true)
	
	# 2. Subir a la altura alta
	await fly_to_height(high_hover_height)
	
	# 3. Empezar a Disparar
	p2_sub_state = Phase2SubState.HIGH_SHOOTING
	start_shooting_loop()
	
	# 4. Duración de la fase de lava (Ej: 8 segundos)
	await get_tree().create_timer(8.0).timeout
	
	# 5. Bajar
	end_high_hazard_sequence()

func end_high_hazard_sequence():
	if current_state != States.PHASE_2_AIR: return
	
	print("Fase 2: BAJANDO. Desactivando Lava.")
	p2_sub_state = Phase2SubState.TRANSITION_DOWN
	
	# 1. Avisar al Nivel
	emit_signal("toggle_hazards", false)
	
	# 2. Cambiar el modo de ataque para la próxima bajada
	if next_low_attack_mode == AttackModes.STOMP_MODE:
		next_low_attack_mode = AttackModes.BOMB_MODE
	else:
		next_low_attack_mode = AttackModes.STOMP_MODE
	
	# 3. Reiniciar ciclo
	start_low_attack_sequence()

# --- LÓGICA DE ATAQUES (Loops) ---

func start_attack_loop():
	# Este timer controla los ataques individuales (stomp/bomb) mientras está abajo
	if p2_sub_state == Phase2SubState.LOW_ATTACK:
		# Ejecutamos ataque
		if next_low_attack_mode == AttackModes.STOMP_MODE:
			perform_stomp_attack()
		else:
			perform_bomb_attack()
		
		# Esperar cooldown y repetir si seguimos en estado LOW
		var cooldown = randf_range(min_attack_cooldown, max_attack_cooldown)
		await get_tree().create_timer(cooldown).timeout
		if p2_sub_state == Phase2SubState.LOW_ATTACK:
			start_attack_loop()

func start_shooting_loop():
	# Este loop controla los disparos mientras está ARRIBA
	if p2_sub_state == Phase2SubState.HIGH_SHOOTING:
		shoot_bullet_at_player()
		
		# Dispara rápido (cada 1 segundo)
		await get_tree().create_timer(1.0).timeout
		if p2_sub_state == Phase2SubState.HIGH_SHOOTING:
			start_shooting_loop()

func shoot_bullet_at_player():
	if not bullet_scene: 
		print("ERROR: No has asignado la Bullet Scene en el Inspector del Boss")
		return
	
	# 1. Instanciar la bala
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.global_position = global_position # La bala sale del centro del jefe
	
	# 2. Configurar quién dispara (IMPORTANTE para que tu script sepa que es Enemy)
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	
	if player:
		# 3. Calcular la dirección normalizada hacia el jugador
		
		var bullet_dir = global_position.direction_to(player.global_position)
		
		# 4. Pasar la dirección a tu bala
		if bullet.has_method("set_direction"):
			bullet.set_direction( bullet_dir)
		
		if bullet.has_method("set_mask"):
			bullet.set_mask(2)
			
	# 5. Añadir al mundo (fuera del jefe)
	get_parent().add_child(bullet)
	
	if bullet.has_meta("delete_mask"):
			bullet.delete_mask(1)

# --- UTILIDADES ---
func _handle_patrol_movement():
	# Tu lógica de patrulla existente (izquierda/derecha)
	# Solo se ejecuta cuando está abajo
	if is_attacking: # Si está haciendo Stomp/Bomb, no moverse
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

func fly_to_height(target_y: float):
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(1850, target_y), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

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
	if not is_alive or is_invulnerable:
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
