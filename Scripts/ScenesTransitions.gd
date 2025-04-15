extends CanvasLayer

# Variable para indicar si una transición está en curso
var is_transitioning: bool = false

func change_scene(target: String) -> void:
	is_transitioning = true
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(target)
	$AnimationPlayer.play_backwards("fade_in")
	await $AnimationPlayer.animation_finished
	is_transitioning = false
