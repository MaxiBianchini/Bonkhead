extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var raycast_floor = $RayCast2D
@onready var detection_area = $Area2D/CollisionShape2D2
@onready var anim_player = $AnimationPlayer

@onready var player = get_tree().current_scene.get_node_or_null("%Player") # Encuentra al jugador en la escena

const FLOOR_RAYCAST_RIGHT_POS: Vector2 = Vector2(22, 12)
const FLOOR_RAYCAST_LEFT_POS: Vector2 = Vector2(-5, 12)


# Variables para controlar el movimiento y la física
var direction: int = 1
const gravity: int = 2000
const movement_velocity: int = 60

signal add_points
var points = 20
var is_shooting: bool = false

# Variables para controlar la vida
var lives: int = 3
var is_alive: bool = true
var enemy_is_near: bool = false

# Carga la escena de la bala
var bullet_scene = preload("res://Prefabs/Bullet_1.tscn")
var bullet_dir = Vector2.RIGHT
var bullet_offset: Vector2

var can_shoot: bool = true

func _ready():
	animated_sprite.play("Walk") # Reproduce la animación de caminar por defecto

func _physics_process(delta):
	if is_alive:
		# Actualiza las posiciones de los nodos según la dirección
		update_sprite_direction(velocity.x < 0)
		
		# Aplica la gravedad si no está en el suelo
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		
		# Invierte la dirección si está en la pared o no está en el suelo
		if is_on_wall() or not raycast_floor.is_colliding():
			direction *= -1
			raycast_floor.position = FLOOR_RAYCAST_LEFT_POS if direction < 0 else FLOOR_RAYCAST_RIGHT_POS
		
		# Controla el movimiento del enemigo
		if !enemy_is_near:
			velocity.x = direction * movement_velocity
			move_and_slide()
		
		# Verifica la proximidad del jugador y cambia la animación y el comportamiento
		if player and player.is_alive:
			# Verificar si el jugador está dentro del área de detección
			if enemy_is_near:
				# Actualiza la dirección y posición del enemigo según la posición del jugador
				update_sprite_direction(player.position.x < position.x)
				animated_sprite.play("Shoot")
				if can_shoot:
					
					shoot_bullet()
					can_shoot = false
					await (get_tree().create_timer(2.0).timeout)
					can_shoot = true
			else:
				animated_sprite.play("Walk")
		else:
			animated_sprite.play("Walk")
			enemy_is_near = false



# Controlador de la direccion del Sprite
func update_sprite_direction(value):
	var offset = 10
	if value:
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


func shoot_bullet():
	var bullet = bullet_scene.instantiate() as Area2D # Instancia la bala
	
	bullet.mask = 2
	# Le indicamos quién la disparó:
	bullet.shooter = self
	
	 # Posición final de la bala y dirección
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir
	
	get_tree().current_scene.add_child(bullet) # Añade la bala a la escena actual


# Controlador del Daño
func take_damage():
	if is_alive:
		anim_player.play("Hurt")
		lives -= 1
		emit_signal("add_points", points)  # Enviar la señal a la UI
		if lives == 0:
			is_alive = false
			animated_sprite.play("Death")


func _on_animation_finished():
	if animated_sprite.animation == "Death":
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		enemy_is_near = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		enemy_is_near = false
