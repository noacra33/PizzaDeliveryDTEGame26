extends CharacterBody2D

@export var path: Path2D = null
@export var speed := 80.0
@export var progress := 0.0

func _physics_process(delta: float) -> void:
	if path == null:
		return
	
	progress += speed * delta
	if progress > path.curve.get_baked_length():
		progress = 0.0
	
	var target_pos = path.curve.sample_baked(progress)
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	rotation = velocity.angle() + PI / 2
	move_and_slide()
