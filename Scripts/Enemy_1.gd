extends CharacterBody2D

# Variables para definir el área de detección rectangular
var detection_width = 100  # Ancho del área de detección
var detection_height = 90  # Altura del área de detección

# Variables para controlar el movimiento y la física
const movement_velocity = 60
const gravity = 2000
var direction = 1

var is_stay_angry = false

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var raycast_floor = $RayCast2D
@onready var player = get_node("../Player") # Encuentra al jugador en la escena

func _ready():
	#animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.play("Walk") # Reproduce la animación de caminar por defecto

func _physics_process(delta):
	# Actualiza las posiciones de los nodos según la dirección
	update_sprite_direction(velocity.x < 0)
	
	# Aplica la gravedad si no está en el suelo
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Invierte la dirección si está en la pared o no está en el suelo
	if is_on_wall() or not raycast_floor.is_colliding():
		direction *= -1
	
	# Controla el movimiento del enemigo
	if animated_sprite.animation != "Shot":
		velocity.x = direction * movement_velocity
		move_and_slide()
	
	# Verifica la proximidad del jugador y cambia la animación y el comportamiento
	if player and player.is_alive:
		# Verificar si el jugador está dentro del área de detección
		if abs(player.position.x - position.x) <  detection_width  and abs(player.position.y - position.y) < detection_height:
			if not is_stay_angry:
				animated_sprite.play("Shot")
				is_stay_angry = true
				detection_width = 200
				
			# Actualiza la dirección y posición del enemigo según la posición del jugador
			if player.position.x < position.x:
				update_sprite_direction(true)
			else:
				update_sprite_direction(false)
		
		else:
			if is_stay_angry:
				is_stay_angry = false
				animated_sprite.play("Walk")
				detection_width = 100
	

func update_sprite_direction(value):
	var offset = Vector2(10, 0)
	if value:
		animated_sprite.flip_h = true
		animated_sprite.position = -offset
		collision_shape.position = offset
	else:
		animated_sprite.flip_h = false
		animated_sprite.position = offset
		collision_shape.position = offset
	

#func _on_animation_finished():
	#if animated_sprite.animation == "Angry":
	#	animated_sprite.play("Shot")
	
