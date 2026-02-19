extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var singpost: Sprite2D = $Sprite2D
@export var flip: bool = false

var is_activated: bool = false

func _ready() -> void:
	animated_sprite.flip_h = flip
	
	if SceneManager.has_active_checkpoint:
		if global_position.distance_squared_to(SceneManager.active_checkpoint_pos) < 100:
			is_activated = true
			singpost.visible = true
			animated_sprite.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_activated:
		activate_me()

func activate_me():
	singpost.visible = true
	is_activated = true
	animated_sprite.play("default")
	
	SceneManager.activate_checkpoint(global_position, SceneManager.points)
