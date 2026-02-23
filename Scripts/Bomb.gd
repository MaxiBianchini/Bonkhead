extends CharacterBody2D

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN)
# ==============================================================================
@export var fuse_time: float = 1.0
@export var damage: int = 2

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var explosion_area: Area2D = $ExplosionArea
@onready var sprite = $AnimatedSprite2D
@onready var sound = $AudioStream_Exploit

# ==============================================================================
# VARIABLES DE ESTADO Y SISTEMA
# ==============================================================================
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_exploded: bool = false


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del nodo al entrar al árbol de escenas
func _ready() -> void:
	# Inicia la cuenta regresiva para la explosión conectada al temporizador
	get_tree().create_timer(fuse_time).timeout.connect(explode)
	
	# Establece el estado visual inicial
	sprite.play("Idle")

# Bucle principal de físicas (se ejecuta cada frame físico del motor)
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		# Aplica gravedad si el objeto se encuentra en el aire
		velocity.y += gravity * delta
	else:
		# Aplica fricción/desaceleración hasta detenerse si toca el suelo
		velocity.x = move_toward(velocity.x, 0, 10.0)
	
	# Ejecuta el movimiento y maneja las colisiones integradas
	move_and_slide()


# ==============================================================================
# LÓGICA DE DETONACIÓN Y DAÑO
# ==============================================================================

# Detona el objeto, evalúa impactos en el área y gestiona su destrucción
func explode() -> void:
	# Cláusula de guarda (Guard clause): Evita ejecuciones múltiples superpuestas
	if has_exploded: return
	has_exploded = true

	# Congela el objeto deteniendo su ciclo de físicas
	set_physics_process(false)
	
	# Despliegue de efectos audiovisuales
	sound.play()
	sprite.play("Explotion")
	
	# Habilita el sensor del área de impacto
	explosion_area.monitoring = true
	
	# Espera dos frames físicos para asegurar que el motor interno 
	# haya registrado y actualizado las colisiones del Area2D habilitado
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Escaneo de entidades dentro del radio de explosión
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(false, damage)
	
	# Mantiene el nodo vivo en memoria hasta que concluya el efecto visual
	await sprite.animation_finished
	
	# Destrucción final y liberación de memoria
	queue_free()
