extends CharacterBody2D

# --- SEÑALES ---
signal health_changed(new_health)
signal phase_changed(new_phase)
signal toggle_hazards(is_active)
signal boss_die()
signal add_points(amount)

# --- CONFIGURACIÓN GENERAL ---
@export_group("Stats")
@export var max_health: int = 300
var current_health: int

@export_group("Velocidades")
@export var ground_speed: float = 100.0
@export var dash_speed: float = 400.0
@export var air_patrol_speed: float = 550.0
@export var stomp_speed: float = 1300.0

# --- CONFIGURACIÓN FASE 2 (AIRE) ---
@export_group("Fase 2: Configuración")
@export var hover_height: float = 1540
@export var patrol_min_x: float = 1600.0
@export var patrol_max_x: float = 2145.0
@export var high_hover_height: float = 1350
@export var bullet_scene: PackedScene
@export var bomb_scene: PackedScene

# Sub-Estados de la Fase 2
enum Phase2SubState { 
	LOW_ATTACK, 
	TRANSITION_UP, 
	HIGH_SHOOTING, 
	TRANSITION_DOWN,
	STOMP_FALLING,    # NUEVO: Estado explícito para caer
	STOMP_RECOVERING  # NUEVO: Estado explícito tras el golpe
}
var p2_sub_state: Phase2SubState = Phase2SubState.LOW_ATTACK

var is_invulnerable: bool = false
var next_low_attack_mode: AttackModes = AttackModes.STOMP_MODE

@export_group("Timers Config")
@export var min_attack_cooldown: float = 1.0
@export var max_attack_cooldown: float = 2.0
@export var min_mode_duration: float = 15.0
@export var max_mode_duration: float = 35.0

# --- CONFIGURACIÓN FASE 3 (CAOS) ---
@export_group("Fase 3: Caos")
@export var center_position: Vector2 = Vector2(1850, 1350) # Posición "segura" en el centro
@export var chaos_duration_shooting: float = 8.0 # Tiempo disparando
@export var chaos_duration_chasing: float = 10.0 # Tiempo persiguiendo
@export var erratic_speed: float = 600.0 # Velocidad al perseguir

@export var p3_area_min: Vector2 = Vector2(1600, 1150) # La esquina SUPERIOR IZQUIERDA del rectángulo
@export var p3_area_max: Vector2 = Vector2(2145, 1600) # La esquina INFERIOR DERECHA del rectángulo

# Variables internas Fase 3
enum Phase3SubState { BULLET_HELL, ERRATIC_CHASE }
var p3_sub_state: Phase3SubState = Phase3SubState.BULLET_HELL
var p3_target_position: Vector2 = Vector2.ZERO # Para el movimiento errático
var spiral_angle: float = 0.0 # Para el patrón de disparo
var p3_timer: float = 0.0 # Control manual de tiempo
var p3_point_timeout: float = 0.0 # Variable nueva: Paciencia para llegar al punto
var p3_is_waiting: bool = false # Para saber si está en la pausa de 1 segundo

enum BulletPatterns { SPIRAL, NOVA, AIMED }
var current_bullet_pattern: BulletPatterns = BulletPatterns.SPIRAL

# Variables para controlar la cadencia según el patrón
var shoot_timer: float = 0.0
var shoot_delay: float = 0.1 # Tiempo entre disparos

# --- VARIABLES INTERNAS ---
var player: Node2D = null
@onready var animated_sprite = $AnimatedSprite2D

# Máquina de Estados Principal
enum States { PHASE_1_GROUND, PHASE_2_AIR, PHASE_3_CHAOS }
var current_state: States = States.PHASE_1_GROUND

# Modos de Ataque Fase 2
enum AttackModes { STOMP_MODE, BOMB_MODE }
var current_attack_mode: AttackModes = AttackModes.STOMP_MODE

# Variables de Control
var can_attack: bool = true
var is_dashing: bool = false
var is_hovering: bool = false
var is_attacking: bool = false # Bloqueo genérico

# Variables de Patrulla
var moving_right: bool = true
var is_alive: bool = true
var points: int = 20

# Referencias a Tweens activos (para poder cancelarlos si cambia la fase)
var current_tween: Tween

# --- INICIO ---
func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	
	visible = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

# --- CINEMÁTICA DE ENTRADA ---
func play_intro_sequence():
	visible = true
	# Limpiamos tween anterior si existiera
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	for i in 6:
		current_tween.tween_property(self, "modulate:a", 1.0, 0.1)
		current_tween.tween_property(self, "modulate:a", 0.0, 0.1)
	
	current_tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await current_tween.finished

func start_battle():
	print("Jefe: ¡Hora de luchar!")
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	change_state(States.PHASE_1_GROUND)

# --- BUCLE FÍSICO ---
func _physics_process(delta):
	# Validación de seguridad: Si murió o no hay player, no procesar
	if not is_instance_valid(player) or current_health <= 0: 
		return

	match current_state:
		States.PHASE_1_GROUND:
			_process_phase_1(delta)
		States.PHASE_2_AIR:
			_process_phase_2(delta)
		States.PHASE_3_CHAOS:
			_process_phase_3(delta)
			
	# Move and Slide centralizado (opcional, pero aquí lo dejamos dentro de cada estado
	# para respetar tu lógica de Tweens que a veces no usan física)

# --- GESTIÓN DE ESTADOS ---
func change_state(new_state: States):
	# Limpieza del estado anterior
	cleanup_timers()
	if current_tween: current_tween.kill()
	
	current_state = new_state
	
	match current_state:
		States.PHASE_1_GROUND:
			print(">> FASE 1: TIERRA <<")
			# Asegurar que la física esté activa
			set_physics_process(true) 
			
		States.PHASE_2_AIR:
			print(">> FASE 2: SECUENCIA AÉREA <<")
			emit_signal("phase_changed", 2)
			start_low_attack_sequence()
			
		States.PHASE_3_CHAOS:
			print(">> FASE 3: CAOS TOTAL <<")
			emit_signal("phase_changed", 3)
			
			# 1. Activamos Lava y Plataformas PERMANENTEMENTE
			emit_signal("toggle_hazards", true)
			
			# 2. Iniciamos la secuencia
			start_p3_bullet_hell()

# Utility para detener timers pendientes y evitar bugs al cambiar fase
func cleanup_timers():
	# En Godot 4, los timers creados con create_timer son SceneTreeTimers y no se pueden detener manualmente.
	# La estrategia es usar banderas de estado (current_state) dentro de los awaits para abortar la lógica.
	# Resetear banderas lógicas:
	is_attacking = false
	is_dashing = false
	can_attack = true
	is_invulnerable = false

# ========================================================
#                     FASE 1: TIERRA
# ========================================================
func _process_phase_1(_delta):
	if is_dashing:
		move_and_slide()
		if is_on_wall():
			is_dashing = false
		return

	# Lógica de persecución
	var direction_to_player = global_position.direction_to(player.global_position)
	
	if direction_to_player.x > 0: animated_sprite.play("Right")
	else: animated_sprite.play("Left")
	
	if can_attack:
		start_dash_attack()
	else:
		# Movimiento lento
		velocity.x = direction_to_player.x * 50
		velocity.y += 980 * _delta # Gravedad básica por si salta o cae
		move_and_slide()

func start_dash_attack():
	can_attack = false
	velocity = Vector2.ZERO
	
	animated_sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(1.0).timeout
	
	# GUARD: Verificar si cambiamos de estado durante la espera
	if current_state != States.PHASE_1_GROUND: return
	
	animated_sprite.modulate = Color.WHITE
	is_dashing = true
	
	var dir = 1 if player.global_position.x > global_position.x else -1
	velocity = Vector2(dir * dash_speed, 0)
	
	await get_tree().create_timer(0.8).timeout
	
	if current_state != States.PHASE_1_GROUND: return # Guard
	
	is_dashing = false
	velocity = Vector2.ZERO
	
	await get_tree().create_timer(2.0).timeout
	can_attack = true

# ========================================================
#                     FASE 2: AIRE
# ========================================================
func _process_phase_2(_delta):
	match p2_sub_state:
		Phase2SubState.LOW_ATTACK:
			_handle_patrol_movement()
			
		Phase2SubState.HIGH_SHOOTING:
			# Quieto o micro-movimiento
			velocity = Vector2.ZERO
			move_and_slide()
			
		# OPTIMIZACIÓN: Manejo de caída con física real
		Phase2SubState.STOMP_FALLING:
			velocity.y = stomp_speed
			velocity.x = 0 # Asegurar caída recta
			move_and_slide()
			
			if is_on_floor():
				_on_stomp_impact()

func start_low_attack_sequence():
	p2_sub_state = Phase2SubState.LOW_ATTACK
	is_invulnerable = false
	
	await fly_to_height(hover_height)
	if current_state != States.PHASE_2_AIR: return # Guard
	
	print("Fase 2: Iniciando ataque tipo ", "APLASTAR" if next_low_attack_mode == AttackModes.STOMP_MODE else "BOMBAS")
	
	# Timer para cambiar a fase de lava
	var duration = randf_range(min_mode_duration, max_mode_duration)
	# Usamos una función anónima o verificamos estado en la llamada
	get_tree().create_timer(duration).timeout.connect(start_high_hazard_sequence)
	
	start_attack_loop()

func start_high_hazard_sequence():
	if current_state != States.PHASE_2_AIR: return
	
	print("Fase 2: ¡SUBIENDO! Activando Lava.")
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
	
	print("Fase 2: BAJANDO.")
	p2_sub_state = Phase2SubState.TRANSITION_DOWN
	emit_signal("toggle_hazards", false)
	
	# Alternar modo
	if next_low_attack_mode == AttackModes.STOMP_MODE:
		next_low_attack_mode = AttackModes.BOMB_MODE
	else:
		next_low_attack_mode = AttackModes.STOMP_MODE
		
	start_low_attack_sequence()

# --- ATAQUES (Loops) ---
func start_attack_loop():
	# Si ya no estamos en modo ataque bajo o cambió la fase, abortamos el loop
	if p2_sub_state != Phase2SubState.LOW_ATTACK or current_state != States.PHASE_2_AIR:
		return

	if next_low_attack_mode == AttackModes.STOMP_MODE:
		perform_stomp_attack() # Esto ahora cambia el estado, no bloquea
	else:
		perform_bomb_attack() # Esto es async pero corto
		
	# Esperamos cooldown solo si fue bomba. 
	# Si fue Stomp, el loop se reinicia cuando el Stomp termina (en _on_stomp_impact o fly_to_hover).
	if next_low_attack_mode == AttackModes.BOMB_MODE:
		var cooldown = randf_range(min_attack_cooldown, max_attack_cooldown)
		await get_tree().create_timer(cooldown).timeout
		# Recursión segura
		if p2_sub_state == Phase2SubState.LOW_ATTACK:
			start_attack_loop()

func start_shooting_loop():
	if p2_sub_state != Phase2SubState.HIGH_SHOOTING or current_state != States.PHASE_2_AIR:
		return
		
	shoot_bullet_at_player()
	
	await get_tree().create_timer(1.0).timeout
	start_shooting_loop() # Recursión

func shoot_bullet_at_player():
	if not bullet_scene or not is_instance_valid(player): return
	
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.global_position = global_position
	
	if bullet.has_method("set_shooter"): bullet.set_shooter(self)
	
	var bullet_dir = global_position.direction_to(player.global_position)
	if bullet.has_method("set_direction"): bullet.set_direction(bullet_dir)
	if bullet.has_method("set_mask"): bullet.set_mask(2)
	
	get_parent().add_child(bullet)
	
	if bullet.has_meta("delete_mask"): bullet.delete_mask(1)

# --- UTILIDADES DE MOVIMIENTO ---
func _handle_patrol_movement():
	# Si estamos atacando (ej. animacion de inicio de stomp), no mover X
	if is_attacking: 
		move_and_slide() # Mantiene colisiones pero no velocity.x
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
	# Desactivamos physics process para que move_and_slide no pelee con el Tween
	set_physics_process(false)
	
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	# Volamos hacia un punto X seguro (ej. centro) o mantenemos X actual si prefieres
	var target_pos = Vector2(1850, target_y) 
	
	current_tween.tween_property(self, "position", target_pos, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	await current_tween.finished
	
	# Reactivamos física
	set_physics_process(true)

# --- Ataque 1: Aplastar (REFACTORIZADO) ---
func perform_stomp_attack():
	is_attacking = true # Bloquea patrulla horizontal
	velocity = Vector2.ZERO
	
	print("¡Ataque Aplastar!")
	animated_sprite.play("Attack")
	await get_tree().create_timer(0.5).timeout
	
	if current_state != States.PHASE_2_AIR: return
	
	# En lugar de while loop, cambiamos el estado para que _physics_process lo maneje
	p2_sub_state = Phase2SubState.STOMP_FALLING

# Función llamada por _physics_process cuando toca el suelo
func _on_stomp_impact():
	print("¡PUM!")
	p2_sub_state = Phase2SubState.STOMP_RECOVERING # Estado temporal de espera
	velocity = Vector2.ZERO
	
	# Aquí podrías instanciar ondas de choque o hitbox de daño de área
	
	await get_tree().create_timer(1.0).timeout
	if current_state != States.PHASE_2_AIR: return
	
	fly_to_hover_position()

# --- Ataque 2: Bombas ---
func perform_bomb_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	
	print("¡Ataque Bombas!")
	animated_sprite.play("Attack 2")
	await get_tree().create_timer(0.5).timeout
	
	if bomb_scene:
		var bomb = bomb_scene.instantiate()
		bomb.global_position = global_position + Vector2(0, 30)
		get_parent().add_child(bomb)
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	if p2_sub_state == Phase2SubState.LOW_ATTACK:
		animated_sprite.play("Idle") # O volver a animación de vuelo

func fly_to_hover_position():
	is_hovering = false
	is_attacking = true # Sigue bloqueado hasta llegar arriba
	
	await fly_to_height(hover_height)
	
	# --- CORRECCIÓN AQUÍ ---
	is_hovering = true
	is_attacking = false # ¡Liberamos al jefe para que se mueva!
	p2_sub_state = Phase2SubState.LOW_ATTACK # Estado de patrulla activado
	
	# Esperamos un tiempo aleatorio ANTES de iniciar el siguiente ataque.
	# Durante este tiempo, como is_attacking es false, el jefe patrullará.
	var cooldown = randf_range(min_attack_cooldown, max_attack_cooldown)
	await get_tree().create_timer(cooldown).timeout
	
	# Chequeo de seguridad por si cambió de fase mientras esperábamos
	if current_state != States.PHASE_2_AIR: return
	
	# Ahora sí, iniciamos el siguiente ciclo de ataque
	start_attack_loop()

# ========================================================
#                     FASE 3 & DAÑO
# ========================================================
func _process_phase_3(delta):
	# Decrementar timer de la sub-fase actual
	if p3_timer > 0:
		p3_timer -= delta
		if p3_timer <= 0:
			_swap_p3_sub_state()

	match p3_sub_state:
		# --- ESTADO 1: DISPAROS DESDE EL CENTRO (INVULNERABLE) ---
		Phase3SubState.BULLET_HELL:
			velocity = Vector2.ZERO
			move_and_slide()
			
			# Gestión del disparo
			shoot_timer -= delta
			if shoot_timer <= 0:
				shoot_timer = shoot_delay # Reiniciar timer
				
				# Ejecutar el patrón seleccionado
				match current_bullet_pattern:
					BulletPatterns.SPIRAL:
						perform_spiral_pattern(delta)
					BulletPatterns.NOVA:
						perform_nova_pattern()
					BulletPatterns.AIMED:
						perform_aimed_pattern()

		# --- ESTADO 2: MOVIMIENTO ERRÁTICO (VULNERABLE) ---
		Phase3SubState.ERRATIC_CHASE:
			# Si estamos esperando, no hacemos nada de movimiento
			if p3_is_waiting:
				velocity = Vector2.ZERO
				move_and_slide()
				return
			
			# 1. Moverse hacia el punto
			var direction = global_position.direction_to(p3_target_position)
			velocity = direction * erratic_speed
			move_and_slide()
			
			# 2. Restar tiempo de paciencia (para que no se atasque)
			p3_point_timeout -= delta
			
			# 3. CONDICIÓN DE LLEGADA (O Tiempo agotado)
			var distance = global_position.distance_to(p3_target_position)
			if distance < 50.0 or p3_point_timeout <= 0:
				# EN LUGAR DE ELEGIR PUNTO DIRECTAMENTE, LLAMAMOS A LA PAUSA
				_wait_and_reposition()
			
			# Animación
			if velocity.x > 0: animated_sprite.play("Right")
			else: animated_sprite.play("Left")

func _wait_and_reposition():
	p3_is_waiting = true # Bloqueamos el movimiento en _process
	velocity = Vector2.ZERO # Frenado total
	
	# Opcional: Poner animación de Idle o de "Jadeo/Cansancio"
	animated_sprite.play("Idle") 
	
	# Esperamos 1 segundo
	await get_tree().create_timer(1.0).timeout
	
	# Verificación de seguridad (por si murió o cambió fase en ese segundo)
	if current_state != States.PHASE_3_CHAOS or p3_sub_state != Phase3SubState.ERRATIC_CHASE:
		return
		
	# Elegimos nuevo punto y liberamos el bloqueo
	pick_random_erratic_point()
	p3_is_waiting = false

# --- PATRÓN 1: ESPIRAL (Como el que tenías, pero doble) ---
func perform_spiral_pattern(delta):
	# Rotamos el ángulo
	spiral_angle += 5.0 * delta # Ajusta el 5.0 para girar más rápido/lento
	
	# Disparamos 3 brazos de espiral separados por 120 grados
	shoot_bullet_angle(spiral_angle)
	shoot_bullet_angle(spiral_angle + deg_to_rad(120))
	shoot_bullet_angle(spiral_angle + deg_to_rad(240))

# --- PATRÓN 2: NOVA (Anillo explosivo) ---
func perform_nova_pattern():
	var bullets_amount = 12 # Cantidad de balas en el anillo
	var angle_step = TAU / bullets_amount # TAU es 2*PI (360 grados)
	
	# Creamos un anillo completo
	for i in range(bullets_amount):
		var angle = i * angle_step
		# Opcional: Sumar un pequeño offset aleatorio para que los huecos no estén siempre igual
		# angle += randf_range(-0.1, 0.1) 
		shoot_bullet_angle(angle)

# --- PATRÓN 3: AIMED (Escopeta al jugador) ---
func perform_aimed_pattern():
	if not player: return
	
	# Calcular ángulo hacia el jugador
	var dir_to_player = global_position.direction_to(player.global_position)
	var base_angle = dir_to_player.angle()
	
	# Disparar 1 bala central
	shoot_bullet_angle(base_angle)
	
	# Disparar 2 balas a los costados (Spread de 15 grados)
	shoot_bullet_angle(base_angle + deg_to_rad(15))
	shoot_bullet_angle(base_angle - deg_to_rad(15))

# Función genérica para disparar una bala en un ángulo específico
func shoot_bullet_angle(angle_rad: float):
	if not bullet_scene: return
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	if bullet.has_method("set_shooter"): bullet.set_shooter(self)
	
	# Vector dirección a partir del ángulo
	var dir = Vector2(cos(angle_rad), sin(angle_rad))
	
	if bullet.has_method("set_direction"): bullet.set_direction(dir)
	if bullet.has_method("set_mask"): bullet.set_mask(2)
	
	get_parent().add_child(bullet)
	if bullet.has_meta("delete_mask"): bullet.delete_mask(1)

# --- INICIO DE SUB-FASES ---

func start_p3_bullet_hell():
	print("Fase 3: ¡BULLET HELL! (Invulnerable)")
	p3_sub_state = Phase3SubState.BULLET_HELL
	is_invulnerable = true # ¡ESCUDO ACTIVADO!
	
	# Subir al centro protegido
	await fly_to_position(center_position)
	# --- ELECCIÓN DE PATRÓN ---
	# Elegimos uno de los 3 patrones al azar
	var random_pick = randi() % 4
	print("RANDOM: ", random_pick)
	current_bullet_pattern = random_pick as BulletPatterns
	
	# Configuración específica para cada patrón
	match current_bullet_pattern:
		BulletPatterns.SPIRAL:
			print("Patrón: ESPIRAL")
			shoot_delay = 0.1 # Muy rápido
		BulletPatterns.NOVA:
			print("Patrón: NOVA (Anillos)")
			shoot_delay = 0.8 # Más lento, son muchas balas
		BulletPatterns.AIMED:
			print("Patrón: DIRIGIDO")
			shoot_delay = 0.8 # Medio
			
	p3_timer = chaos_duration_shooting
	shoot_timer = 0.0 # Reset del timer de disparo

func start_p3_erratic_chase():
	print("Fase 3: ¡PERSECUCIÓN! (Vulnerable)")
	p3_sub_state = Phase3SubState.ERRATIC_CHASE
	is_invulnerable = false 
	p3_is_waiting = false # <--- RESETEAR AQUÍ
	
	# Apagamos colisión con paredes (Capa 1)
	set_collision_mask_value(1, false) 
	
	pick_random_erratic_point()
	p3_timer = chaos_duration_chasing

# --- UTILIDADES FASE 3 ---

func _swap_p3_sub_state():
	if current_state != States.PHASE_3_CHAOS: return
	
	if p3_sub_state == Phase3SubState.BULLET_HELL:
		start_p3_erratic_chase()
	else:
		start_p3_bullet_hell()

func pick_random_erratic_point():
	# Generamos una X aleatoria dentro de los límites del rectángulo
	var random_x = randf_range(p3_area_min.x, p3_area_max.x)
	
	# Generamos una Y aleatoria dentro de los límites del rectángulo
	var random_y = randf_range(p3_area_min.y, p3_area_max.y)
	
	p3_target_position = Vector2(random_x, random_y)
	
	# Mantenemos el timer de paciencia por si acaso se traba con el player
	p3_point_timeout = 2.0

func shoot_spiral_bullet(angle_rad: float):
	if not bullet_scene: return
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	if bullet.has_method("set_shooter"): bullet.set_shooter(self)
	
	# Calculamos vector de dirección basado en el ángulo
	var dir = Vector2(cos(angle_rad), sin(angle_rad))
	
	if bullet.has_method("set_direction"): bullet.set_direction(dir)
	if bullet.has_method("set_mask"): bullet.set_mask(2)
	
	get_parent().add_child(bullet)
	if bullet.has_meta("delete_mask"): bullet.delete_mask(1)

# Función de vuelo genérica (Versión mejorada de fly_to_height para usar Vector2)
func fly_to_position(target: Vector2):
	set_physics_process(false)
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	current_tween.tween_property(self, "position", target, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	await current_tween.finished
	set_physics_process(true)

# ========================================================
#                     DAÑO
# ========================================================

func take_damage():
	if not is_alive or is_invulnerable: return
	
	current_health -= 10
	emit_signal("add_points", points)
	emit_signal("health_changed", current_health)
	
	# Visual Feedback
	var tw = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	if current_health <= 0:
		die()
	else:
		check_for_phase_change()

func check_for_phase_change():
	var pct = float(current_health) / float(max_health)
	
	if pct < 0.33 and current_state != States.PHASE_3_CHAOS:
		change_state(States.PHASE_3_CHAOS)
	elif pct < 0.66 and current_state == States.PHASE_1_GROUND:
		change_state(States.PHASE_2_AIR)

func die():
	is_alive = false
	set_collision_mask_value(1, true)
	print("Jefe Derrotado")
	animated_sprite.play("Death")
	emit_signal("boss_die")
	
	cleanup_timers()
	if current_tween: current_tween.kill()
	
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Dar un tiempo para ver la animación antes de desaparecer
	await get_tree().create_timer(2.0).timeout
	queue_free()
