extends CharacterBody2D

# --- Señales para comunicarse con el Nivel ---
signal health_changed(new_health) # Para la barra de vida de la UI
signal phase_changed(new_phase) # Para avisarle al Nivel (activar plataformas, romper suelo)

# --- Configuración del Jefe ---
@export var max_health: int = 300
var current_health: int

# Velocidades para las diferentes fases (ajustables en el inspector)
@export var ground_speed: float = 100.0
@export var air_speed: float = 150.0

# --- Referencias a Nodos Hijos ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var claw = $MechanicalClaw/AnimatedSprite2D # Descomenta cuando agregues la garra

# --- Variables para Fase 1 (Embestida) ---
var player: Node2D = null
var can_attack: bool = true
var is_dashing: bool = false
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.7
var dash_direction: Vector2 = Vector2.ZERO

# --- Variables Fase 2 (Aérea) ---
@export var hover_height: float = 1540.0 # Altura Y a la que flotará (ajusta según tu nivel)
@export var air_patrol_speed: float = 150.0
@export var stomp_speed: float = 600.0 # Velocidad de caída al aplastar
@export var bomb_scene: PackedScene # Aquí arrastrarás tu escena "Bomb.tscn" cuando la crees

var is_hovering: bool = false # Para saber si ya llegó a la altura
var is_attacking: bool = false # Para no moverse mientras ataca
var attack_cooldown_timer: Timer = null

# --- Máquina de Estados ---
enum States { PHASE_1_GROUND, PHASE_2_AIR, PHASE_3_CHAOS }
var current_state: States = States.PHASE_1_GROUND

signal add_points
var points: int = 20
var is_alive: bool = true

func _ready():
	current_health = max_health
	# Buscamos al jugador por su grupo (asegúrate que tu Player tenga el grupo "Player")
	player = get_tree().get_first_node_in_group("Player")
	
	# El jefe empieza oculto y "cerebralmente muerto"
	visible = false
	set_physics_process(false) # Esto desactiva el _physics_process (la máquina de estados)
	$CollisionShape2D.set_deferred("disabled", true) # Sin colisión al inicio
	
	# Iniciar en la Fase 1
	#change_state(States.PHASE_1_GROUND)

func _physics_process(delta) -> void:
	# El comportamiento exacto lo definirá el estado actual
	match current_state:
		States.PHASE_1_GROUND:
			_process_phase_1(delta)
		States.PHASE_2_AIR:
			_process_phase_2(delta)
		States.PHASE_3_CHAOS:
			_process_phase_3(delta)

# --- Función para cambiar de estado de forma ordenada ---
func change_state(new_state: States):
	current_state = new_state
	
	# Lógica de entrada a cada estado (solo se ejecuta una vez al cambiar)
	match current_state:
		States.PHASE_1_GROUND:
			print("Entrando a Fase 1: Tierra")
			# Aquí podrías resetear la posición del jefe o reproducir una animación de inicio
		
		States.PHASE_2_AIR:
			print("Entrando a Fase 2: Aire")
			emit_signal("phase_changed", 2)
			
			# Configurar un Timer para los ataques (creado por código para no ensuciar la escena)
			attack_cooldown_timer = Timer.new()
			attack_cooldown_timer.wait_time = 1.5 # Ataca cada 3 segundos
			attack_cooldown_timer.one_shot = true
			attack_cooldown_timer.timeout.connect(_on_attack_timer_timeout)
			add_child(attack_cooldown_timer)
			
			# INICIAR TRANSICIÓN: Subir al cielo
			fly_to_hover_position()
			
		States.PHASE_3_CHAOS:
			print("Entrando a Fase 3: Caos")
			# Avisamos al Nivel para que rompa el suelo
			emit_signal("phase_changed", 3)

# --- Funciones de procesamiento de cada fase (MARCADORES DE POSICIÓN) ---
func _process_phase_1(delta) -> void:
	# Si no hay jugador o estamos cambiando de fase, no hacemos nada
	if not player or current_health <= 0: return

	# Si está en medio del Dash, solo aplicamos movimiento
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		
		# Detectar choque con pared (opcional, para detener el dash antes)
		if is_on_wall():
			is_dashing = false
			# Aquí podrías poner la animación de "Attack" (Aplastar) contra la pared
			animated_sprite.play("Attack") 
		return

	# --- LÓGICA DE PERSECUCIÓN / PREPARACIÓN ---
	
	# 1. Mirar al jugador
	var direction_to_player = global_position.direction_to(player.global_position)
	if direction_to_player.x > 0:
		animated_sprite.play("Right") # O flip_h = false
	else:
		animated_sprite.play("Left") # O flip_h = true

	# 2. Decidir atacar
	if can_attack:
		start_dash_attack()
	else:
		# Movimiento lento de "acecho" mientras descansa
		velocity.x = direction_to_player.x * 50 # Velocidad lenta
		move_and_slide()

func _process_phase_2(_delta):
	# Si está atacando o todavía subiendo, no calculamos movimiento de patrulla
	if is_attacking or not is_hovering: 
		move_and_slide() # Necesario si estamos en medio del ataque de aplastar
		return

	# --- PATRULLA AÉREA ---
	# Moverse hacia el jugador (o de lado a lado)
	# Aquí hacemos un movimiento simple de persecución suave en X
	var dir_x = 0
	if player:
		# Si el jugador está a la derecha, vamos a la derecha
		dir_x = 1 if player.global_position.x > global_position.x else -1
		
		# Animación
		if dir_x > 0: animated_sprite.play("Right")
		else: animated_sprite.play("Left")
	
	velocity.x = dir_x * air_patrol_speed
	velocity.y = 0 # Mantener altura
	
	move_and_slide()
	
	# Iniciar el timer de ataque si no está corriendo
	if attack_cooldown_timer.is_stopped():
		attack_cooldown_timer.start()

func _process_phase_3(delta) -> void:
	# Lógica temporal para probar
	# Ir al centro y atacar
	pass

# --- Función para recibir daño ---
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
		print("Jefe derrotado")
		velocity.x = 0
		animated_sprite.play("Death")
		
	# Desactivar colisiones
		$CollisionShape2D.set_deferred("disabled", true)
		# Aquí iría la lógica de fin de nivel
		
		#death_sound.play()
		#await death_sound.finished
		queue_free()
		
		#can_shoot = false
		#if shoot_timer.time_left > 0:
			#shoot_timer.start(shoot_timer.time_left + 1.0)
		#else:
			#shoot_timer.start(1.0)
	
	# Verificar cambio de fase
	check_for_phase_change()


func start_dash_attack() -> void:
	can_attack = false
	
	# 1. PREPARACIÓN (Telegrafía)
	# Frenamos al jefe
	velocity = Vector2.ZERO
	# Aquí podrías poner un color rojo de advertencia o animación de "cargar"
	animated_sprite.modulate = Color(1, 0.5, 0.5) # Rojo aviso
	print("Jefe: Preparando embestida...")
	
	# Esperamos 1 segundo para que el jugador reaccione
	await get_tree().create_timer(1.0).timeout
	
	# Revisamos si seguimos en Fase 1 (por si le bajaron la vida mientras cargaba)
	if current_state != States.PHASE_1_GROUND: return
	
	# 2. EJECUCIÓN (Dash)
	animated_sprite.modulate = Color(1, 1, 1) # Color normal
	is_dashing = true
	
	# Calculamos dirección hacia donde ESTÁ el jugador AHORA
	# (Solo horizontal para que no vuele)
	var dir = 1 if player.global_position.x > global_position.x else -1
	dash_direction = Vector2(dir, 0)
	
	# El dash dura un tiempo fijo (ej: 0.8 segundos)
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	velocity = Vector2.ZERO
	
	# 3. ENFRIAMIENTO (Cooldown)
	# El jefe se queda quieto o lento un rato, vulnerable
	print("Jefe: Descansando...")
	await get_tree().create_timer(2.0).timeout
	
	can_attack = true

func play_intro_sequence():
	# 1. Parpadeo Visual (Glitch)
	visible = true
	var tween = create_tween()
	
	# Parpadeo rápido (6 veces)
	for i in 6:
		tween.tween_property(self, "modulate:a", 1.0, 0.1) # Visible
		tween.tween_property(self, "modulate:a", 0.0, 0.1) # Invisible
	
	# Aparecer totalmente
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Esperamos a que termine el show de luces
	await tween.finished
	
	# Opcional: Aquí podrías hacer un "Rugido" o animación de pose
	# animated_sprite.play("Roar")
	# await get_tree().create_timer(1.0).timeout
	

# --- TRANSICIÓN INICIAL ---
func fly_to_hover_position():
	is_hovering = false
	is_attacking = true # Bloqueamos ataques mientras sube
	
	# Usamos un Tween para subir suavemente hasta la altura deseada
	var tween = create_tween()
	# "position:y" se moverá hasta hover_height en 2 segundos
	tween.tween_property(self, "position:y", hover_height, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	is_hovering = true
	is_attacking = false # Ya puede empezar a moverse y atacar
	print("Jefe: Altura alcanzada, iniciando patrulla.")

# --- SELECCIÓN DE ATAQUE ---
func _on_attack_timer_timeout():
	if current_state != States.PHASE_2_AIR: return
	
	if not player: return
	
	# Decisión basada en la posición del jugador
	# Calculamos la distancia horizontal
	var distance_x = abs(global_position.x - player.global_position.x)
	
	# Si el jugador está cerca (debajo) -> APLASTAR (Attack 1)
	# Si está lejos -> BOMBAS (Attack 2)
	if distance_x < 100: # 100 pixeles de margen
		perform_stomp_attack()
	else:
		perform_bomb_attack()

# --- ATAQUE 1: APLASTAR ---
func perform_stomp_attack():
	is_attacking = true
	velocity = Vector2.ZERO # Frenar
	
	# 1. Telegrafía (Animación de caer)
	print("Jefe: ¡Voy a aplastar!")
	animated_sprite.play("Attack") # Tu animación de bola/caída
	
	# Pequeña pausa arriba para que el jugador se quite
	await get_tree().create_timer(0.5).timeout
	
	# 2. Caída Violenta
	velocity.y = stomp_speed
	
	# Esperamos a tocar el suelo
	while not is_on_floor():
		move_and_slide()
		await get_tree().physics_frame # Esperar al siguiente frame
		# Seguridad: Si cambiamos de fase mientras cae, salir
		if current_state != States.PHASE_2_AIR: return 
	
	# 3. Impacto (Aquí podrías instanciar ondas de choque o temblor de cámara)
	print("Jefe: ¡PUM!")
	# animated_sprite.play("Land") # Si tuvieras animación de aterrizaje
	
	await get_tree().create_timer(1.0).timeout # Quedarse en el suelo un momento
	
	# 4. Volver a subir
	fly_to_hover_position() # Reutilizamos la función de subir

# --- ATAQUE 2: BOMBAS ---
func perform_bomb_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	
	print("Jefe: ¡Bombas fuera!")
	animated_sprite.play("Attack 2") # Tu animación de abrir boca/garra
	
	# Esperar al momento justo de la animación para soltar la bomba
	# (Puedes ajustar este tiempo o usar una señal de animation_finished)
	await get_tree().create_timer(0.5).timeout
	
	spawn_bomb()
	
	await get_tree().create_timer(0.5).timeout # Terminar animación
	
	is_attacking = false # Volver a patrullar
	animated_sprite.play("Idle")

func spawn_bomb():
	if bomb_scene:
		var bomb = bomb_scene.instantiate()
		bomb.global_position = global_position # Sale del centro del jefe
		get_parent().add_child(bomb) # Añadir al nivel, no al jefe
	else:
		print("Falta asignar la Bomb Scene en el Inspector")

func start_battle():
	print("Jefe: ¡Hora de luchar!")
	# Activamos cerebro y cuerpo
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Iniciamos la Fase 1
	change_state(States.PHASE_1_GROUND)

func check_for_phase_change():
	var health_percentage = float(current_health) / float(max_health)
	print("VIDA %: ",health_percentage)
	
	if health_percentage > 0.33 and health_percentage <= 0.66 and current_state == States.PHASE_1_GROUND:
		change_state(States.PHASE_2_AIR)
	elif health_percentage <= 0.33 and current_state == States.PHASE_2_AIR:
		change_state(States.PHASE_3_CHAOS)
	
