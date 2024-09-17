extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var area2D = $Area2D

# Variables para controlar el movimiento del dron
var movement_velocity: float = 100.0
var patrol_range: float = 200.0
var start_position: Vector2

func _ready():
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.play("Walk") # Reproduce la animación de caminar por defecto
	
	area2D.connect("body_entered", Callable(self,"_on_body_entered"))
	
	start_position = position

func _physics_process(delta):
	# Movimiento horizontal del dron
	position.x += movement_velocity * delta

	# Control simple de patrullaje (si quieres que vaya de un lado a otro)
	if position.x > start_position.x + patrol_range or position.x < start_position.x - patrol_range:
		movement_velocity *= -1  # Cambia de dirección
		
	update_sprite_direction()

func update_sprite_direction():
	if movement_velocity < 0:
		animated_sprite.flip_h = true
		
	elif movement_velocity > 0:
		animated_sprite.flip_h = false

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("Detecto l player")
