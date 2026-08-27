extends CharacterBody2D

var damage_cooldown := 0.0
const DAMAGE_COOLDOWN_TIME := 1.5
const Pizza = preload("res://pizza.tscn")
var health := 100
var MAX_HEALTH := 100
var rocket_count := 0
var boosting := false
const BOOST_SPEED := 600.0
const BOOST_DURATION := 5.0
var base_max_speed := 0.0

@onready var music1 = $Music1
@onready var music2 = $Music2

@export var ACCELERATION : float = 600.0
@export var MAX_SPEED    : float = 400.0
@export var FRICTION     : float = 4.0
@export var TURN_SPEED   : float = 3.8
var NORMAL_GRIP  := 0.85
var DRIFT_GRIP   := 0.95
var DRIFT_KICK   := 0.03
var in_delivery_zone := false

func _ready() -> void:
	var car_data = Names.CAR_DATA[Names.selected_car]
	MAX_HEALTH   = car_data.health
	health       = MAX_HEALTH
	MAX_SPEED    = car_data.speed * 48.0 + 120.0
	base_max_speed = MAX_SPEED
	ACCELERATION = car_data.acceleration * 70.0 + 120.0
	FRICTION     = 3.0 - (car_data.handling * 0.2)
	var d = car_data.drift / 5.0
	DRIFT_KICK  = lerp(0.008, 0.025, d)
	DRIFT_GRIP  = lerp(0.90, 0.95, d)
	NORMAL_GRIP = lerp(0.75, 0.85, d)
	$CarSprite1.visible = Names.selected_car == 0
	$CarSprite2.visible = Names.selected_car == 1
	$CarSprite3.visible = Names.selected_car == 2
	_start_music()

func _start_music() -> void:
	var track = music1 if randi() % 2 == 0 else music2
	track.play()
	track.finished.connect(func(): _play_other(track))

func _play_other(last_track: AudioStreamPlayer2D) -> void:
	var next = music2 if last_track == music1 else music1
	next.play()
	next.finished.connect(func(): _play_other(next))

func collect_rocket() -> void:
	rocket_count += 1
	get_tree().current_scene._update_rocket_display()

func collect_health() -> void:
	var car_data = Names.CAR_DATA[Names.selected_car]
	var heal_amount = int(car_data.health * 0.3)
	health = min(health + heal_amount, MAX_HEALTH)

func _use_rocket() -> void:
	if rocket_count <= 0 or boosting:
		return
	rocket_count -= 1
	boosting = true
	MAX_SPEED = BOOST_SPEED
	ACCELERATION = 900.0
	get_tree().current_scene._update_rocket_display()
	_spawn_fire()
	await get_tree().create_timer(BOOST_DURATION).timeout
	MAX_SPEED = base_max_speed
	ACCELERATION = Names.CAR_DATA[Names.selected_car].acceleration * 70.0 + 120.0
	boosting = false
	$FireParticles.emitting = false

func _spawn_fire() -> void:
	$FireParticles.emitting = true

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

	if Input.is_action_just_pressed("use_rocket") and not boosting:
		_use_rocket()

	move_and_slide()

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return
	damage_cooldown = DAMAGE_COOLDOWN_TIME
	health -= amount
	health = max(health, 0)
	get_tree().current_scene.flash_damage()
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
