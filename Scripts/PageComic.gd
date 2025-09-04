extends Area2D

signal winLevel

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("winLevel")
		queue_free()
