extends CharacterBody2D

const velocidad = 60.0
const gravedad = 2000
var direccion = 1.0

func _ready():
	$AnimatedSprite2D.play("Walk")

func _physics_process(delta):
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.position = Vector2(-10,0)
		$CollisionShape2D.position = Vector2(10,0)
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.position = Vector2(10,0)
		$CollisionShape2D.position = Vector2(10,0)
	
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	if is_on_wall() or not is_on_floor():
		direccion *= -1
	
	velocity.x = direccion * velocidad
	move_and_slide()
