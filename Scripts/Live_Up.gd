extends Area2D

@onready var collisionshape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var is_collected: bool = true

func _on_body_entered(body: Node2D) -> void:
	if not is_collected:
		return
	
	if body.name == "Player":
		if body.increase_life() and is_collected:
			is_collected = true
			
			# 3. También deshabilitamos la colisión como buena práctica.
			collisionshape.set_deferred("disabled", true)
			sprite.visible = false
			
			# 4. Ahora el resto de tu lógica se ejecuta de forma 100% segura.
			$AudioStreamPlayer2D.play()
			await $AudioStreamPlayer2D.finished
			queue_free()
