extends CharacterBody2D

# --- tuning knobs ---
const ACCELERATION  = 600.0
const MAX_SPEED     = 400.0
const FRICTION      = 4.0      # higher = snappier stop
const TURN_SPEED    = 2.8      # radians per second
const DRIFT_FACTOR  = 0.92     # how much sideways speed bleeds off (lower = more drift)
const DRIFT_BRAKE   = 0.60     # less bleed when handbrake held (the slidey feel)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("brake", "accelerate")   # -1 reverse, +1 forward
	var turn_dir  := Input.get_axis("left", "right") # wait — flipped below
	var handbrake := Input.is_action_pressed("ui_accept")  # spacebar = handbrake

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
