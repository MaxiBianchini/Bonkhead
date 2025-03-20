extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var area2d: Area2D = $Area2D

@onready var player = get_tree().current_scene.get_node_or_null("%Player") # Encuentra al jugador en la escena

var bullet_scene: PackedScene = preload("res://Prefabs/Bullet_1.tscn")

var detection_width: float = 10000.0
var detection_height: float = 180.0
var can_shoot: bool = false
var shoot_now: bool = true

var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2 = Vector2(-15, 5)

var lives: int = 3
var is_alive: bool = true

signal add_points
var points = 25

func _ready() -> void:
	animated_sprite.play("Idle")
	
	# Conectar señales
	animated_sprite.animation_finished.connect(_on_animation_finished)
	


func _physics_process(delta: float) -> void:
	if not (player and is_alive):
		return
	
	# Creamos un rectángulo centrado en la posición del enemigo con el tamaño deseado
	var detection_rect = Rect2(
		position - Vector2(detection_width * 0.5, detection_height * 0.5),
		Vector2(detection_width, detection_height)
	)
	
	# Comprobamos si el jugador está dentro del área de detección
	if detection_rect.has_point(player.position):
		# Ajustamos flip y offsets según la posición del jugador
		if player.position.x < position.x:
			animated_sprite.flip_h = true
			animated_sprite.position = Vector2(-8, 0)
			bullet_offset = Vector2(-25, 5)
			bullet_dir = Vector2.LEFT
		else:
			animated_sprite.flip_h = false
			animated_sprite.position = Vector2(7, 0)
			bullet_offset = Vector2(25, 5)
			bullet_dir = Vector2.RIGHT
	
	# Si está listo para disparar, realizamos el disparo
	if can_shoot and player.is_alive:
		if shoot_now:
			shoot_bullet()
			shoot_now = false
			await get_tree().create_timer(0.75).timeout  # Pausa de 3 segundos antes de volver a la normalidad
			shoot_now = true


func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.mask = 2
	# Le indicamos quién la disparó:
	bullet.shooter = self
	
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir  # Asegúrate de que la bala tenga una variable 'direction'
	get_tree().current_scene.add_child(bullet)


func take_damage() -> void:
	if is_alive:
		anim_player.play("Hurt")
		lives -= 1
		emit_signal("add_points", points)  # Enviar la señal a la UI
		if lives == 0:
			is_alive = false
			animated_sprite.play("Death")
	

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		animated_sprite.play("Atack")
		can_shoot = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and is_alive:
		animated_sprite.play("Idle")
		can_shoot = false


func _on_animation_finished() -> void:
	if animated_sprite.animation == "Death":
		queue_free()
