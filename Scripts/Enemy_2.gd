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
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $Timer
@onready var area2d: Area2D = $Area2D

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var idle_sound: AudioStreamPlayer2D = $AudioStream_Idle 
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

# ==============================================================================
# VARIABLES DE ESTADO Y REFERENCIAS EXTERNAS
# ==============================================================================
var player: Node2D = null
var bullet_scene: PackedScene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2 

var detection_width: float = 10000.0
var enemy_is_near: bool = false
var can_shoot: bool = true

var lives: int = 3
var is_alive: bool = true
var points = 25

var damage_tween: Tween


# ==============================================================================
# FUNCIONES DEL CICLO DE VIDA DE GODOT
# ==============================================================================

# Inicialización del enemigo al cargar la escena
func _ready() -> void:
	# Duplica el material para permitir efectos visuales independientes (ej. parpadeo de daño)
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Idle")
	
	if idle_sound: idle_sound.play()
	
	# Obtiene la referencia global del jugador de forma segura
	player = get_tree().current_scene.get_node_or_null("%Player")

# Bucle principal: Maneja el apuntado y la lógica de disparo continuo
func _physics_process(_delta: float) -> void:
	# Cláusulas de guarda: Verifica que el enemigo y el jugador sigan activos
	if not is_alive or not is_instance_valid(player):
		return
		
	var is_player_alive = "is_alive" in player and player.is_alive
	if not is_player_alive:
		return
	
	# Calcula la distancia horizontal hacia el jugador
	var distance_x = player.global_position.x - global_position.x
	
	# Lógica de apuntado: Gira el sprite y ajusta el cañón si el jugador está en el rango
	if abs(distance_x) < (detection_width * 0.5):
		if distance_x < 0:
			animated_sprite.flip_h = true
			animated_sprite.position.x = -8
			bullet_offset = Vector2(-25, 5)
			bullet_dir = Vector2.LEFT
		else:
			animated_sprite.flip_h = false
			animated_sprite.position.x = 7
			bullet_offset = Vector2(25, 5)
			bullet_dir = Vector2.RIGHT
	
	# Dispara automáticamente si el jugador está en el área de detección y el arma está lista
	if enemy_is_near and can_shoot:
		shoot_bullet()
		can_shoot = false
		shoot_timer.start(0.75)


# ==============================================================================
# LÓGICA DE COMBATE Y DAÑO
# ==============================================================================

# Instancia y configura el proyectil para ser disparado
func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	if shoot_sound: shoot_sound.play()
	
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

# Recibe daño, penaliza el tiempo de disparo y gestiona el feedback visual
func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	
	emit_signal("add_points", points)
	
	# Reinicia la animación de daño si recibe múltiples golpes rápidos
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()
	else:
		# Penalización: Aplaza el siguiente disparo si el enemigo recibe daño
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

# Finaliza el ciclo de vida del enemigo y lo elimina de la escena
func die() -> void:
	is_alive = false
	
	if idle_sound: idle_sound.stop()
	
	set_collision_layer_value(3, false)
	shoot_timer.stop()
	can_shoot = false
	
	animated_sprite.play("Death")
	if death_sound: death_sound.play()
	
	await animated_sprite.animation_finished
	queue_free()


# ==============================================================================
# GESTIÓN DE SEÑALES (INTERACCIONES DE ÁREA Y TIMERS)
# ==============================================================================

func _on_body_entered(body: Node) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			animated_sprite.play("Attack")
			enemy_is_near = true

func _on_body_exited(body: Node) -> void:
	if is_alive and is_instance_valid(body) and body.is_in_group("Player"):
		animated_sprite.play("Idle")
		if idle_sound and not idle_sound.playing: 
			idle_sound.play()
		enemy_is_near = false

func _on_shoot_timer_timeout() -> void:
	if is_alive:
		can_shoot = true
