extends CharacterBody2D

const CHASE_SPEED := 220.0
const RAM_DAMAGE := 20
const ACCELERATION := 3.0

var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = velocity.lerp(direction * CHASE_SPEED, ACCELERATION * delta)
	
	# rotate to face player
	rotation = direction.angle() + PI / 2
	
	move_and_slide()
	
	# check if we rammed the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Car":
			collision.get_collider().take_damage(RAM_DAMAGE)
