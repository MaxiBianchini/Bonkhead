extends RigidBody2D

@onready var collapse_timer: Timer = $Timer2
@onready var reset_timer: Timer = $Timer

var player_on_platform: bool = false
var falling: bool = false
var initial_position: Vector2

func _ready() -> void:
	initial_position = position
	gravity_scale = 0

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not falling:
		player_on_platform = true
		if collapse_timer.is_stopped():
			collapse_timer.start()

func start_falling() -> void:
	if player_on_platform:
		gravity_scale = 1
		falling = true
		reset_timer.start()

func reset_platform() -> void:
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	position = initial_position
	falling = false
	player_on_platform = false
