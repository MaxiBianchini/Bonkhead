extends Area2D

@export var damage_amount: int = 1

var player_inside: Node2D = null

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if player_inside != null:
		if player_inside.has_method("take_damage"):
			player_inside.take_damage()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = null
