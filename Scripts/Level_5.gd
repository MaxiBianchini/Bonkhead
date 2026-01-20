extends Node2D

# --- Referencias ---
@onready var platforms_1: Node2D = $Platform_Fase1
@onready var platforms_2: Node2D = $Platform_Fase2
@onready var molten_rock: TileMapLayer = $"TileMaps/Molten Rock 2"
@onready var dead_area: Area2D = $Dead_Area2
@onready var gates: TileMapLayer = $TileMaps/Gates
@onready var gates_trigger: Area2D = $GatesArea

@export var final_boss: CharacterBody2D

# --- Configuración Inicial ---
func _ready() -> void:
	# Estado inicial
	set_molten_rock_active(false)
	
	# Aseguramos que las plataformas arranquen invisibles y sin colisión
	platforms_1.visible = false
	platforms_1.modulate.a = 0.0
	platforms_2.visible = false
	platforms_2.modulate.a = 0.0
	_set_platform_collision(false,1)
	_set_platform_collision(false,2)
	
	open_gates()
	
	#print("--- TEST INICIADO ---")
	
	# Esperamos un poco antes de empezar la secuencia
	await get_tree().create_timer(5.0).timeout
	
	# 1. APARECER: Parpadeo -> Sólido
	print("Fase 2: Iniciando aparición de plataformas...")
	await blink_and_show_platforms(1) 
	print("Plataformas listas y sólidas.")
	
	# Mantenemos las plataformas un rato (Simulando la fase)
	#await get_tree().create_timer(5.0).timeout
	
	# 2. DESAPARECER: Parpadeo -> Invisible
	print("Fase 2 terminada: Las plataformas se van...")
	#await blink_and_hide_platforms()
	print("Plataformas eliminadas.")
	
	#open_gates()

# --- LÓGICA DE APARICIÓN (Blink In) ---
func blink_and_show_platforms(grup_plat) -> void:
	var platforms_container
	match grup_plat:
		1:
			platforms_container = platforms_1
		2: 
			platforms_container = platforms_2
	
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
	_set_platform_collision(true,grup_plat)
	#await get_tree().create_timer(2.0).timeout
	#set_molten_rock_active(true)

# --- LÓGICA DE DESAPARICIÓN (Blink Out) ---
func blink_and_hide_platforms(grup_plat) -> void:
	var platforms_container
	match grup_plat:
		1:
			platforms_container = platforms_1
		2: 
			platforms_container = platforms_2
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
	_set_platform_collision(false,grup_plat)
	set_molten_rock_active(false)

# --- FUNCIÓN AUXILIAR DE FÍSICA ---
func _set_platform_collision(is_active: bool, grup_plat: int) -> void:
	var platforms_container
	match grup_plat:
		1:
			platforms_container = platforms_1
		2: 
			platforms_container = platforms_2
	
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

func close_gates():
	gates.enabled = true 
	gates.visible = true
	gates_trigger.set_deferred("monitoring", false)

func open_gates():
	gates.enabled = false
	gates.visible = false
