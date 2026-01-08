extends Area2D

@export var damage_amount: int = 1

# Variable para recordar si el jugador está dentro
var player_inside: Node2D = null

func _ready() -> void:
	# Asegúrate de conectar estas señales en el editor o aquí por código
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	# Si tenemos al jugador registrado dentro del área...
	if player_inside != null:
		# ...intentamos hacerle daño constantemente.
		# No te preocupes, el script del Player rechazará el daño 
		# si la variable 'is_stunned' es verdadera.
		if player_inside.has_method("take_damage"):
			player_inside.take_damage() # Sin argumentos extra (no es muerte forzada)

# --- SEÑALES ---

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Si el jugador sale, dejamos de intentar hacerle daño
		player_inside = null
