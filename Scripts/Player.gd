# ============================================================================
# SCRIPT DEL JUGADOR (Player.gd)
# Hereda de CharacterBody2D, la clase base de Godot para personajes controlados
# que necesitan interactuar con la física del juego (colisiones, gravedad, etc.).
# ============================================================================
extends CharacterBody2D

# ============================================================================
# SECCIÓN DE REFERENCIAS A NODOS
# Usamos @onready para asegurarnos de que el nodo esté listo en la escena
# antes de asignarlo a la variable. Esto evita errores si el script se carga
# antes que los nodos hijos.
# ============================================================================

# --- Nodos para Animaciones ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Sprite para animaciones principales (correr, saltar).
@onready var animated_sprite2:AnimatedSprite2D = $AnimatedSprite2D2 # Sprite para animaciones de disparo horizontal.
@onready var animated_sprite3:AnimatedSprite2D = $AnimatedSprite2D3 # Sprite para animaciones de disparo hacia arriba.
var animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3] # Array para gestionar los tres sprites a la vez.

# --- Nodos para Físicas y Detección ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D # Define el área de colisión física del jugador.
@onready var raycast_floor: RayCast2D = $RayCast2D2 # Rayo para detectar si hay suelo debajo del jugador.
@onready var raycast_wall: RayCast2D = $RayCast2D # Rayo para detectar paredes a los lados.
@onready var area2D: Area2D = $Area2D # Área para detectar colisiones con otros objetos (ej. enemigos).

# --- Nodos de Audio ---
@onready var audio_dash: AudioStreamPlayer2D = $AudioStream_Dash # Sonido del dash.
@onready var audio_jump: AudioStreamPlayer2D = $AudioStream_Jump # Sonido del salto.
@onready var audio_hurts: AudioStreamPlayer2D = $AudioStream_Hurts # Sonido al recibir daño.
@onready var audio_shoot: AudioStreamPlayer2D = $AudioStream_Shoot # Sonido del disparo.
@onready var audio_landing: AudioStreamPlayer2D = $AudioStream_Landing # Sonido al aterrizar.

# --- Nodo de Animaciones Adicionales ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer # Se usa para animaciones complejas (ej. parpadeo al recibir daño).

# --- Nodos de Temporizadores (Timers) ---
@onready var wall_grab_timer: Timer = $Timer4 # Timer para controlar la duración del agarre en la pared.
@onready var dashing_timer: Timer = $Timer3 # Timer para el cooldown (tiempo de recarga) del dash.
@onready var dash_timer: Timer = $Timer2 # Timer para controlar la duración del dash.
@onready var dead_timer: Timer = $Timer # Timer para esperar tras la animación de muerte antes de notificar al SceneManager.

# ============================================================================
# SECCIÓN DE VARIABLES EXPORTADAS
# @export permite que estas variables se puedan editar directamente desde el
# Inspector de Godot, facilitando el ajuste de la jugabilidad sin tocar el código.
# ============================================================================
@export var wall_slide_speed: float = 12.5 # Velocidad de deslizamiento al estar agarrado a una pared.
@export var wall_jump_force: float = -150 # Fuerza del salto desde una pared.

# ============================================================================
# SECCIÓN DE SEÑALES
# Las señales permiten que este nodo se comunique con otros nodos (como el
# SceneManager o la GUI) de forma desacoplada.
# ============================================================================
signal player_died # Se emite cuando el jugador muere definitivamente.
signal change_UI_lives(change_lives) # Se emite para pedirle a la GUI que actualice los corazones de vida.

# ============================================================================
# SECCIÓN DE VARIABLES DE ESTADO Y FÍSICA
# Aquí se definen todas las propiedades que controlan el comportamiento,
# la física y el estado actual del jugador.
# ============================================================================

# --- Variables de Física y Movimiento ---
var gravity: int = 2000 # Fuerza de gravedad que afecta al jugador.
var jump_force: float = -550 # Impulso inicial del salto.
var jump_cut_multiplier: float = 0.5 # Modificador para acortar el salto si se suelta el botón.
var player_dir: String = "RIGHT" # Dirección a la que mira el jugador ("LEFT" o "RIGHT").
var dash_velocity: int = 400 # Velocidad del jugador durante el dash.
var movement_velocity: int = 250 # Velocidad normal de movimiento.
var fall_through_time: float = 0.05 # Pequeño retraso para atravesar plataformas.

# --- Variables de Estado (Booleanas) ---
var was_in_air: bool = false # Registra si el jugador estaba en el aire en el fotograma anterior (para el sonido de aterrizaje).
var can_dash: bool = false # Indica si la habilidad de dash está desbloqueada.
var is_dashing: bool = false # Indica si el jugador está actualmente ejecutando un dash.
var double_jump_enabled: bool = false # Indica si las condiciones para un doble salto se cumplen.
var first_jump_completed: bool = false # Registra si ya se realizó el primer salto.
var has_used_wall_grab: bool = false # Registra si ya se usó el agarre en el aire actual.
var wall_grab_duration: float = 0.2 # Tiempo en segundos que puede estar agarrado
var is_alive: bool = true # Estado de vida del jugador.

# --- Variables de Combate ---
var lives: int = 5 # Vidas actuales dentro del "paquete de vidas".
var bullet_scene = preload("res://Prefabs/Bullet.tscn") # Precarga la escena de la bala para poder crearla después.
var bullet_dir: Vector2 = Vector2.RIGHT # Dirección actual del disparo.
var bullet_offset: Vector2 # Desplazamiento desde el centro del jugador donde se crea la bala.
var gun_type: String ="Small" # Tipo de arma equipada.
var current_state: String = "" # Estado actual de la animación (ej. "Idle", "Run", "Jump").
var change_gun_type: bool = false # Bandera para controlar el cambio de arma.
var hurt_jump_force: float = -200 # Pequeño salto hacia atrás al recibir daño.

# --- Variables de Progresión ---
var current_level: int # Nivel actual del juego, obtenido del SceneManager.
var can_wall_grab: bool = false # Indica si la habilidad de agarre en pared está desbloqueada.
var is_wall_grabbing: bool = false # Indica si el jugador está actualmente agarrado a una pared.

# ============================================================================
# FUNCIONES INTEGRADAS DE GODOT
# ============================================================================

# La función _ready() se ejecuta una sola vez cuando el nodo entra en la escena.
# Es ideal para inicializar variables y configurar el nodo.
func _ready() -> void:
	# Configura la duración del temporizador de agarre en pared.
	wall_grab_timer.wait_time = wall_grab_duration
	# Obtiene el nivel actual desde el SceneManager para desbloquear habilidades.
	current_level = SceneManager.current_level
	
	# Desbloquea el dash si el jugador está en el nivel 3 o superior.
	if current_level >= 3:
		can_dash = true
	# Desbloquea el agarre en pared si está en el nivel 1 o superior (ajustado para pruebas).
	if current_level >= 1:
		can_wall_grab = true

# La función _physics_process(delta) se ejecuta en cada fotograma de física.
# Es el lugar principal para toda la lógica de movimiento y control del jugador.
func _physics_process(delta) -> void:
	if is_alive:
		# Captura la entrada del jugador (izquierda/derecha).
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
		# --- LÓGICA DE AGARRE EN PARED ---
		# Comprueba si hay una pared al lado.
		var on_wall = raycast_wall.is_colliding()
		# Comprueba si el jugador se está moviendo hacia la pared.
		var is_moving_towards_wall = (player_dir == "RIGHT" and input_vector.x > 0) or (player_dir == "LEFT" and input_vector.x < 0)

		# Condiciones para iniciar el agarre: tener la habilidad, estar en el aire, moverse hacia la pared.
		if can_wall_grab and not is_on_floor() and on_wall and is_moving_towards_wall:
			wall_grab_timer.start()
			is_wall_grabbing = true
		else:
			is_wall_grabbing = false

		# --- Lógica de Estado: Agarrado a la Pared vs. Movimiento Normal ---
		if is_wall_grabbing:
			# Se reduce la velocidad de caída para simular un deslizamiento.
			velocity.y = min(velocity.y + (gravity * 0.5 * delta), wall_slide_speed)
			
			# Lógica del Salto de Pared (Wall Jump).
			if Input.is_action_just_pressed("ui_jump"):
				# Se aplica un impulso hacia arriba.
				velocity.y = wall_jump_force
				# Se desactiva el agarre al saltar.
				is_wall_grabbing = false
		else:
			# --- FÍSICAS NORMALES ---
			# Se aplica la gravedad estándar.
			velocity.y += gravity * delta
			
			# Lógica del Dash.
			if Input.is_action_just_pressed("Dash") and can_dash:
				audio_dash.play()
				can_dash = false
				is_dashing = true
				animated_sprite.stop()
				animated_sprite.play("Dash")
				current_state = "Dash"
				dashing_timer.start()
				dash_timer.start()

			# Se aplica la velocidad de movimiento (normal o de dash).
			velocity.x = input_vector.x * (dash_velocity if is_dashing else movement_velocity)

			# Lógica de Salto (con todas sus variantes).
			if Input.is_action_just_pressed("ui_jump"):
				# Si se presiona "abajo + salto" en una plataforma, se atraviesa hacia abajo.
				if Input.is_action_pressed("ui_down") && raycast_floor.is_colliding():
					var collider = raycast_floor.get_collider()
					if collider.is_in_group("Platform"):
						ignore_platform_collision()
				# Salto normal desde el suelo.
				elif is_on_floor():
					audio_jump.play()
					first_jump_completed = true
					velocity.y = jump_force
					match gun_type:
						"Small":
							animated_sprite.play("SJump")
						"Big":
							animated_sprite.play("BJump")
					current_state = "Jump"
					switch_animation(1)
				# Doble salto si está habilitado y ya se hizo el primer salto.
				elif double_jump_enabled and first_jump_completed:
					first_jump_completed = false
					velocity.y = jump_force
					animated_sprite.play("Double_Jump")
					current_state = "Double_Jump"
					switch_animation(1)
			
			# Lógica para acortar el salto si se suelta el botón.
			if Input.is_action_just_released("ui_jump") and velocity.y < 0:
				velocity.y *= jump_cut_multiplier
		
		# Lógica de aterrizaje (para el sonido).
		if !is_on_floor() and velocity.y > 0:
			was_in_air = true
		elif raycast_floor.is_colliding() and was_in_air:
			audio_jump.stop()
			audio_landing.play()
			was_in_air = false
		
		# Lógica de disparo.
		if Input.is_action_just_pressed("Shoot"):
			audio_shoot.play()
			shoot_bullet()
	else:
		# Si el jugador no está vivo, no tiene control y solo le afecta la gravedad.
		velocity.x = 0
		velocity.y += gravity * delta
	
	# Aplica el vector de velocidad al personaje para moverlo y gestionar colisiones.
	move_and_slide()
	
	# Actualiza la parte visual y otros estados después del movimiento.
	if is_alive:
		update_sprite_direction()
		update_animation()
	handle_double_jump()

# ============================================================================
# FUNCIONES PERSONALIZADAS
# ============================================================================

# Gestiona la orientación visual del jugador y la posición de sus componentes.
func update_sprite_direction() -> void:
	var offset = 10
	# Si la velocidad es negativa, mira a la izquierda.
	if velocity.x < 0:
		animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3]
		# Voltea todos los sprites.
		for s in animated_sprites:
			s.position.x = -offset
			s.flip_h = true
		
		player_dir = "LEFT"
		# Ajusta la posición de los detectores y colisiones para que coincidan con la nueva dirección.
		bullet_offset = Vector2(-15, -9)
		bullet_dir = Vector2.LEFT
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = -offset
		raycast_floor.position.x = offset
		collision_shape.position.x = offset
		area2D.position.x = offset
	
	# Si la velocidad es positiva, mira a la derecha.
	elif velocity.x > 0:
		animated_sprites = [animated_sprite, animated_sprite2, animated_sprite3]
		for s in animated_sprites:
			s.position.x = offset
			s.flip_h = false
		
		player_dir = "RIGHT"
		bullet_offset = Vector2(35, -9)
		bullet_dir = Vector2.RIGHT
		raycast_wall.position.x = offset
		raycast_wall.target_position.x = offset
		raycast_floor.position.x = offset
		collision_shape.position.x = offset
		area2D.position.x = offset

# Elige la animación correcta según el estado actual del jugador.
func update_animation() -> void:
	if not is_alive:
		return
	
	# Animación prioritaria: si está agarrado a la pared.
	if is_wall_grabbing:
		#animated_sprite.play("WallGrab") # (Necesitas crear una animación con este nombre)
		return # Se detiene aquí para que esta animación no sea sobreescrita.

	# Si no está recibiendo daño.
	if animated_sprite.animation != "Hurt" and lives != 0:
		# Animación de caída.
		if not is_on_floor() and velocity.y > 250:
			match gun_type:
				"Small":
					animated_sprite.play("SFall")
				"Big":
					animated_sprite.play("BFall")
			current_state = "Fall"
			switch_animation(1)
		
		# Animación de estar quieto (Idle).
		elif velocity.x == 0 and velocity.y == 0:
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					animator_controller("Idle", 3)
					bullet_dir = Vector2.UP
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(12, -25)
						"LEFT":
							bullet_offset = Vector2(10, -25)
				else:
					animator_controller("Idle", 2)
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(35, -9)
							bullet_dir = Vector2.RIGHT
						"LEFT":
							bullet_offset = Vector2(-15, -9)
							bullet_dir = Vector2.LEFT
			else:
				animator_controller("Idle", 1)
				
		# Animación de correr.
		elif is_on_floor() and not is_dashing and (
			Input.get_action_strength("ui_left") or Input.get_action_strength("ui_right")
			):
			if Input.is_action_pressed("Shoot"):
				if Input.is_action_pressed("ui_up"):
					animator_controller("Run", 3)
					bullet_dir = Vector2.UP
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(25, -25)
						"LEFT":
							bullet_offset = Vector2(-5, -25)
				else:
					animator_controller("Run", 2)
					match player_dir:
						"RIGHT":
							bullet_offset = Vector2(60, -9)
							bullet_dir = Vector2.RIGHT
						"LEFT":
							bullet_offset = Vector2(-40, -9)
							bullet_dir = Vector2.LEFT
			else:
				animator_controller("Run", 1)

# Controlador principal que elige la animación base (Idle, Run) y el tipo de arma.
func animator_controller(state_trigger: String, animation_number: int) -> void:
	if current_state != state_trigger or gun_type:
		change_gun_type = false
		match state_trigger:
			"Idle":
				match gun_type:
					"Small":
						animated_sprite.play("SIdle with Gun")
						animated_sprite2.play("SIdle Shooting Rect")
						animated_sprite3.play("SIdle Shooting Up")
					"Big":
						animated_sprite.play("BIdle with Gun")
						animated_sprite2.play("BIdle Shooting Rect")
						animated_sprite3.play("BIdle Shooting Up")
			
			"Run":
				match gun_type:
					"Small":
						animated_sprite.play("SRun with Gun")
						animated_sprite2.play("SRun Shooting Rect")
						animated_sprite3.play("SRun Shooting Up")
					"Big":
						animated_sprite.play("BRun with Gun")
						animated_sprite2.play("BRun Shooting Rect")
						animated_sprite3.play("BRun Shooting Up")
		
		current_state = state_trigger
	
	switch_animation(animation_number)

# Activa el sprite correcto para la animación deseada y oculta los demás.
func switch_animation(animation_number: int) -> void:
	hide_all_sprites()
	match animation_number:
		1:
			animated_sprite.visible = true
		2:
			animated_sprite2.visible = true
		3:
			animated_sprite3.visible = true

# Función de ayuda para ocultar todos los sprites.
func hide_all_sprites() -> void:
	animated_sprite.visible = false
	animated_sprite2.visible = false
	animated_sprite3.visible = false

# Gestiona si el doble salto está disponible.
func handle_double_jump() -> void:
	if current_level < 2:
		return
		
	if raycast_wall.is_colliding():
		var collider = raycast_wall.get_collider()
		if collider.is_in_group("Wall"):
			double_jump_enabled = true
		if collider.is_in_group("Floor"):
			double_jump_enabled = false
	else:
		double_jump_enabled = false

# Crea una instancia de la bala y la añade a la escena.
func shoot_bullet() -> void:
	update_animation()
	
	var bullet = bullet_scene.instantiate() as Area2D
	bullet.mask = 3
	bullet.shooter = self
	
	bullet.change_bullet_speed(245)
	bullet.change_bullet_acceleration(300)  
	bullet.change_bullet_lifetime(0.7)   
	
	bullet.position = position + bullet_offset
	bullet.direction = bullet_dir
	
	get_tree().current_scene.add_child(bullet)

# Permite al jugador atravesar plataformas.
func ignore_platform_collision() -> void:
	collision_shape.disabled = true
	velocity.y = jump_force * -1.5
	await (get_tree().create_timer(fall_through_time).timeout)
	collision_shape.disabled = false

# Cambia el tipo de arma.
func change_weapon() -> void:
	if gun_type == "Small":
		gun_type = "Big"
	else:
		gun_type = "Small"
	change_gun_type = true

# Procesa el evento de recibir daño.
func take_damage() -> void:
	if is_alive:
		audio_hurts.play()
		lives -= 1
		emit_signal("change_UI_lives", lives)
		if lives <= 0:
			is_alive = false
			# La animación de muerte ahora se maneja en update_animation para evitar conflictos
			current_state = "Death"
			animated_sprite.play("Death")
			animated_sprite2.play("Death")
			animated_sprite3.play("Death")
			
			call_deferred("disable_player_collision")
			dead_timer.start()
			
		else:
			animation_player.play("Hurt")
			velocity.y = hurt_jump_force

# Permite al jugador recuperar vidas.
func increase_life() -> bool:
	if lives < 5: # Ahora el máximo es 5
		lives += 1
		emit_signal("change_UI_lives", lives)
		return true
	else:
		return false

# Desactiva las colisiones del jugador.
func disable_player_collision() -> void:
	area2D.set_collision_mask_value(3,false)
	area2D.set_collision_mask_value(4,false)
	area2D.set_collision_mask_value(5,false)

# ============================================================================
# FUNCIONES CONECTADAS A SEÑALES (_on_...)
# Estas funciones se ejecutan automáticamente cuando un nodo emite una señal
# que ha sido conectada a ellas en el editor de Godot.
# ============================================================================

# Se ejecuta cuando el Area2D del jugador entra en contacto con otro cuerpo.
func _on_body_entered(body) -> void:
	if body.is_in_group("Enemy") and body.is_alive:
		take_damage()

# Se ejecuta cuando el temporizador del dash termina.
func _on_dash_timer_timeout() -> void:
	is_dashing = false

# Se ejecuta cuando el cooldown del dash termina.
func _on_can_dash_timeout() -> void:
	can_dash = true

# Se ejecuta después de la animación de muerte.
func _on_dead_timer_timeout() -> void:
	player_died.emit()

# Se ejecuta cuando el jugador entra en un área (ej. zona de muerte).
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Dead"):
		lives = 0
		take_damage()

# Se ejecuta cuando se agota el tiempo de agarre en la pared.
func _on_wall_grab_timer_timeout() -> void:
	# El tiempo se acabó, forzamos al jugador a soltarse de la pared.
	is_wall_grabbing = false
