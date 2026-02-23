extends CharacterBody2D

# ==============================================================================
# SEÑALES
# ==============================================================================
signal add_points

# ==============================================================================
# CONSTANTES
# ==============================================================================
const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(22, 12)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-5, 12)
const gravity: int = 2000
const movement_velocity: int = 60

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN)
# ==============================================================================
@export var bullet_sprite: Texture2D

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast_floor: RayCast2D = $RayCast2D
@onready var shoot_timer: Timer = $Timer

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

# ==============================================================================
# VARIABLES DE ESTADO Y REFERENCIAS EXTERNAS
# ==============================================================================
var player: Node2D = null  
var direction: int = 1
var points: int = 20

var lives: int = 3
var is_alive: bool = true
var enemy_is_near: bool = false

var bullet_scene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2

var can_shoot: bool = true
var damage_tween: Tween


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

func _ready() -> void:
	# Duplica el material para que los efectos de daño (como parpadeos) no afecten a otros enemigos
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Walk")
	
	# Obtiene la referencia al jugador desde la escena actual
	player = get_tree().current_scene.get_node_or_null("%Player")
	
	if walk_sound: walk_sound.play()

func _physics_process(delta) -> void:
	# Aplica gravedad constante si no está tocando el suelo
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# Delega el comportamiento según el estado vital
	if is_alive:
		_process_alive_state()
	else:
		_process_dead_state(delta)
		
	# Ejecuta el movimiento y procesa colisiones
	move_and_slide()


# ==============================================================================
# LÓGICA DE ESTADOS (MÁQUINA DE ESTADOS BÁSICA)
# ==============================================================================

func _process_alive_state() -> void:
	# Valida si el jugador existe y sigue con vida
	var player_valid = is_instance_valid(player) and "is_alive" in player and player.is_alive
	
	# Cancela el estado de alerta si el jugador deja de ser válido (ej. muere o desaparece)
	if enemy_is_near and not player_valid:
		enemy_is_near = false
	
	if enemy_is_near:
		# --- ESTADO: ATACANDO ---
		update_sprite_direction(player.global_position.x < global_position.x)
		velocity.x = 0
		
		if animated_sprite.animation != "Shoot":
			animated_sprite.play("Shoot")
			
		if can_shoot:
			shoot_bullet()
			shoot_sound.play()
			can_shoot = false
			shoot_timer.start(0.75)
	else:
		# --- ESTADO: PATRULLANDO ---
		update_sprite_direction(velocity.x < 0)
		
		# Detecta bordes o paredes para invertir la dirección de la patrulla
		if is_on_wall() or not raycast_floor.is_colliding():
			direction *= -1
			raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS
			
		velocity.x = direction * movement_velocity
		
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")

func _process_dead_state(delta) -> void:
	# Aplica fricción gradual hasta que el cadáver se detenga por completo
	velocity.x = move_toward(velocity.x, 0, movement_velocity * delta * 5)


# ==============================================================================
# LÓGICA DE COMBATE Y ACCIONES
# ==============================================================================

# Actualiza la orientación del sprite, el hitbox y el punto de aparición de la bala
func update_sprite_direction(is_facing_left: bool) -> void:
	var offset = 10
	if is_facing_left:
		animated_sprite.flip_h = true
		animated_sprite.position.x = -offset
		collision_shape.position.x = offset
		bullet_offset = Vector2(-15, -9)
		bullet_dir = Vector2.LEFT
	else:
		animated_sprite.flip_h = false
		animated_sprite.position.x = offset
		collision_shape.position.x = offset
		bullet_offset = Vector2(35, -9)
		bullet_dir = Vector2.RIGHT

# Instancia y dispara el proyectil
func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	if bullet.has_method("set_direction"):
		bullet.set_direction(bullet_dir)
		
	bullet.global_position = global_position + bullet_offset
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bullet)

# Recibe daño y ejecuta el parpadeo rojo
func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	
	# Reinicia el tween si ya estaba en curso
	if damage_tween: 
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()

# Ejecuta la secuencia de muerte y limpieza
func die() -> void:
	is_alive = false
	
	emit_signal("add_points", points)
	
	# Desactiva la capa de colisión para no seguir recibiendo daño
	set_collision_layer_value(3, false)
	set_physics_process(false)
	
	if walk_sound: walk_sound.stop()
	shoot_timer.stop()
	can_shoot = false
	
	animated_sprite.play("Death")
	death_sound.play()
	
	# Espera a que termine el sonido antes de eliminar el nodo
	await death_sound.finished
	
	queue_free()


# ==============================================================================
# GESTIÓN DE SEÑALES
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			enemy_is_near = true

func _on_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and body.is_in_group("Player"):
		enemy_is_near = false

func _on_shoot_timer_timeout() -> void:
	if is_alive:
		can_shoot = true
