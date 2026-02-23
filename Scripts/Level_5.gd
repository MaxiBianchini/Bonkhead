extends Node2D

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN DE ESCENA)
# ==============================================================================
@export var final_boss: CharacterBody2D


# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
# --- Plataformas y Peligros ---
@onready var platforms_1: Node2D = $Platform_Fase1
@onready var platforms_2: Node2D = $Platform_Fase2
@onready var molten_rock: TileMapLayer = $"TileMaps/Molten Rock 2"
@onready var dead_area: Area2D = $Dead_Area2

# --- Entorno y Control de Sala ---
@onready var tilemap = $TileMaps
@onready var gates: TileMapLayer = $TileMaps/Gates
@onready var gates_trigger: Area2D = $GatesArea

# --- Interfaz y Cámara ---
@onready var warning_label = $Signpost 
@onready var camera = $Camera2D 

@onready var audio_stream: AudioStreamPlayer = $AudioStreamPlayer

# ==============================================================================
# VARIABLES DE ESTADO Y VISUALES
# ==============================================================================
var blink_tween: Tween

var normal_color = Color(1, 1, 1, 1)
var danger_color = Color(1, 0.5, 0.5, 1)


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicializa el estado de la sala antes de que comience el combate
func _ready() -> void:
	if final_boss:
		final_boss.toggle_hazards.connect(_on_boss_toggle_hazards)
		final_boss.boss_die.connect(_on_boss_die)
		
	set_molten_rock_active(false)
	
	platforms_2.visible = false
	platforms_2.modulate.a = 0.0
	_set_platform_collision(false)
	
	open_gates()


# ==============================================================================
# GESTIÓN DE LA SALA Y CINEMÁTICAS
# ==============================================================================

# Detecta cuando el jugador entra a la arena
func _on_gates_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if gates.visible == false: 
			start_boss_cinematic(body)

# Orquesta la cinemática introductoria del combate
func start_boss_cinematic(player_node):
	close_gates()
	
	if "is_cutscene" in player_node:
		player_node.is_cutscene = true
	
	while not player_node.is_on_floor():
		await get_tree().process_frame
	
	player_node.velocity = Vector2.ZERO
	if player_node.has_node("AnimatedSprite2D"):
		player_node.get_node("AnimatedSprite2D").play("SIdle with Gun")
	
	await get_tree().create_timer(2.5).timeout
	
	if "is_cutscene" in player_node:
		player_node.is_cutscene = false
		
	if final_boss:
		await final_boss.play_intro_sequence()
	
	await get_tree().create_timer(1.0).timeout
	
	player_node.set_physics_process(true)
	
	if final_boss:
		final_boss.start_battle()
		audio_stream.play()

# Cierra la puerta principal de la arena
func close_gates():
	gates.enabled = true 
	gates.visible = true
	gates_trigger.set_deferred("monitoring", false)

# Abre la puerta principal de la arena
func open_gates():
	gates.enabled = false
	gates.visible = false


# ==============================================================================
# RECEPTORES DE SEÑALES DEL JEFE
# ==============================================================================

# Responde a los cambios de fase del jefe para activar/desactivar peligros
func _on_boss_toggle_hazards(is_active: bool) -> void:
	if is_active:
		if warning_label:
			warning_label.visible = true
			warning_label.modulate.a = 1.0
			
		if tilemap:
			if blink_tween: blink_tween.kill() 
			blink_tween = create_tween()
			
			blink_tween.set_loops(4)
			
			blink_tween.tween_property(tilemap, "modulate", danger_color, 0.25)
			blink_tween.tween_property(tilemap, "modulate", normal_color, 0.25)
		
		await get_tree().create_timer(1.5).timeout
		
		blink_and_show_platforms()
		
		await get_tree().create_timer(1.0).timeout
		
		set_molten_rock_active(true)
		
		if warning_label:
			warning_label.visible = false
	
	else:
		if warning_label: warning_label.visible = false
		if blink_tween: blink_tween.kill()
		
		if tilemap:
			var reset_tween = create_tween()
			reset_tween.tween_property(tilemap, "modulate", normal_color, 0.5)
			
		blink_and_hide_platforms()
		set_molten_rock_active(false)

# Responde a la muerte del jefe final desactivando peligros y abriendo la sala
func _on_boss_die():
	set_molten_rock_active(false)
	open_gates()


# ==============================================================================
# MANEJO DE PELIGROS (PLATAFORMAS Y LAVA)
# ==============================================================================

# Revela las plataformas gradualmente mediante un efecto de parpadeo
func blink_and_show_platforms() -> void:
	var platforms_container = platforms_2
	platforms_container.visible = true
	var tween = create_tween()
	
	for i in 6:
		tween.tween_property(platforms_container, "modulate:a", 1.0, 0.1)
		tween.tween_property(platforms_container, "modulate:a", 0.0, 0.1)
	
	tween.tween_property(platforms_container, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	_set_platform_collision(true)
	await get_tree().create_timer(2.0).timeout

# Oculta las plataformas gradualmente
func blink_and_hide_platforms() -> void:
	var platforms_container = platforms_2
	var tween = create_tween()
	
	for i in 5:
		tween.tween_property(platforms_container, "modulate:a", 0.2, 0.2) 
		tween.tween_property(platforms_container, "modulate:a", 1.0, 0.2)
	
	tween.tween_property(platforms_container, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	platforms_container.visible = false
	_set_platform_collision(false)

# Activa o desactiva las colisiones de las plataformas hijas
func _set_platform_collision(is_active: bool) -> void:
	var platforms_container = platforms_2
	
	for platform in platforms_container.get_children():
		if platform.has_node("CollisionShape2D"):
			var shape = platform.get_node("CollisionShape2D")
			shape.set_deferred("disabled", not is_active)

# Controla la visibilidad y colisión del área de roca fundida (lava)
func set_molten_rock_active(is_active: bool) -> void:
	molten_rock.visible = is_active
	if is_active:
		var tween = create_tween()
		tween.tween_property(molten_rock, "modulate:a", 1.0, 0.5).from(0.0)
	dead_area.set_deferred("monitoring", is_active)
	dead_area.set_deferred("monitorable", is_active)
	
	if is_active:
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		var bodies = dead_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				if body.has_method("_on_area_entered"):
					body._on_area_entered(dead_area)
