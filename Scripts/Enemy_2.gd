extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var area2D = $Area2D
@onready var player = get_node("../Player") # Encuentra al jugador en la escena

# Variables para controlar el movimiento del dron
var movement_velocity: float = 100.0
var patrol_range: float = 200.0
var start_position: Vector2
var follow_player = false
var initial_height
var target_position

func _ready():
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.play("Walk Scan") # Reproduce la animación de caminar por defecto
	
	area2D.connect("body_entered", Callable(self,"_on_body_entered"))
	area2D.connect("body_exited", Callable(self,"_on_body_exited"))
	
	start_position = position
	initial_height = position.y

func _physics_process(delta):
	if follow_player and player.is_alive:
		if (player.position - position).length() > 2.0:
			target_position = (player.position - position).normalized()
			
			if target_position.x < 0:
				animated_sprite.flip_h = true
			elif target_position.x > 0:
				animated_sprite.flip_h = false
			
			position += target_position * 100 * delta

	else:
		# Si el dron ha dejado de seguir al jugador, vuelve a su altura inicial
		if abs(position.y - initial_height) > 1:  # Tolerancia para evitar oscilaciones
			if position.y > initial_height:
				position.y += -100 * delta  # Mover hacia arriba
			else:
				position.y += 100 * delta  # Mover hacia abajo
		
		# Patrullaje horizontal
		if position.x > start_position.x + patrol_range or position.x < start_position.x - patrol_range:
			movement_velocity *= -1  # Cambia de dirección

		position.x += movement_velocity * delta  # Movimiento horizontal
		
		update_sprite_direction()

func update_sprite_direction():
	if movement_velocity < 0: 
		animated_sprite.flip_h = true
	elif movement_velocity > 0:
		animated_sprite.flip_h = false

func _on_body_entered(body):
	if body.is_in_group("Player"):
		animated_sprite.play("Walk")
		follow_player = true


func _on_body_exited(body):
	if body.is_in_group("Player"):
		animated_sprite.play("Walk Scan")
		follow_player = false
