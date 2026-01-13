extends Node2D

@onready var Gates: TileMapLayer = $TileMaps/Gates
@onready var GatesArea: Area2D = $GatesArea

func _ready() -> void:
	pass

func _on_gates_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Gates.enabled = true
		#GatesArea.monitoring = false
