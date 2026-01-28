extends Node2D

# --- Referencias ---
@onready var platforms_1: Node2D = $Platform_Fase1
@onready var platforms_2: Node2D = $Platform_Fase2
@onready var molten_rock: TileMapLayer = $"TileMaps/Molten Rock 2"
@onready var dead_area: Area2D = $Dead_Area2
@onready var gates: TileMapLayer = $TileMaps/Gates
@onready var gates_trigger: Area2D = $GatesArea
@export var final_boss: CharacterBody2D

@onready var tilemap = $TileMaps # (O como se llame tu nodo padre del escenario)
@onready var warning_label = $Signpost # Ajusta la ruta a tu UI
@onready var camera = $Camera2D # Si tienes acceso a la cámara para vibrar

# Asegúrate de tener esta variable definida al principio del script
var blink_tween: Tween

# Color normal (Blanco = sin tinte)
var normal_color = Color(1, 1, 1, 1)
# Color de Alerta (Rojo Intenso)
var danger_color = Color(1, 0.5, 0.5, 1)

func _ready() -> void:
	
	# 2. CONEXIÓN DE SEÑALES DEL JEFE
	if final_boss:
		# Conectamos la nueva señal
		final_boss.toggle_hazards.connect(_on_boss_toggle_hazards)
		final_boss.boss_die.connect(_on_boss_die)
		
	else:
		print("ERROR: ¡No has asignado el Final Boss en el Inspector del Nivel 5!")
	
	# Estado inicial
	set_molten_rock_active(false)
	
	# Aseguramos que las plataformas de la fase 2 y 3 arranquen invisibles y sin colisión
	platforms_2.visible = false
	platforms_2.modulate.a = 0.0
	_set_platform_collision(false)
	
	open_gates()

# --- LÓGICA DE APARICIÓN (Blink In) ---
func blink_and_show_platforms() -> void:
	var platforms_container = platforms_2
	platforms_container.visible = true
	var tween = create_tween()
	
	# Hacemos que parpadee 6 veces rápido (efecto glitch/entrada)
	for i in 6:
		tween.tween_property(platforms_container, "modulate:a", 1.0, 0.1) # Visible
		tween.tween_property(platforms_container, "modulate:a", 0.0, 0.1) # Invisible
	
	# Paso final: Se vuelve totalmente visible
	tween.tween_property(platforms_container, "modulate:a", 1.0, 0.2)
	
	# Esperamos a que termine la animación visual para activar la física
	await tween.finished
	_set_platform_collision(true)
	await get_tree().create_timer(2.0).timeout
	#set_molten_rock_active(true)

# --- LÓGICA DE DESAPARICIÓN (Blink Out) ---
func blink_and_hide_platforms() -> void:
	var platforms_container = platforms_2
	var tween = create_tween()
	
	# Parpadeo de advertencia (más lento para que el jugador se prepare)
	# Nota: Mantenemos la colisión activa DURANTE el parpadeo para no tirar al jugador injustamente
	for i in 5:
		tween.tween_property(platforms_container, "modulate:a", 0.2, 0.2) # Semitransparente
		tween.tween_property(platforms_container, "modulate:a", 1.0, 0.2) # Visible
	
	# Paso final: Desvanecer por completo
	tween.tween_property(platforms_container, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	platforms_container.visible = false
	_set_platform_collision(false)
	set_molten_rock_active(false)

# --- FUNCIÓN AUXILIAR DE FÍSICA ---
func _set_platform_collision(is_active: bool) -> void:
	var platforms_container = platforms_2
	
	for platform in platforms_container.get_children():
		if platform.has_node("CollisionShape2D"):
			var shape = platform.get_node("CollisionShape2D")
			# Si is_active es true -> disabled es false
			shape.set_deferred("disabled", not is_active)

# --- (RESTO DEL CÓDIGO DE LAVA Y PUERTAS IGUAL QUE ANTES) ---
func set_molten_rock_active(is_active: bool) -> void:
	molten_rock.visible = is_active
	if is_active:
		var tween = create_tween()
		tween.tween_property(molten_rock, "modulate:a", 1.0, 0.5).from(0.0)
	dead_area.set_deferred("monitoring", is_active)
	dead_area.set_deferred("monitorable", is_active)
	
	# --- VERIFICACIÓN MANUAL ---
	if is_active:
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		var bodies = dead_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				print("Detectado jugador dentro de la lava al activarse")
				
				# Forzar la llamada a SU función de señal manualmente
				if body.has_method("_on_area_entered"):
					body._on_area_entered(dead_area)

func _on_gates_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Solo activamos la secuencia si las puertas estaban abiertas (para que no pase dos veces)
		if gates.visible == false: 
			start_boss_cinematic(body)

func start_boss_cinematic(player_node):
	print("--- INICIANDO CINEMÁTICA DEL JEFE ---")
	
	# CERRAR PUERTAS
	close_gates()
	
	# QUITAR EL CONTROL PERO DEJAMOS LA GRAVEDAD
	# Verificar si el script del player tiene la variable que creamos
	if "is_cutscene" in player_node:
		player_node.is_cutscene = true
	
	# ESPERAR A QUE CAIGA AL SUELO
	# Usamos un bucle que revisa en cada frame si ya tocó el piso
	while not player_node.is_on_floor():
		await get_tree().process_frame # Espera un frame y vuelve a preguntar
	
	# FRENAR Y PONER IDLE
	player_node.velocity = Vector2.ZERO
	if player_node.has_node("AnimatedSprite2D"):
		player_node.get_node("AnimatedSprite2D").play("SIdle with Gun")
	
	# PAUSA DRAMÁTICA
	await get_tree().create_timer(2.5).timeout
	
	# DEVOLVER EL CONTROL
	if "is_cutscene" in player_node:
		player_node.is_cutscene = false
	
	# APARICIÓN DEL JEFE
	# Usamos 'await' para que el nivel espere a que el jefe termine de brillar
	if final_boss:
		await final_boss.play_intro_sequence()
	
	# PAUSA DE TENSIÓN (Boss visible, mirándose fijamente)
	await get_tree().create_timer(1.0).timeout
	
	# INICIAR COMBATE
	# Devolvemos el control al jugador
	player_node.set_physics_process(true)
	
	# Activar al jefe
	if final_boss:
		final_boss.start_battle()

func _on_boss_toggle_hazards(is_active: bool) -> void:
	if is_active:
		# --- SECUENCIA DE ACTIVACIÓN ---
		print("Nivel 5: ¡ALERTA DE LAVA!")
		
		# 1. Mostrar Advertencia (Estática, sin parpadeo)
		if warning_label:
			warning_label.visible = true
			warning_label.modulate.a = 1.0 # Aseguramos que sea visible

		# 2. Parpadeo del Tilemap
		if tilemap:
			if blink_tween: blink_tween.kill() # Limpieza preventiva
			blink_tween = create_tween()
			
			# Hacemos que parpadee 4 veces (ida y vuelta) = aprox 2 segundos total
			blink_tween.set_loops(4)
			
			# Ciclo: Ir a Rojo -> Volver a Blanco
			blink_tween.tween_property(tilemap, "modulate", danger_color, 0.25)
			blink_tween.tween_property(tilemap, "modulate", normal_color, 0.25)
		
		# 3. Esperar un momento mientras parpadea (1.5 segundos)
		await get_tree().create_timer(1.5).timeout
		
		# --- PUNTO CLAVE: PLATAFORMAS ANTES DEL FINAL ---
		# Activamos las plataformas para que el player tenga a donde ir
		blink_and_show_platforms()
		
		# 4. Esperar el resto del tiempo (0.5 segundos más) para completar los 2s
		await get_tree().create_timer(1.0).timeout
		
		# 5. FINAL DE LA SECUENCIA
		set_molten_rock_active(true) # Sube la lava
		
		if warning_label:
			warning_label.visible = false # Se va el cartel ("sale el warning_label")
	
	else:
		# --- SECUENCIA DE DESACTIVACIÓN ---
		print("Nivel 5: Calma...")
		
		# 1. Resetear UI y Tweens
		if warning_label: warning_label.visible = false
		if blink_tween: blink_tween.kill()

		# 2. Restaurar Color del Nivel
		if tilemap:
			var reset_tween = create_tween()
			reset_tween.tween_property(tilemap, "modulate", normal_color, 0.5)

		# 3. Desactivar mecánicas
		blink_and_hide_platforms()
		set_molten_rock_active(false)
	

func _on_boss_die():
	set_molten_rock_active(false)
	open_gates()

func close_gates():
	gates.enabled = true 
	gates.visible = true
	gates_trigger.set_deferred("monitoring", false)

func open_gates():
	gates.enabled = false
	gates.visible = false
