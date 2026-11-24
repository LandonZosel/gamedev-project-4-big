extends CharacterBody2D

@onready var body_sprite : Sprite2D = $Body
@onready var arm_sprite : Sprite2D = $Arm
@onready var anim_player : AnimationPlayer = $AnimationPlayer

@export var move_speed : float = 120
@export var air_move_speed : float = 20
@export var acceleration : float = 50
@export var braking : float = 15
@export var jump_force : float = 300
@export var shoot_speed : float = 600
@export var gravity : float = 980

var move_input : float
var targets : Array[Node2D] = []
var shot_coins : Array[CharacterBody2D] = []
var current_target : Node2D = null
var priority_action : Action
var jump_started : bool = false
var fall_started : bool = false
var land_started : bool = true
var previously_falling : bool = false

const coin_scene = preload("res://Scenes/coin.tscn")

enum Action {Pull, Push}

func _process(_delta):
	# flip sprite to face movement direction
	if velocity.x != 0:
		body_sprite.flip_h = velocity.x < 0
		if velocity.x < 0:
			arm_sprite.position.x = -5
			arm_sprite.scale.x = -1
		else:
			arm_sprite.position.x = 5
			arm_sprite.scale.x = 1
	
	
	if Input.is_action_pressed("Pull") && current_target && priority_action == Action.Pull:
		arm_sprite.look_at(current_target.global_position)
	elif Input.is_action_pressed("Push") && current_target && priority_action == Action.Push:
		arm_sprite.look_at(current_target.global_position)
	else:
		arm_sprite.look_at(get_global_mouse_position())
	arm_sprite.rotation += deg_to_rad(270)
	
	if jump_started:
		if velocity.y >= 0:
			jump_started = false
	
	if fall_started:
		if velocity.y < 0:
			fall_started = false
	
	
	queue_redraw()
	_manage_animation()
	

func _physics_process(delta: float) -> void:
	# handle jump
	if Input.is_action_pressed("Jump") and is_on_floor():
		velocity.y = -jump_force
	
	# set current target
	if (!Input.is_action_pressed("Pull") || priority_action != Action.Pull) && (!Input.is_action_pressed("Push") || priority_action != Action.Push):
		current_target = _get_best_target()
	
	# set priority
	if Input.is_action_just_pressed("Pull"):
		priority_action = Action.Pull
	if Input.is_action_just_pressed("Push"):
		priority_action = Action.Push
	
	move_input = Input.get_axis("Left", "Right")
	
	if is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, braking * delta)
	
	var moving_self = true
	
	#handle pull, push, and regular movement
	if Input.is_action_pressed("Pull") && current_target && priority_action == Action.Pull:
		# handle pull
		var distance = global_position.distance_to(current_target.global_position)
		if distance < 5 && current_target is CharacterBody2D:
			current_target.velocity = Vector2.ZERO
		elif distance < 500:
			distance -= 100
			var distance_mult = 1 - (distance / 400)
			var direction = global_position.direction_to(current_target.global_position)
			if current_target is CharacterBody2D:
				moving_self = _colliding_with_wall(current_target.velocity - direction * 1500 * distance_mult * delta, delta, current_target)
				if moving_self:
					velocity += direction * 1500 * distance_mult * delta
				else:
					current_target.velocity -= direction * 1500 * distance_mult * delta
			else:
				velocity += direction * 1500 * distance_mult * delta
	elif Input.is_action_pressed("Push") && current_target && priority_action == Action.Push:
		# handle push
		var distance = global_position.distance_to(current_target.global_position)
		if distance < 500:
			distance -= 100
			var distance_mult = 1 - (distance / 400)
			var direction = global_position.direction_to(current_target.global_position)
			if current_target is CharacterBody2D:
				moving_self = _colliding_with_wall(current_target.velocity + direction * 1500 * distance_mult * delta, delta, current_target)
				if moving_self:
					velocity -= direction * 1500 * distance_mult * delta
				else:
					current_target.velocity += direction * 1500 * distance_mult * delta
			else:
				velocity -= direction * 1500 * distance_mult * delta
	else:
		# handle movement
		if is_on_floor():
			if move_input != 0:
				velocity.x = lerp(velocity.x, move_input * move_speed, acceleration * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, braking * delta)
			
		elif ((velocity.x > move_input * move_speed && move_input == -1) || (velocity.x < move_input * move_speed && move_input == 1)):
			velocity.x += move_input * move_speed * 0.1
	
	velocity = velocity.limit_length(500)
	
	# handle gravity
	if not is_on_floor() && ((!Input.is_action_pressed("Pull") || priority_action != Action.Pull) || !current_target || !moving_self) && ((!Input.is_action_pressed("Push") || priority_action != Action.Push) || !current_target || !moving_self):
		velocity.y += 980 * delta
	
	# handle shoot coin
	if Input.is_action_just_pressed("Shoot"):
		_shoot_coin();
	
	move_and_slide()
	

func _manage_animation():
	if !is_on_floor():
		if velocity.y < 0:
			if previously_falling && !jump_started:
				anim_player.play("start_jump_from_fall")
			elif !jump_started:
				anim_player.play("start_jump")
			else:
				anim_player.play("jump")
		else:
			if !fall_started:
				anim_player.play("start_fall")
			else:
				anim_player.play("fall")
	else:
		if !land_started:
			anim_player.play("land")
		elif move_input != 0:
			anim_player.play("walk")
		else:
			anim_player.play("idle")
	

func _draw() -> void:
	for target in targets:
		var start := to_local(global_position)
		var end := to_local(target.global_position)
		var distance = global_position.distance_to(target.global_position)
		
		var color
		if target == current_target:
			var transparency : float = 1 - ((distance-280)/20)
			transparency = clampf(transparency, 0.1, 0.5)
			color = Color(1, 1, 1, transparency) #0.5
			if Input.is_action_pressed("Pull") && priority_action == Action.Pull:
				color = Color(0, 0, 1, transparency)
			elif Input.is_action_pressed("Push") && priority_action == Action.Push:
				color = Color(1, 0.5, 0, transparency)
		else:
			var transparency : float = 1 - (distance/300)
			transparency = clampf(transparency, 0, 0.1)
			color = Color(1, 1, 1, transparency) #0.1
		
		draw_line(start, end, color, 1.5)

func _get_best_target():
	var best_target = null
	var best_alignment = -1
	var mouse_position = get_global_mouse_position()
	var mouse_dir_from_player = (mouse_position - global_position).normalized()
	for target in targets:
		var target_dir_from_player = (target.global_position - global_position).normalized()
		var alignment = mouse_dir_from_player.dot(target_dir_from_player)
		if best_target == null || alignment > best_alignment:
			best_target = target
			best_alignment = alignment
	return best_target

func _colliding_with_wall(test_velocity: Vector2, delta: float, target: CharacterBody2D) -> bool:
	var motion := test_velocity * delta
	var collision := target.move_and_collide(motion, true)
	
	if collision == null:
		return false
	else:
		return true

func _shoot_coin():
	# spawn coin
	var coin = coin_scene.instantiate()
	if (shot_coins.size() < 3):
		shot_coins.append(coin)
	else:
		var coin_to_remove = shot_coins.pop_at(0)
		coin_to_remove.queue_free()
		shot_coins.append(coin)
	coin.global_position = global_position
	var mouse_position = get_global_mouse_position()
	var mouse_dir_from_player = (mouse_position - global_position).normalized()
	coin.velocity = mouse_dir_from_player * shoot_speed
	get_tree().current_scene.add_child(coin)

func _on_detection_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if (parent is CharacterBody2D):
		targets.append(parent)
	else:
		targets.append(area)

func _on_detection_hitbox_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if (parent is CharacterBody2D):
		targets.erase(parent)
		if current_target == parent:
			current_target = null
	else:
		targets.erase(area)
		if current_target == area:
			current_target = null

func _jump_started():
	jump_started = true
	land_started = false

func _fall_started():
	fall_started = true
	previously_falling = true

func _land_started():
	land_started = true
	previously_falling = false
