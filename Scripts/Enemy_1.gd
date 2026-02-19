extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast_floor: RayCast2D = $RayCast2D
@onready var shoot_timer: Timer = $Timer

@onready var shoot_sound: AudioStreamPlayer2D = $AudioStream_Shoot
@onready var walk_sound: AudioStreamPlayer2D = $AudioStream_Walk
@onready var death_sound: AudioStreamPlayer2D = $AudioStream_Death

var player: Node2D = null  

const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(22, 12)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-5, 12)

var direction: int = 1
const gravity: int = 2000
const movement_velocity: int = 60

signal add_points
var points: int = 20

var lives: int = 3
var is_alive: bool = true
var enemy_is_near: bool = false

@export var bullet_sprite: Texture2D
var bullet_scene = preload("res://Prefabs/Bullet.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2

var can_shoot: bool = true
var damage_tween: Tween # Para evitar solapamiento de animaciones de daño

func _ready() -> void:
	# Duplicamos material para que el parpadeo de daño sea único a esta instancia
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Walk")
	
	# Obtenemos al jugador de forma segura usando tu método original
	player = get_tree().current_scene.get_node_or_null("%Player")
	
	# Iniciamos sonido de caminata
	if walk_sound: walk_sound.play()

func _physics_process(delta) -> void:
	# 1. APLICAMOS GRAVEDAD SIEMPRE (incluso si está muerto, para que el cadáver caiga)
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if is_alive:
		_process_alive_state()
	else:
		_process_dead_state(delta)
		
	# 2. MOVER Y DESLIZAR SIEMPRE
	move_and_slide()

func _process_alive_state() -> void:
	# Verificación vital: ¿El jugador existe y su propiedad is_alive es true?
	var player_valid = is_instance_valid(player) and "is_alive" in player and player.is_alive
	
	# Si estábamos cerca pero el jugador murió o desapareció, cancelamos el estado
	if enemy_is_near and not player_valid:
		enemy_is_near = false
	
	if enemy_is_near:
		update_sprite_direction(player.global_position.x < global_position.x)
		velocity.x = 0 # Nos detenemos para disparar
		
		# Evita reiniciar la animación en cada frame si ya está disparando
		if animated_sprite.animation != "Shoot":
			animated_sprite.play("Shoot")
			
		if can_shoot:
			shoot_bullet()
			shoot_sound.play()
			can_shoot = false
			shoot_timer.start(0.75)
	else:
		# Lógica de patrulla normal
		update_sprite_direction(velocity.x < 0)
		
		if is_on_wall() or not raycast_floor.is_colliding():
			direction *= -1
			raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS
			
		velocity.x = direction * movement_velocity
		
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")

func _process_dead_state(delta) -> void:
	# Frena el cuerpo gradualmente si estaba caminando o es empujado por un impacto
	velocity.x = move_toward(velocity.x, 0, movement_velocity * delta * 5)

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
		
	# CRÍTICO: Usar global_position para no duplicar offsets en escenas anidadas
	bullet.global_position = global_position + bullet_offset
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bullet)

func take_damage() -> void:
	if not is_alive:
		return
	
	lives -= 1
	
	# Control de Tweens: Matar el anterior si existe para evitar glitches visuales
	if damage_tween: 
		damage_tween.kill()
		
	damage_tween = create_tween()
	animated_sprite.modulate = Color(1, 0, 0, 1)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE)
	
	if lives <= 0:
		die()

func die() -> void:
	is_alive = false
	
	# Emitir puntos SOLAMENTE cuando muere
	emit_signal("add_points", points)
	
	# Desactivamos colisión con balas (Capa 3) para que no sea un escudo de carne
	set_collision_layer_value(3, false)
	
	# Detener sonidos y timers inmediatamente
	if walk_sound: walk_sound.stop()
	shoot_timer.stop()
	can_shoot = false
	
	animated_sprite.play("Death")
	death_sound.play()
	
	# Esperar a que termine el sonido o la animación de muerte
	await death_sound.finished
	
	# Destruir nodo limpiamente
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Validación segura: comprobamos grupo y la existencia de la propiedad "is_alive"
	if is_instance_valid(body) and body.is_in_group("Player"):
		if "is_alive" in body and body.is_alive:
			enemy_is_near = true

func _on_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and body.is_in_group("Player"):
		enemy_is_near = false

func _on_shoot_timer_timeout() -> void:
	if is_alive:
		can_shoot = true
