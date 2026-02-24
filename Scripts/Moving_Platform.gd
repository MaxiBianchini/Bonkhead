extends AnimatableBody2D

# ==============================================================================
# PROPIEDADES EXPORTADAS
# ==============================================================================
@export var speed: float = 100.0

@export_group("Texturas por Nivel")
@export var texturas_sprite_1: Array[Texture2D]
@export var texturas_sprite_2: Array[Texture2D]
@export var texturas_sprite_3: Array[Texture2D]


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var sprite_1: Sprite2D = $Sprite2D
@onready var sprite_2: Sprite2D = $Sprite2D2
@onready var sprite_3: Sprite2D = $Sprite2D3


# ==============================================================================
# VARIABLES DE TRAYECTORIA
# ==============================================================================
var start_position: Vector2
var target_position: Vector2


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

func _ready() -> void:
	configurar_estetica()
	
	start_position = global_position
	var marker = find_child("Marker2D", true, false)
	
	if marker:
		target_position = marker.global_position
		# En lugar de usar _physics_process, iniciamos el Tween una sola vez
		iniciar_movimiento_tween()
	else:
		push_error("No se encontró un Marker2D dentro de la plataforma.")


# ==============================================================================
# LÓGICA DE MOVIMIENTO (TWEEN)
# ==============================================================================

func iniciar_movimiento_tween() -> void:
	# 1. Calculamos la distancia total entre el punto A y el punto B
	var distance = start_position.distance_to(target_position)
	
	# 2. Calculamos la duración exacta usando la fórmula: Tiempo = Distancia / Velocidad
	var duration = distance / speed
	
	var tween = create_tween()
	
	# 3. ¡CRÍTICO! Le decimos al Tween que se sincronice con los frames físicos.
	# Esto asegura que la plataforma mueva al jugador de forma perfecta y sin tirones.
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# 4. Le indicamos que este ciclo debe repetirse infinitamente
	tween.set_loops()
	
	# 5. Programamos el viaje de IDA
	tween.tween_property(self, "global_position", target_position, duration).from(start_position)
	
	# 6. Programamos el viaje de VUELTA
	tween.tween_property(self, "global_position", start_position, duration)


# ==============================================================================
# GESTIÓN VISUAL Y ESTÉTICA
# ==============================================================================

func configurar_estetica() -> void:
	var nivel_index = SceneManager.current_level - 1
	
	# --- Configuración del Sprite 1 ---
	if nivel_index < texturas_sprite_1.size() and texturas_sprite_1[nivel_index]:
		sprite_1.texture = texturas_sprite_1[nivel_index]
		sprite_1.visible = true
	else:
		sprite_1.visible = false
		
	# --- Configuración del Sprite 2 ---
	if nivel_index < texturas_sprite_2.size() and texturas_sprite_2[nivel_index]:
		sprite_2.texture = texturas_sprite_2[nivel_index]
		sprite_2.visible = true
	else:
		sprite_2.visible = false
		
	# --- Configuración del Sprite 3 ---
	if nivel_index < texturas_sprite_3.size() and texturas_sprite_3[nivel_index]:
		sprite_3.texture = texturas_sprite_3[nivel_index]
		sprite_3.visible = true
	else:
		sprite_3.visible = false
