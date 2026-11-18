extends CharacterBody2D

@onready var sprite : Sprite2D = $Sprite

@export var move_speed : float = 100
@export var acceleration : float = 50
@export var braking : float = 20
@export var jump_force : float = 200
@export var gravity : float = 980
@export var target : Node2D
var move_input : float

func _process(_delta):
	# flip sprite to face movement direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	
	queue_redraw()
	

func _physics_process(delta: float) -> void:
	# handle movement
	move_input = Input.get_axis("Left", "Right")
	if is_on_floor():
		if move_input != 0:
			velocity.x = lerp(velocity.x, move_input * move_speed,
			acceleration * delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, braking * delta)
	
	# handle jump
	if Input.is_action_pressed("Jump") and is_on_floor():
		velocity.y = -jump_force
	
	## handle pull
	#if Input.is_action_pressed("Pull"):
		#global_position = global_position.move_toward(target.global_position, 200*delta)
	if Input.is_action_pressed("Pull"):
		# Stop moving when very close to prevent jittering
		if global_position.distance_to(target.global_position) > 5.0:
			var direction = global_position.direction_to(target.global_position)
			velocity += direction * 1500 * delta
	
	# handle push
	#if Input.is_action_pressed("Push"):
		#d
	
	# handle gravity
	if not is_on_floor() && !Input.is_action_pressed("Pull"):
		velocity.y += 980 * delta
	
	velocity = velocity.limit_length(600)
	
	move_and_slide()
	

func _draw() -> void:
	if is_instance_valid(target):
		var start := to_local(global_position)
		var end := to_local(target.global_position)
		draw_line(start, end, Color.BLUE, 2.0)
