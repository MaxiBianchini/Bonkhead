extends CharacterBody2D

# ==============================================================================
# SEÑALES
# ==============================================================================
signal add_points

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN)
# ==============================================================================
@export var bullet_sprite: Texture2D

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var shoot_timer: Timer = $Timer
@onready var raycast_wall: RayCast2D = $RayCast2D
@onready var raycast_floor: RayCast2D = $RayCast2D2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

# ==============================================================================
# VARIABLES DE ESTADO Y MOVIMIENTO
# ==============================================================================
# --- Referencias externas ---
var player: Node2D = null
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")

# --- Vectores y posiciones ---
var bullet_offset: Vector2
var bullet_dir: Vector2
var start_position: Vector2
var initial_height: float

# --- Configuración de IA y Movimiento ---
var horizontal_speed: float = 100.0
var vertical_speed: float = 80.0
var patrol_range: float = 200.0
var patrol_direction: int = 1
var chase_stop_distance_x: float = 80.0
var hover_offset_y: float = 25.0

# --- Flags de estado ---
var follow_player: bool = false
var can_shoot: bool = true
var is_alive: bool = true

# --- Estadísticas y Utilidades ---
var lives: int = 3
var points = 30
var damage_tween: Tween


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del enemigo
func _ready() -> void:
	# Duplica el material para permitir efectos visuales (parpadeo de daño) independientes
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Walk Scan")
	
	if walk_sound: walk_sound.play()
	
	# Guarda la posición original para limitar el rango de patrulla y la altura base
	start_position = global_position
	initial_height = global_position.y
	
	player = get_tree().current_scene.get_node_or_null("%Player")

# Bucle principal de IA y físicas
func _physics_process(delta: float) -> void:
	if not is_alive:
		apply_dead_physics(delta)
		return
		
	# Valida si el jugador existe y sigue vivo
	var player_valid = is_instance_valid(player) and "is_alive" in player and player.is_alive
	
	if follow_player and player_valid:
		# Verifica si el enemigo va a chocar contra paredes o el suelo
		var hit_floor_wall = raycast_wall.is_colliding() and raycast_wall.get_collider().is_in_group("Floor")
		var hit_floor_bottom = raycast_floor.is_colliding() and raycast_floor.get_collider().is_in_group("Floor")
		
		# Abandona la persecución si el terreno bloquea su paso
		if hit_floor_wall or hit_floor_bottom:
			follow_player = false
		else:
			chase_player()
	else:
		follow_player = false
		return_to_height()
		patrol_horizontally()
		
	move_and_slide()


# ==============================================================================
# LÓGICA DE INTELIGENCIA ARTIFICIAL (MOVIMIENTO Y PERSECUCIÓN)
# ==============================================================================

# Lógica de persecución y posicionamiento para atacar
func chase_player() -> void:
	var dx = player.global_position.x - global_position.x
	var desired_y = player.global_position.y - hover_offset_y
	
	# Acercamiento horizontal hasta el punto de frenado
	if abs(dx) > chase_stop_distance_x:
		var horizontal_dir = sign(dx)
		animated_sprite.flip_h = (horizontal_dir < 0.0)
		velocity.x = horizontal_dir * horizontal_speed 
	else:
		# Frena, apunta y dispara al jugador
		velocity.x = 0
		animated_sprite.flip_h = (dx < 0.0)
		bullet_offset = Vector2(-10, 15) if (dx < 0.0) else Vector2(10, 15)
		
		if can_shoot:
			shoot_bullet()
			if shoot_sound: shoot_sound.play()
			can_shoot = false
			shoot_timer.start(1.0)  
			
	# Ajuste vertical (hovering) para mantener la altura sobre el jugador
	var vertical_dir = sign(desired_y - global_position.y)
	if abs(global_position.y - desired_y) > 2.0:
		velocity.y = vertical_dir * vertical_speed
	else:
		velocity.y = 0

# Regresa a la altura de vuelo original tras perder al jugador
func return_to_height() -> void:
	if abs(global_position.y - initial_height) > 2.0:
		var vertical_dir = sign(initial_height - global_position.y)
		velocity.y = vertical_dir * vertical_speed
	else:
		velocity.y = 0

# Patrullaje horizontal dentro de los límites establecidos
func patrol_horizontally() -> void:
	# Invierte la dirección si choca con una pared o se sale del rango
	if raycast_wall.is_colliding() and raycast_wall.get_collider().is_in_group("Floor"):
		patrol_direction *= -1
	elif global_position.x > start_position.x + patrol_range:
		patrol_direction = -1
	elif global_position.x < start_position.x - patrol_range:
		patrol_direction = 1
	
	raycast_wall.target_position = Vector2(50 * patrol_direction, 0)
	velocity.x = patrol_direction * horizontal_speed
	animated_sprite.flip_h = (patrol_direction < 0)


# ==============================================================================
# LÓGICA DE COMBATE Y DAÑO
# ==============================================================================

# Instancia, orienta y dispara el proyectil hacia el jugador
func shoot_bullet() -> void:
	animated_sprite.play("Attack")
	if not is_instance_valid(player):
		return

	var bullet = bullet_scene.instantiate() as Area2D
	
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
		
	var direction_to_player = (player.global_position - global_position).normalized()
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	if bullet.has_method("set_mask"):
		bullet.set_mask(2)
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction_to_player)
		
	bullet.global_position = global_position + bullet_offset
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bullet)

# Recibe daño y aplica feedback visual
func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	
	emit_signal("add_points", points)
	
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()
	else:
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

# ==============================================================================
# LÓGICA DE MUERTE
# ==============================================================================

# Ejecuta la limpieza de nodos y animación de muerte
func die() -> void:
	is_alive = false
	
	if walk_sound: walk_sound.stop()
	shoot_timer.stop()
	can_shoot = false
	
	set_collision_layer_value(3, false)
	collision_shape.position.y = 9
	
	animated_sprite.play("Death")
	if death_sound: death_sound.play()
	
	await animated_sprite.animation_finished
	queue_free()

# Físicas aplicadas únicamente al cadáver cayendo
func apply_dead_physics(delta: float) -> void:
	velocity.y += 2000 * delta
	velocity.x = move_toward(velocity.x, 0, horizontal_speed * delta * 5)
	move_and_slide()


# ==============================================================================
# GESTIÓN DE SEÑALES (ÁREAS DE DETECCIÓN Y TIMERS)
# ==============================================================================

func _on_body_entered(body: Node) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			animated_sprite.play("Walk")
			follow_player = true

func _on_body_exited(body: Node) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		animated_sprite.play("Walk Scan")
		if walk_sound and not walk_sound.playing:
			walk_sound.play()
		follow_player = false

func _on_shoot_timer_timeout() -> void:
	if is_alive:
		can_shoot = true
		if follow_player:
			animated_sprite.play("Walk")
