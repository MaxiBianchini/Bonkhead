extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#$AnimatedSprite2D.play("Idle")
	#await (get_tree().create_timer(5).timeout)
	$AnimatedSprite2D.play("Atack")
