extends CharacterBody2D

@export var fuse_time: float = 1.0 # Tiempo hasta explotar
@export var damage: int = 2 # Daño al jugador

@onready var explosion_area: Area2D = $ExplosionArea
@onready var sprite = $AnimatedSprite2D # O AnimatedSprite2D

# Gravedad estándar
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_exploded: bool = false

func _ready() -> void:
	# Iniciamos la cuenta regresiva apenas aparece
	get_tree().create_timer(fuse_time).timeout.connect(explode)
	
	# Iniciar animación de "mecha quemándose"
	sprite.play("Idle")

func _physics_process(delta: float) -> void:
	# Caída simple física
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Fricción para que no deslice infinitamente si cae en pendiente
		velocity.x = move_toward(velocity.x, 0, 10.0)
	
	move_and_slide()

func explode() -> void:
	#if has_exploded: return
	has_exploded = true
	
	# 1. Congelar movimiento
	set_physics_process(false)
	sprite.play("Explotion")
	
	# 2. Activar Área de Daño (Explosión)
	explosion_area.monitoring = true
	
	# Verificar instántaneamente si el jugador está dentro (mismo truco que usamos antes)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(false, damage)
	
	# 3. Efectos Visuales (Instanciar partículas o animación de explosión)
	# Aquí podrías instanciar una escena de "ExplosionEffect" si tienes una
	print("¡BOOM!") 
	
	# 4. Limpieza
	# Esperamos un poquito para asegurar que el daño se procese o la animación termine
	await sprite.animation_finished
	queue_free()
