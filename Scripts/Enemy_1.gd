extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var raycast_floor = $RayCast2D

@onready var player = get_node("../Player") # Encuentra al jugador en la escena
 
# Variables para definir el área de detección rectangular
var detection_width: int = 100  # Ancho del área de detección
var detection_height: int = 90  # Altura del área de detección

# Variables para controlar el movimiento y la física
var direction: int = 1
const gravity: int = 2000
const movement_velocity: int = 60

var is_stay_angry: bool = false

# Variables para controlar la vida
var lives: int = 3
var is_alive: bool = true

# Carga la escena de la bala
var bullet_scene = preload("res://Prefabs/Bullet_1.tscn")

func _ready():
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.play("Walk") # Reproduce la animación de caminar por defecto

func _physics_process(delta):
	
	if is_alive:
		# Actualiza las posiciones de los nodos según la dirección
		update_sprite_direction(velocity.x < 0)
		
		# Aplica la gravedad si no está en el suelo
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Invierte la dirección si está en la pared o no está en el suelo
		if is_on_wall() or not raycast_floor.is_colliding():
			direction *= -1
		
		# Controla el movimiento del enemigo
		if animated_sprite.animation != "Shoot":
			velocity.x = direction * movement_velocity
			move_and_slide()
		
		# Verifica la proximidad del jugador y cambia la animación y el comportamiento
		if player and player.is_alive:
			# Verificar si el jugador está dentro del área de detección
			if abs(player.position.x - position.x) <  detection_width  and abs(player.position.y - position.y) < detection_height:
				if not is_stay_angry:
					animated_sprite.play("Shoot")
					is_stay_angry = true
					detection_width = 200
					
				# Actualiza la dirección y posición del enemigo según la posición del jugador
				if player.position.x < position.x:
					update_sprite_direction(true) # Actualizar la dirección del sprite
				else:
					update_sprite_direction(false) # Actualizar la dirección del sprite
				
				await (get_tree().create_timer(3.0).timeout)
				shoot_bullet()
			
			else:
				if is_stay_angry:
					is_stay_angry = false
					animated_sprite.play("Walk")
					detection_width = 100


# Controlador de la direccion del Sprite
func update_sprite_direction(value):
	var offset = 10
	if value:
		animated_sprite.flip_h = true
		animated_sprite.position.x = -offset
		collision_shape.position.x = offset
	else:
		animated_sprite.flip_h = false
		animated_sprite.position.x = offset
		collision_shape.position.x = offset


func shoot_bullet():
	var bullet_instance = bullet_scene.instantiate() # Instancia la bala
	
	# Posiciona la bala en la posición del player + una distancia
	bullet_instance.position = position + Vector2(30, 0)
	get_tree().current_scene.add_child(bullet_instance) # Añade la bala a la escena actual


# Controlador del Daño
func take_damage():
	lives -= 1
	if lives == 0:
		is_alive = false
		animated_sprite.play("Death")
	else:
		$AnimationPlayer.play("Hurt")
		await (get_tree().create_timer(3.0).timeout)


func _on_animation_finished():
	if animated_sprite.animation == "Death":
		queue_free()
