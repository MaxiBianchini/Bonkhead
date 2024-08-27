extends CharacterBody2D

# Variables para definir el área de detección rectangular
var detection_width = 200.0  # Ancho del área de detección
var detection_height = 100.0  # Altura del área de detección

# Variables para controlar el movimiento y la física
const VELOCIDAD = 60.0
const GRAVEDAD = 2000.0
var direccion = 1.0
var stop = false

# Referencias a nodos
var animated_sprite
var collision_shape
var player

func _ready():
	# Inicializa las referencias a los nodos
	animated_sprite = $AnimatedSprite2D
	collision_shape = $CollisionShape2D
	
	# Encuentra al jugador en la escena
	player = get_node("../Player")

	# Reproduce la animación de caminar por defecto
	animated_sprite.play("Walk")

func _physics_process(delta):
	# Actualiza la animación y la posición del enemigo según la dirección
	if velocity.x < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

	# Actualiza las posiciones de los nodos según la dirección
	var offset = Vector2(10, 0)
	if velocity.x < 0:
		animated_sprite.position = -offset
		collision_shape.position = offset
	else:
		animated_sprite.position = offset
		collision_shape.position = offset

	# Aplica la gravedad si no está en el suelo
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta
	
	# Invierte la dirección si está en la pared o no está en el suelo
	if is_on_wall() or not is_on_floor():
		direccion *= -1

	# Controla el movimiento del enemigo
	if not stop:
		velocity.x = direccion * VELOCIDAD
		move_and_slide()

	# Verifica la proximidad del jugador y cambia la animación y el comportamiento
	if player:
		var enemy_position = position
		var player_position = player.position
		
		# Definir los límites del área de detección
		var left_bound = enemy_position.x - detection_width / 2
		var right_bound = enemy_position.x + detection_width / 2
		var top_bound = enemy_position.y - detection_height / 2
		var bottom_bound = enemy_position.y + detection_height / 2
		
		# Verificar si el jugador está dentro del área de detección
		if player_position.x > left_bound and player_position.x < right_bound and player_position.y > top_bound and player_position.y < bottom_bound:
			animated_sprite.play("Angry")
			stop = true
			
			# Actualiza la dirección y posición del enemigo según la posición del jugador
			if player_position.x < enemy_position.x:
				animated_sprite.flip_h = true
				animated_sprite.position = Vector2(-10, 0)
				collision_shape.position = Vector2(10, 0)
			else:
				animated_sprite.flip_h = false
				animated_sprite.position = Vector2(10, 0)
				collision_shape.position = Vector2(10, 0)
		else:
			animated_sprite.play("Walk")
			stop = false
