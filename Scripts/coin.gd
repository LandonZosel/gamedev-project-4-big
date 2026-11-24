extends CharacterBody2D

@export var turn_speed : float = 1
@export var braking : float = 10

#func _process(_delta):
	#

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += 980 * delta
		rotate(turn_speed)
	else:
		if (global_rotation != 0):
			global_rotation = 0
		if (velocity.x != 0):
			velocity.x = lerp(velocity.x, 0.0, braking * delta)
		
	
	move_and_slide()
