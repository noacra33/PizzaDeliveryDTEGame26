extends CharacterBody2D

var CHASE_SPEED := 210.0
var RAM_DAMAGE  := 20
const ACCELERATION := 3.0

var player: Node2D = null
var ram_cooldown := 0.0
const RAM_COOLDOWN_TIME := 1.0
@onready var sprite  = $AnimatedSprite2D
var TURN_SPEED := 3.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	var roll = randf()
	var cop_type: int
	if roll < 0.5:
		cop_type = 0    # medium 50%
	elif roll < 0.75:
		cop_type = 1    # fast 25%
	else:
		cop_type = 2    # slow 25%
	var data = Names.COP_DATA[cop_type]
	CHASE_SPEED = data.speed
	RAM_DAMAGE  = data.damage
	TURN_SPEED = 12.0 if cop_type == 0 else 6.0  # fast cop very snappy, others decent
	sprite.animation = Names.COP_DATA[cop_type]["sprite"]

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	ram_cooldown -= delta

	var direction = (player.global_position - global_position).normalized()
	
	# movement follows direction instantly
	velocity = velocity.lerp(direction * CHASE_SPEED, ACCELERATION * delta)
	
	# visual rotation lerps to match velocity direction, not target direction
	# this makes it look like the car is actually turning, not teleporting
	if velocity.length() > 10:
		var target_angle = velocity.angle() + PI / 2
		rotation = lerp_angle(rotation, target_angle, TURN_SPEED * delta)
	
	move_and_slide()
	
	if ram_cooldown <= 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider().name == "Car":
				collision.get_collider().take_damage(RAM_DAMAGE)
				ram_cooldown = RAM_COOLDOWN_TIME
				break
