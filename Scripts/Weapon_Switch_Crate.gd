extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	print("ENTRO ALGO")
	if body.is_in_group("Player"):  # Verificar si colisionó con un enemigo
		body.change_weapon()  # Función de cambiar arma en el player
		queue_free()  # Eliminar la bala # Replace with function body.
