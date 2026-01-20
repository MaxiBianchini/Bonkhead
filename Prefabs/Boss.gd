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
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.8
var dash_direction: Vector2 = Vector2.ZERO

# --- Máquina de Estados ---
enum States { PHASE_1_GROUND, PHASE_2_AIR, PHASE_3_CHAOS }
var current_state: States = States.PHASE_1_GROUND

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

func _physics_process(delta):
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
			# Avisamos al Nivel para que active las plataformas
			emit_signal("phase_changed", 2)
			# Aquí harías visible la garra: claw.visible = true
			
		States.PHASE_3_CHAOS:
			print("Entrando a Fase 3: Caos")
			# Avisamos al Nivel para que rompa el suelo
			emit_signal("phase_changed", 3)

# --- Funciones de procesamiento de cada fase (MARCADORES DE POSICIÓN) ---
func _process_phase_1(delta):
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

func _process_phase_2(delta):
	# Lógica temporal para probar
	# Volar y perseguir al jugador
	pass

func _process_phase_3(delta):
	# Lógica temporal para probar
	# Ir al centro y atacar
	pass

# --- Función para recibir daño ---
func take_damage():
	current_health -= 10
	emit_signal("health_changed", current_health)
	
	# Reproducir animación de herido
	if animated_sprite.animation != "Death":
		animated_sprite.play("Hurt")
	
	# Verificar muerte
	if current_health <= 0:
		die()
		return

	# Verificar cambio de fase
	check_for_phase_change()

func start_dash_attack():
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
	
func start_battle():
	print("Jefe: ¡Hora de luchar!")
	# Activamos cerebro y cuerpo
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Iniciamos la Fase 1
	change_state(States.PHASE_1_GROUND)

func check_for_phase_change():
	var health_percentage = float(current_health) / float(max_health)
	
	if health_percentage < 0.33 and current_state != States.PHASE_3_CHAOS:
		change_state(States.PHASE_3_CHAOS)
	elif health_percentage < 0.66 and current_state != States.PHASE_1_GROUND and current_state != States.PHASE_3_CHAOS:
		# Esta condición es para evitar volver a Fase 1 si te curas
		if current_state == States.PHASE_1_GROUND: # Solo cambia si vienes de la 1
			change_state(States.PHASE_2_AIR)

func die():
	print("Jefe derrotado")
	animated_sprite.play("Death")
	# Desactivar colisiones
	$CollisionShape2D.set_deferred("disabled", true)
	# Aquí iría la lógica de fin de nivel
