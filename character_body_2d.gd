extends CharacterBody2D
var health := 100
var damage_cooldown := 0.0
const DAMAGE_COOLDOWN_TIME := 1.5
var DRIFT_KICK := 0.04
var DRIFT_GRIP := 0.985
const MAX_HEALTH := 100
# --- tuning knobs ---
const Pizza = preload("res://pizza.tscn")
@export var ACCELERATION : float  = 600.0
@export var MAX_SPEED  : float   = 400.0
@export var FRICTION    : float  = 4.0      # higher = snappier stop
@export var TURN_SPEED   : float = 2.8      # radians per second
@export var DRIFT_FACTOR : float = 0.98     # how much sideways speed bleeds off (lower = more drift)
@export var DRIFT_BRAKE  : float = 0.995     # less bleed when handbrake held (the slidey feel)
var in_delivery_zone := false


func _ready() -> void:
	var car_data = Names.CAR_DATA[Names.selected_car]
	MAX_SPEED    = car_data.speed        * 80.0
	ACCELERATION = car_data.acceleration * 120.0
	FRICTION     = 3.0 - (car_data.handling * 0.3)
	$CarSprite1.visible = Names.selected_car == 0
	$CarSprite2.visible = Names.selected_car == 1
	$CarSprite3.visible = Names.selected_car == 2
	var drift_factor = car_data.drift / 5.0
	DRIFT_KICK = lerp(0.01, 0.07, drift_factor)
	DRIFT_GRIP = lerp(0.96, 0.995, drift_factor)
func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("brake", "accelerate")
	var turn_dir  := Input.get_axis("left", "right")
	var drift     := Input.is_action_pressed("drift")
	damage_cooldown -= delta

	if Input.is_action_just_pressed("throw_pizza") and in_delivery_zone:
		var pizza = Pizza.instantiate()
		pizza.global_position = global_position
		pizza.launch(Vector2.UP.rotated(rotation))
		get_tree().current_scene.add_child(pizza)

	if velocity.length() > 20:
		var speed_factor = velocity.length() / MAX_SPEED
		rotation += -turn_dir * TURN_SPEED * speed_factor * delta

	var forward := Vector2.UP.rotated(rotation)
	if input_dir != 0:
		velocity += forward * input_dir * ACCELERATION * delta
		velocity = velocity.limit_length(MAX_SPEED)

	var forward_speed  := forward.dot(velocity)
	var sideways_speed := forward.orthogonal().dot(velocity)

	var grip := DRIFT_BRAKE if drift else DRIFT_FACTOR
	sideways_speed *= grip
	if drift:
		sideways_speed += turn_dir * velocity.length() * DRIFT_KICK
		sideways_speed *= DRIFT_GRIP
	else:
		sideways_speed *= 0.92

	if input_dir == 0:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)

	move_and_slide()

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return
	damage_cooldown = DAMAGE_COOLDOWN_TIME
	health -= amount
	health = max(health, 0)
	print("took damage, health now: ", health)
	if health <= 0:
		die()

func die() -> void:
	get_tree().get_first_node_in_group("hud").hide()
	$DeliveryArrow.hide()
	await get_tree().process_frame
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	var texture = ImageTexture.create_from_image(image)
	DeathScreen.last_screenshot = texture
	get_tree().change_scene_to_file("res://death_screen.tscn")
