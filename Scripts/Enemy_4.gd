extends CharacterBody2D

@onready var area2d: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var can_shoot_timer: Timer = $Can_Shoot
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var player = get_node("../Player")  # Ajustar el tipo si lo deseas, por ejemplo (Player)

var bullet_scene: PackedScene = preload("res://Prefabs/Bullet_1.tscn")

var detection_width: float = 10000.0
var detection_height: float = 180.0
var can_shoot: bool = false

var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_offset: Vector2 = Vector2(-15, 5)

var lives: int = 3
var is_alive: bool = true

func _ready() -> void:
	animated_sprite.play("Idle")
	
	# Conectar señales
	animated_sprite.animation_finished.connect(_on_animation_finished)
	area2d.body_entered.connect(_on_body_entered)
	area2d.body_exited.connect(_on_body_exited)
	can_shoot_timer.timeout.connect(_on_can_shoot_timeout)


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
	if can_shoot:
		shoot_bullet()
		can_shoot = false
		can_shoot_timer.start()


func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir  # Asegúrate de que la bala tenga una variable 'direction'
	get_tree().current_scene.add_child(bullet)


func take_damage() -> void:
	lives -= 1
	if lives <= 0:
		is_alive = false
		animated_sprite.play("Death")
	else:
		anim_player.play("Hurt")
		await get_tree().create_timer(3.0).timeout  # Pausa de 3 segundos antes de volver a la normalidad


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		animated_sprite.play("Atack")
		can_shoot = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		animated_sprite.play("Idle")
		can_shoot = false


func _on_animation_finished() -> void:
	if animated_sprite.animation == "Death":
		queue_free()


func _on_can_shoot_timeout() -> void:
	can_shoot = true
