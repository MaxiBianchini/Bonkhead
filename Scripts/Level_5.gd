extends Node2D

@onready var platforms_container = $Platform_Group
@onready var molten_rock = $"TileMaps/Molten Rock 2"
@onready var Gates: TileMapLayer = $TileMaps/Gates
@onready var GatesArea: Area2D = $GatesArea
@onready var dead_area2 = $Dead_Area2

func _ready() -> void:
	# 1. Al inicio, las ocultamos y desactivamos
	disable_platforms()
	#disable_molten_rock()
	await get_tree().create_timer(5.0).timeout
	
	# Cuando termina el tiempo, ejecuta lo siguiente:
	enable_platforms()
	await get_tree().create_timer(1.0).timeout
	enable_moltern_rock()
	
	await get_tree().create_timer(10.0).timeout
	
	disable_gates()
	dissable_molten_rock()

func disable_platforms():
	platforms_container.visible = false
	# Recorremos cada plataforma hija para apagar su colisión
	for platform in platforms_container.get_children():
		var shape = platform.get_node("CollisionShape2D")
		# ¡IMPORTANTE! Usamos set_deferred
		shape.set_deferred("disabled", true)

func enable_platforms():
	# 2. En Fase 2, las mostramos
	platforms_container.visible = true
	
	# Efecto visual opcional: "Glitch" o aparición
	create_tween().tween_property(platforms_container, "modulate:a", 1.0, 0.5).from(0.0)
	
	for platform in platforms_container.get_children():
		var shape = platform.get_node("CollisionShape2D")
		# ¡IMPORTANTE! Activamos la física de forma segura
		shape.set_deferred("disabled", false)
		

func enable_moltern_rock():
	create_tween().tween_property(molten_rock, "modulate:a", 1.0, 0.5).from(0.0)
	molten_rock.visible = true
	
	dead_area2.monitorable = true
	dead_area2.monitoring = true

func dissable_molten_rock():
	molten_rock.visible = false

func _on_gates_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Gates.enabled = true
		#GatesArea.monitoring = false

func disable_gates():
	Gates.enabled = false
