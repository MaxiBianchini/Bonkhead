extends Area2D

func _ready() -> void:
	$Sprite2D.visible = false
	$Label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$Sprite2D.visible = true
		$Label.visible = true



func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$Sprite2D.visible = false
		$Label.visible = false
