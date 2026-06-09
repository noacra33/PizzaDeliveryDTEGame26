extends CharacterBody2D
var health := 100
var damage_cooldown := 0.0
const DAMAGE_COOLDOWN_TIME := 1.5
const MAX_HEALTH := 100
const Pizza = preload("res://pizza.tscn")

@export var ACCELERATION : float = 600.0
@export var MAX_SPEED    : float = 400.0
@export var FRICTION     : float = 4.0
@export var TURN_SPEED : float = 3.8
var NORMAL_GRIP  := 0.85
var DRIFT_GRIP   := 0.95
var DRIFT_KICK   := 0.03

var in_delivery_zone := false

func _ready() -> void:
	var car_data = Names.CAR_DATA[Names.selected_car]
	MAX_SPEED    = car_data.speed        * 55.0 +100  # 3-5 = 165-275 (slower, closer together)
	ACCELERATION = car_data.acceleration * 80.0  +100 # 3-5 = 240-400
	FRICTION     = 3.0 - (car_data.handling * 0.2) # tighter range
	var d = car_data.drift / 5.0
	DRIFT_KICK  = lerp(0.008, 0.025, d)
	DRIFT_GRIP  = lerp(0.90, 0.95, d)
	NORMAL_GRIP = lerp(0.75, 0.85, d)
	$CarSprite1.visible = Names.selected_car == 0
	$CarSprite2.visible = Names.selected_car == 1
	$CarSprite3.visible = Names.selected_car == 2

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

	if drift:
		sideways_speed += turn_dir * velocity.length() * DRIFT_KICK
		sideways_speed *= DRIFT_GRIP
	else:
		sideways_speed *= NORMAL_GRIP

	velocity = forward * forward_speed + forward.orthogonal() * sideways_speed

	if input_dir == 0:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)

	move_and_slide()

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return
	damage_cooldown = DAMAGE_COOLDOWN_TIME
	health -= amount
	health = max(health, 0)
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
