extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if body.increase_life():
			$AudioStreamPlayer2D.play()
			queue_free()
