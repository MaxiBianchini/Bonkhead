extends RigidBody2D

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN VISUAL)
# ==============================================================================
@export_group("Texturas por Nivel")
@export var texturas_sprite_1: Array[Texture2D]
@export var texturas_sprite_2: Array[Texture2D]
@export var texturas_sprite_3: Array[Texture2D]


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
# --- Temporizadores ---
@onready var collapse_timer: Timer = $Timer2
@onready var reset_timer: Timer = $Timer

# --- Elementos Visuales ---
@onready var sprite_1: Sprite2D = $Sprite2D
@onready var sprite_2: Sprite2D = $Sprite2D2
@onready var sprite_3: Sprite2D = $Sprite2D3


# ==============================================================================
# VARIABLES DE ESTADO Y SISTEMA
# ==============================================================================
var player_on_platform: bool = false
var falling: bool = false
var initial_position: Vector2
var needs_reset: bool = false


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT Y CONFIGURACIÓN
# ==============================================================================

# Inicialización de la plataforma al cargar la escena
func _ready() -> void:
	# Guarda la posición original para poder regresar a ella tras la caída
	initial_position = position
	
	# Congela las físicas del RigidBody para que se mantenga flotando en el aire
	freeze = true
	
	# Adapta la textura de la plataforma al nivel actual
	configurar_estetica()

# Ajusta los sprites activos y sus texturas basándose en el Singleton SceneManager
func configurar_estetica() -> void:
	var nivel_index = SceneManager.current_level - 1
	
	# Configuración Sprite 1
	if nivel_index < texturas_sprite_1.size() and texturas_sprite_1[nivel_index]:
		sprite_1.texture = texturas_sprite_1[nivel_index]
		sprite_1.visible = true
	else:
		sprite_1.visible = false
		
	# Configuración Sprite 2
	if nivel_index < texturas_sprite_2.size() and texturas_sprite_2[nivel_index]:
		sprite_2.texture = texturas_sprite_2[nivel_index]
		sprite_2.visible = true
	else:
		sprite_2.visible = false
		
	# Configuración Sprite 3
	if nivel_index < texturas_sprite_3.size() and texturas_sprite_3[nivel_index]:
		sprite_3.texture = texturas_sprite_3[nivel_index]
		sprite_3.visible = true
	else:
		sprite_3.visible = false


# ==============================================================================
# LÓGICA DE MECÁNICAS (DETECCIÓN, CAÍDA Y REINICIO)
# ==============================================================================

# Se activa cuando una entidad entra en contacto con la plataforma
func _on_body_entered(body: Node) -> void:
	# Cláusula de validación: Solo el jugador puede activar la caída
	if body.is_in_group("Player") and not falling:
		player_on_platform = true
		
		# Inicia la cuenta regresiva para colapsar si no se ha iniciado ya
		if collapse_timer.is_stopped():
			collapse_timer.start()

# Descongela la plataforma, permitiendo que la gravedad actúe sobre ella
func start_falling() -> void:
	if player_on_platform:
		freeze = false
		falling = true
		
		# Inicia el temporizador para devolver la plataforma a su posición original
		reset_timer.start()

# Restaura la plataforma a su estado original (flotando en su punto de inicio)
func reset_platform() -> void:
	needs_reset = true
	falling = false
	player_on_platform = false

# Esta función es nativa de Godot, se ejecuta en cada frame físico de forma segura
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if needs_reset:
		# Aquí modificamos el "state" (el estado físico real) en lugar de las variables directas
		state.transform.origin = initial_position # Esto equivale a cambiar la "position"
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		
		# Cambiamos propiedades del nodo de forma diferida (segura)
		set_deferred("freeze", true) 
		
		# Bajamos la bandera para que no se reinicie infinitamente
		needs_reset = false
