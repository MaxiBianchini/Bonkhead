extends CharacterBody2D

# Referencias a nodos del enemigo
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var raycast_floor: RayCast2D = $RayCast2D
@onready var shoot_timer: Timer = $Timer

@onready var player = get_tree().current_scene.get_node_or_null("%Player")  

# Constantes para las posiciones del RayCast2D según la dirección
const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(22, 12)  # Posición del raycast mirando a la derecha
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-5, 12)   # Posición del raycast mirando a la izquierda

# Variables para controlar el movimiento y la física
var direction: int = 1              # Dirección del movimiento (1: derecha, -1: izquierda)
const gravity: int = 2000           # Valor de la gravedad aplicada al enemigo
const movement_velocity: int = 60   # Velocidad horizontal del enemigo

# Señal para notificar cuando se deben agregar puntos al recibir daño
signal add_points
var points: int = 20                # Puntos otorgados al dañar al enemigo

# Variables de estado del enemigo
var lives: int = 3                  # Vidas restantes del enemigo
var is_alive: bool = true           # Indica si el enemigo está vivo
var enemy_is_near: bool = false     # Indica si el jugador está dentro del área de detección

# Configuración de la bala
var bullet_scene = preload("res://Prefabs/Bullet_1.tscn")
var bullet_offset: Vector2
var bullet_dir: Vector2

# Control del disparo
var can_shoot: bool = true          # Indica si el enemigo puede disparar

func _ready() -> void:
	# Duplica el material del sprite para que sea único por instancia (evita compartirlo entre enemigos)
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.play("Walk")     # Inicia la animación de caminar al instanciar al enemigo

func _physics_process(delta) -> void:
	if is_alive:
		# Actualiza la dirección del sprite según la velocidad o la posición del jugador
		if enemy_is_near:
			# Si el jugador está cerca, orienta el sprite hacia él
			update_sprite_direction(player.position.x < position.x)
		else:
			# Si no, orienta según la dirección de movimiento
			update_sprite_direction(velocity.x < 0)
		
		# Aplica gravedad si el enemigo no está en el suelo
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Invierte la dirección si choca con una pared o no hay suelo adelante
		if is_on_wall() or not raycast_floor.is_colliding():
			direction *= -1
			# Ajusta la posición del RayCast2D según la nueva dirección
			raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS
		
		# Controla el movimiento horizontal del enemigo
		if not enemy_is_near:
			velocity.x = direction * movement_velocity  # Mueve al enemigo si el jugador no está cerca
		else:
			velocity.x = 0  # Detiene el movimiento si el jugador está cerca
		
		# Aplica el movimiento físico al enemigo
		move_and_slide()
		
		# Comportamiento cuando el jugador está cerca y vivo
		if enemy_is_near and player and player.is_alive:
			animated_sprite.play("Shoot")  # Cambia a la animación de disparo
			if can_shoot:
				shoot_bullet()            # Dispara una bala
				can_shoot = false         # Desactiva el disparo temporalmente
				shoot_timer.start(0.75)   # Espera 1.5 segundos antes de permitir otro disparo
		else:
			animated_sprite.play("Walk")  # Vuelve a la animación de caminar si el jugador no está cerca
			enemy_is_near = false

# Actualiza la dirección visual del sprite y ajusta posiciones
func update_sprite_direction(is_facing_left: bool) -> void:
	var offset = 10  # Desplazamiento para alinear sprite y colisión
	if is_facing_left:
		animated_sprite.flip_h = true         # Gira el sprite hacia la izquierda
		animated_sprite.position.x = -offset  # Ajusta la posición del sprite
		collision_shape.position.x = offset   # Ajusta la posición de la colisión
		bullet_offset = Vector2(-15, -9)     # Offset de la bala hacia la izquierda
		bullet_dir = Vector2.LEFT            # Dirección de la bala hacia la izquierda
	else:
		animated_sprite.flip_h = false        # Gira el sprite hacia la derecha
		animated_sprite.position.x = offset   # Ajusta la posición del sprite
		collision_shape.position.x = offset   # Ajusta la posición de la colisión
		bullet_offset = Vector2(35, -9)      # Offset de la bala hacia la derecha
		bullet_dir = Vector2.RIGHT           # Dirección de la bala hacia la derecha

# Instancia y configura una bala para disparar
func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D  # Crea una nueva instancia de la bala
	bullet.mask = 2                            # Define la máscara de colisión de la bala
	bullet.shooter = self                      # Indica que este enemigo disparó la bala
	 
	bullet.position = position + bullet_offset # Posiciona la bala respecto al enemigo
	bullet.direction = bullet_dir              # Asigna la dirección de la bala
	get_tree().current_scene.add_child(bullet) # Añade la bala a la escena actual

# Maneja el daño recibido por el enemigo
func take_damage() -> void:
	if not is_alive:
		return # No hacer nada si ya está muerto
	
	lives -= 1
	if lives <= 0:
		is_alive = false
		velocity.x = 0
		animated_sprite.play("Death") # Reproducir la animación de muerte
		await animated_sprite.animation_finished  # Espera a que la animación termine
		queue_free()
	else:
		animation_player.play("Hurt") # Reproducir la animación de daño
		emit_signal("add_points", points)  # Enviar la señal a la UI
		
		can_shoot = false
		if shoot_timer.time_left > 0:
			shoot_timer.start(shoot_timer.time_left + 1.0)
		else:
			shoot_timer.start(1.0)

# Detecta cuando el jugador entra en el área de detección
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.is_alive:
		enemy_is_near = true  # Activa el estado de "jugador cerca"

# Detecta cuando el jugador sale del área de detección
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body.is_alive:
		enemy_is_near = false  # Desactiva el estado de "jugador cerca"

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
