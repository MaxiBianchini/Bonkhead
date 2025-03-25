extends RigidBody2D

# Variables
var player_on_platform := false
var falling := false
var collapse_timer: Timer = null

# Referencias a nodos (asegúrate de que coincidan con los nombres en tu escena)
@onready var area_2d = $Area2D

func _ready() -> void:
	# Asegurarse de que la gravedad esté desactivada inicialmente
	gravity_scale = 0

func _on_body_entered(body: Node) -> void:
	# Verificar si el cuerpo que entró es el jugador
	if body.name == "Player":
		player_on_platform = true
		# Crear e iniciar el temporizador si no existe
		if collapse_timer == null:
			collapse_timer = Timer.new()
			collapse_timer.wait_time = 2.0  # 2 segundos antes de colapsar
			collapse_timer.one_shot = true
			collapse_timer.timeout.connect(_start_falling)
			add_child(collapse_timer)
			collapse_timer.start()

func _on_body_exited(body: Node) -> void:
	# Verificar si el cuerpo que salió es el jugador
	if body.name == "Player":
		player_on_platform = false
		# Detener y eliminar el temporizador si el jugador sale
		if collapse_timer != null:
			collapse_timer.stop()
			collapse_timer.queue_free()
			collapse_timer = null

func _start_falling() -> void:
	# Solo iniciar el colapso si el jugador sigue en la plataforma
	if player_on_platform:
		gravity_scale = 1  # Activar la gravedad para que caiga
		falling = true

func _physics_process(delta: float) -> void:
	# Si la plataforma está cayendo, verificar colisión con el suelo
	if falling:
		for body in get_colliding_bodies():
			if body.is_in_group("Floor") and linear_velocity.length() < 0.1:
				# Eliminar la plataforma cuando toca el suelo y se detiene
				queue_free()
				break
