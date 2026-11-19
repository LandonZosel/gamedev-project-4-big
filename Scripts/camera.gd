extends Camera2D

@export var player : CharacterBody2D

func _process(delta: float) -> void:
	global_position = global_position.lerp(player.global_position, 7.0 * delta)
