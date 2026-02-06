extends Area2D

@export var grants_ammo: Player.AmmoType

@onready var sprite: Sprite2D = $Sprite2D

@export var tex_normal: Texture2D
@export var tex_piercing: Texture2D
@export var tex_mortar: Texture2D
@export var tex_burst: Texture2D

func _ready() -> void:
	match grants_ammo:
		Player.AmmoType.NORMAL: 
			sprite.texture = tex_normal
		Player.AmmoType.MORTAR: 
			sprite.texture = tex_mortar
		Player.AmmoType.PIERCING: 
			sprite.texture = tex_piercing
		Player.AmmoType.BURST: 
			sprite.texture = tex_burst
	
func _on_body_entered(body: Node2D) -> void:
	# Comprobamos si el cuerpo que entró en nuestra área es el jugador.
	if body.is_in_group("Player"):
		# Le pedimos al jugador que cambie su tipo de munición.
		body.set_ammo_type(grants_ammo)
		# (Opcional) Aquí podríamos reproducir un sonido de "ítem recogido".
		
		# El ítem se autodestruye después de ser recogido.
		queue_free()
