extends CharacterBody2D

# --- tuning knobs ---
const Pizza = preload("res://pizza.tscn")
@export var ACCELERATION : float  = 600.0
@export var MAX_SPEED  : float   = 400.0
@export var FRICTION    : float  = 4.0      # higher = snappier stop
@export var TURN_SPEED   : float = 2.8      # radians per second
@export var DRIFT_FACTOR : float = 0.92     # how much sideways speed bleeds off (lower = more drift)
@export var DRIFT_BRAKE  : float = 0.6     # less bleed when handbrake held (the slidey feel)
var in_delivery_zone := false
func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("brake", "accelerate")   # -1 reverse, +1 forward
	var turn_dir  := Input.get_axis("left", "right") # wait — flipped below
	var handbrake := Input.is_action_pressed("handbrake")  # spacebar = handbrake
	
	if Input.is_action_just_pressed("throw_pizza") and in_delivery_zone:
		var pizza = Pizza.instantiate()
		pizza.global_position = global_position
		pizza.launch(Vector2.UP.rotated(rotation))
		get_tree().current_scene.add_child(pizza)
		
	# --- turning (only when moving) ---
	if velocity.length() > 20:
		var speed_factor = velocity.length() / MAX_SPEED
		rotation += -turn_dir * TURN_SPEED * speed_factor * delta

	# --- acceleration along facing direction ---
	var forward := Vector2.UP.rotated(rotation)
	if input_dir != 0:
		velocity += forward * input_dir * ACCELERATION * delta
		velocity = velocity.limit_length(MAX_SPEED)

	# --- friction / drift ---
	# Split velocity into forward and sideways components
	var forward_speed  := forward.dot(velocity)
	var sideways_speed := forward.orthogonal().dot(velocity)

	# Choose how much sideways grip to apply
	var grip := DRIFT_FACTOR if not handbrake else DRIFT_BRAKE
	sideways_speed *= grip

	# Rebuild velocity from components
	velocity = forward * forward_speed + forward.orthogonal() * sideways_speed

	# General friction (slows you down when no input)
	if input_dir == 0:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)

	move_and_slide()
