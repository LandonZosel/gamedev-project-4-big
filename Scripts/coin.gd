extends CharacterBody2D

@export var turn_speed : float = 0.5
@export var braking : float = 10

const State = Enums.State

var current_state : State

func _process(_delta):
	if current_state == State.Moving:
		rotation = Vector2.RIGHT.angle_to(velocity)
	elif current_state == State.Anchoring:
		global_rotation = 0
	elif current_state == State.Holding:
		look_at(get_global_mouse_position())
	

func _physics_process(delta: float) -> void:
	if current_state == State.None:
		if not is_on_floor():
			# Add the gravity.
			velocity.y += 980 * delta
			rotate(turn_speed)
		else:
			# On floor, set flat and apply friction
			if (global_rotation != 0):
				global_rotation = 0
			if (velocity.x != 0):
				velocity.x = lerp(velocity.x, 0.0, braking * delta)
	
	velocity = velocity.limit_length(500)
	
	move_and_slide()
	

func set_state(state: State):
	current_state = state
