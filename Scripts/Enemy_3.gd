extends CharacterBody2D

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var raycast_detection = $RayCast2D
@onready var raycast_floor = $RayCast2D2

# Variables para controlar el movimiento del dron
var movement_velocity: float = 250
var start_driving: bool = false

# Variables para controlar la vida
var lives: int = 3
var is_alive: bool = true

func _ready():
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.play("Idle") # Reproduce la animación de caminar por defecto

func _physics_process(delta):
	if is_on_wall() or not raycast_floor.is_colliding():
		movement_velocity *= -1
		update_sprite_direction() # Actualizar la dirección del sprite
	
	if raycast_detection.is_colliding():
		var collider = raycast_detection.get_collider()
		if collider.is_in_group("Player"):
			animated_sprite.play("Walk")
			start_driving = true
	
	if start_driving:
		# Movimiento horizontal del dron
		position.x += movement_velocity  * delta


# Controlador de la direccion del Sprite
func update_sprite_direction():
	if movement_velocity < 0:
		animated_sprite.flip_h = true
		raycast_floor.position = Vector2(-40,27.5)
		raycast_detection.rotate(-3.14159)
	elif movement_velocity > 0:
		animated_sprite.flip_h = false
		raycast_floor.position = Vector2(40,27.5)
		raycast_detection.rotate(3.14159)


# Controlador del Daño
func take_damage():
	lives -= 1
	if lives == 0:
		is_alive = false
		animated_sprite.play("Death")
	else:
		$AnimationPlayer.play("Hurt")
		await (get_tree().create_timer(3.0).timeout)
		animated_sprite.play("Idle")


func _on_animation_finished():
	if animated_sprite.animation == "Death":
		queue_free()
