extends CharacterBody2D

var CHASE_SPEED := 245.0
var RAM_DAMAGE  := 15
var TURN_SPEED  := 7.0
const ACCELERATION := 4.0

var player: Node2D = null
var ram_cooldown := 0.0
const RAM_COOLDOWN_TIME := 1.2

var stuck_timer := 0.0
var last_pos := Vector2.ZERO
const STUCK_TIME := 1.5

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	$SirenSound.play()
	$RamArea.body_entered.connect(_on_ram_area_body_entered)
	
	var roll = randf()
	var cop_type: int
	if roll < 0.5:
		cop_type = 2
	elif roll < 0.75:
		cop_type = 0
	else:
		cop_type = 1

	var data = Names.COP_DATA[cop_type]
	CHASE_SPEED = data.speed
	RAM_DAMAGE  = data.damage
	TURN_SPEED  = data.turn

	$AnimatedSprite2D.play(["Fast", "Slow", "Medium"][cop_type])
	last_pos = global_position

func _on_ram_area_body_entered(body: Node) -> void:
	if body.name == "Car" and ram_cooldown <= 0:
		body.take_damage(RAM_DAMAGE)
		ram_cooldown = RAM_COOLDOWN_TIME

func _physics_process(delta: float) -> void:
	if player == null:
		return

	ram_cooldown -= delta

	stuck_timer += delta
	if stuck_timer > STUCK_TIME:
		stuck_timer = 0.0
		if global_position.distance_to(last_pos) < 20:
			var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 500
			global_position = player.global_position + offset
		last_pos = global_position

	var direction = (player.global_position - global_position).normalized()
	var target_velocity = direction * CHASE_SPEED
	velocity = velocity.lerp(target_velocity, ACCELERATION * delta)
	velocity = velocity.limit_length(CHASE_SPEED * 1.2)

	if velocity.length() > 10:
		var target_angle = velocity.angle() + PI / 2
		rotation = lerp_angle(rotation, target_angle, TURN_SPEED * delta)

	move_and_slide()
