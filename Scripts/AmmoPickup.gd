extends Area2D

## Esta variable nos permitirá elegir qué tipo de munición otorga este ítem
## desde el editor de Godot.
@export var grants_ammo: Player.AmmoType = Player.AmmoType.MORTAR

func _on_body_entered(body: Node2D) -> void:
	# Comprobamos si el cuerpo que entró en nuestra área es el jugador.
	if body.is_in_group("Player"):
		# Le pedimos al jugador que cambie su tipo de munición.
		body.set_ammo_type(grants_ammo)
		
		# (Opcional) Aquí podríamos reproducir un sonido de "ítem recogido".
		
		# El ítem se autodestruye después de ser recogido.
		queue_free()
