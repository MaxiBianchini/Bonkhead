extends CharacterBody2D

@onready var  area2D = $Area2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_node("../Player") # Encuentra al jugador en la escena

var detection_width = 200
var detection_height = 200
var entered_area = false
# Called when the node enters the scene tree for the first time.
func _ready():
	animated_sprite.play("Idle")
	
	area2D.connect("body_entered", Callable(self,"_on_body_entered"))
	area2D.connect("body_exited", Callable(self,"_on_body_exited"))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
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
			print("ENTRRO")
			entered_area = true
			animated_sprite.play("Atack")
			if player_position.x < enemy_position.x:
				animated_sprite.flip_h = true
				animated_sprite.position = Vector2(5, 0)
			else:
				animated_sprite.flip_h = false
				animated_sprite.position = Vector2(5, 0)
		elif entered_area:
			entered_area = false
			print("SALIO")
			animated_sprite.play("Idle")
			
func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("ENTRRO")
		animated_sprite.play("Atack")
		

func _on_body_exited(body):
	if body.is_in_group("Player"):
		print("SALIO")
		animated_sprite.play("Idle")
