extends CharacterBody2D

# Referencias a nodos
@onready var  area2D = $Area2D
@onready var animated_sprite = $AnimatedSprite2D

@onready var player = get_node("../Player") # Encuentra al jugador en la escena

var detection_width: int = 400
var detection_height: int = 180
var entered_area: bool = false

var lives: int = 3
var is_alive: bool = true


func _ready():
	animated_sprite.play("Idle")
	
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	area2D.connect("body_entered", Callable(self,"_on_body_entered"))
	area2D.connect("body_exited", Callable(self,"_on_body_exited"))


func _physics_process(delta):
	if player and is_alive:
		var enemy_position = position
		var player_position = player.position
		
		# Definir los límites del área de detección
		var left_bound = enemy_position.x - detection_width / 2
		var right_bound = enemy_position.x + detection_width / 2
		var top_bound = enemy_position.y - detection_height / 2
		var bottom_bound = enemy_position.y + detection_height / 2
		
		# Verificar si el jugador está dentro del área de detección
		if player_position.x > left_bound and player_position.x < right_bound and player_position.y > top_bound and player_position.y < bottom_bound:
			entered_area = true
			animated_sprite.play("Atack")
			if player_position.x < enemy_position.x:
				animated_sprite.flip_h = true
				animated_sprite.position = Vector2(-8, 0)
			else:
				animated_sprite.flip_h = false
				animated_sprite.position = Vector2(7, 0)
		elif entered_area:
			entered_area = false
			animated_sprite.play("Idle")


# Controlador del Daño
func take_damage():
	lives -= 1
	if lives == 0:
		is_alive = false
		animated_sprite.play("Death")
	else:
		$AnimationPlayer.play("Hurt")
		await (get_tree().create_timer(3.0).timeout)


func _on_body_entered(body):
	if body.is_in_group("Player"):
		animated_sprite.play("Atack")


func _on_body_exited(body):
	if body.is_in_group("Player"):
		animated_sprite.play("Idle")


func _on_animation_finished():
	if animated_sprite.animation == "Death":
		queue_free()
