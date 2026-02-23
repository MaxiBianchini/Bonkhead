extends CharacterBody2D

# ==============================================================================
# SEÑALES
# ==============================================================================
signal add_points

# ==============================================================================
# ENUMS
# ==============================================================================
enum State {
	INACTIVE,
	ACTIVE,
	DEAD
}

# ==============================================================================
# PROPIEDADES EXPORTADAS (CONFIGURACIÓN)
# ==============================================================================
@export var climb_speed: float = 50.0       
@export var patrol_distance: float = 65.0  
@export var attack_cooldown: float = 2.0    
@export var bullet_sprite: Texture2D

# ==============================================================================
# REFERENCIAS A NODOS (ONREADY)
# ==============================================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var projectile_spawn_point: Marker2D = $ProjectileSpawnPoint

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var activ_sound: AudioStreamPlayer2D = $AudioStream_Activated
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

# ==============================================================================
# VARIABLES DE ESTADO Y REFERENCIAS EXTERNAS
# ==============================================================================
var state: State = State.INACTIVE

var player: Node2D = null
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")

var initial_position: Vector2
var patrol_direction: int = 1

var is_alive: bool = true 
var lives: int = 3
var points: int = 30

var damage_tween: Tween


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del enemigo al cargar la escena
func _ready() -> void:
	# Duplica el material para permitir efectos de daño independientes
	animated_sprite.material = animated_sprite.material.duplicate()
	
	# Guarda la posición original para usarla como ancla del límite de patrullaje
	initial_position = global_position
	
	# Configura la cadencia de disparo
	attack_timer.wait_time = attack_cooldown
	
	# Obtiene la referencia al jugador
	player = get_tree().current_scene.get_node_or_null("%Player")

# Bucle de físicas: Máquina de estados principal
func _physics_process(_delta: float) -> void:
	# Cláusula de guarda: Si está muerto, detiene todo procesamiento
	if state == State.DEAD:
		return
		
	# Manejo de comportamiento según el estado actual
	match state:
		State.INACTIVE:
			# --- ESTADO: INACTIVO (Esperando al jugador) ---
			if animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")
			velocity = Vector2.ZERO 
		
		State.ACTIVE:
			# --- ESTADO: ACTIVO (Patrullando y atacando) ---
			
			# Valida si el jugador existe y sigue vivo
			var player_valid = is_instance_valid(player) and "is_alive" in player and player.is_alive
			if not player_valid:
				_deactivate_enemy()
				return
			
			if animated_sprite.animation != "Walk":
				animated_sprite.play("Walk")
			
			# Lógica de patrullaje vertical: Invierter dirección al alcanzar los límites
			if (patrol_direction == 1 and global_position.y >= initial_position.y + patrol_distance) or \
			   (patrol_direction == -1 and global_position.y <= initial_position.y):
				patrol_direction *= -1
			
			# Actualiza el sprite visual dependiendo de la dirección de movimiento vertical
			if patrol_direction == -1: 
				animated_sprite.flip_h = true
				animated_sprite.offset.x = -8
			else: 
				animated_sprite.flip_h = false
				animated_sprite.offset.x = 8
				
			# Aplica velocidad estrictamente vertical (trepar)
			velocity.y = climb_speed * patrol_direction
			velocity.x = 0
			
	# Ejecuta el movimiento físico
	move_and_slide()


# ==============================================================================
# LÓGICA DE INTELIGENCIA ARTIFICIAL Y ESTADO
# ==============================================================================

# Fuerza al enemigo a volver al estado de reposo
func _deactivate_enemy() -> void:
	if state != State.DEAD:
		state = State.INACTIVE
		attack_timer.stop()


# ==============================================================================
# LÓGICA DE COMBATE (DISPARO, DAÑO Y MUERTE)
# ==============================================================================

# Lógica de instanciación y orientación del proyectil
func shoot() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	if bullet.has_method("set_sprite"):
		bullet.set_sprite(bullet_sprite)
	
	# Posiciona la bala en el Marker2D designado
	bullet.global_position = projectile_spawn_point.global_position
	
	# Determina la dirección de disparo en función de dónde esté el Marker2D
	# relativo al centro del enemigo
	var calculated_bullet_dir = Vector2.RIGHT
	if projectile_spawn_point.global_position.x < global_position.x:
		calculated_bullet_dir = Vector2.LEFT
		
	if shoot_sound: shoot_sound.play()
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	if bullet.has_method("set_mask"):
		bullet.set_mask(2) 
	if bullet.has_method("set_direction"):
		bullet.set_direction(calculated_bullet_dir)
		
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bullet)

# Recibe daño y aplica parpadeo rojo (feedback visual)
func take_damage() -> void:
	if not is_alive: return
	
	lives -= 1
	
	emit_signal("add_points", points)
	
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()

# Finaliza el ciclo del enemigo
func die() -> void:
	is_alive = false
	state = State.DEAD
	velocity = Vector2.ZERO
	
	# Desactiva el hitbox para dejar de recibir interacciones
	set_collision_layer_value(3, false)
	attack_timer.stop()
	
	animated_sprite.play("Death")
	if death_sound: death_sound.play()
	
	await animated_sprite.animation_finished
	queue_free()


# ==============================================================================
# GESTIÓN DE SEÑALES (ÁREAS DE DETECCIÓN Y TIMERS)
# ==============================================================================

# Dispara cuando el temporizador de ataque culmina
func _on_attack_timer_timeout() -> void:
	if state == State.ACTIVE and is_alive:
		shoot()

# Detecta al jugador para despertarlo de su estado INACTIVO
func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			if state != State.ACTIVE:
				if activ_sound: activ_sound.play()
				state = State.ACTIVE
				attack_timer.start()

# Apaga al enemigo si el jugador sale de su rango
func _on_detection_area_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and body.is_in_group("Player"):
		_deactivate_enemy()
