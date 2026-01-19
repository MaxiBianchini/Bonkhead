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

# --- Máquina de Estados ---
enum States { PHASE_1_GROUND, PHASE_2_AIR, PHASE_3_CHAOS }
var current_state: States = States.PHASE_1_GROUND

func _ready():
	current_health = max_health
	# Iniciar en la Fase 1
	change_state(States.PHASE_1_GROUND)

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
	# Lógica temporal para probar
	# Moverse de izquierda a derecha
	#velocity.x = ground_speed
	animated_sprite.play("Idle")
	#claw.play("Claw_Idle")
	move_and_slide()
	pass

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
