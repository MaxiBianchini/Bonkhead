extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	sprite.visible = false
	label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		sprite.visible = true
		label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		sprite.visible = false
		label.visible = false
