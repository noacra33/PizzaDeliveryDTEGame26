extends Node2D
var last_spawn_index := -1
const DeliveryMarker = preload("res://delivery_marker.tscn")
var last_cop_threshold := 0
const TOTAL_DELIVERIES_TO_WIN := 10
const CopScene = preload("res://cop.tscn")
var deliveries_done := 0
var high_score_beaten := false
var spawn_points := [
	Vector2(300, 200),
	Vector2(-400, 100),
	Vector2(150, -350),
	Vector2(-200, -200),
	Vector2(500, -100),
]
const ZONES = [
	Rect2(-2000, -2000, 1000, 1000),  # zone 0 — adjust these to your map
	Rect2(-1000, -2000, 1000, 1000),  # zone 1
	Rect2(0,     -2000, 1000, 1000),  # zone 2
	Rect2(-2000, -1000, 1000, 1000),  # zone 3
	Rect2(-1000, -1000, 1000, 1000),  # zone 4
]
const CARS_PER_ZONE := 20
const MIN_CARS_PER_ZONE := 15
var score := 0
var last_delivery_pos := Vector2.ZERO
@onready var markers_node     = $DeliveryMarkers
const TrafficCar = preload("res://traffic_car.tscn")
const TRAFFIC_COUNT = 100
@onready var celebration_label = $CanvasLayer/CelebrationLabel
@onready var health_bar = $CanvasLayer/HealthBar
@onready var camera           = $Car/Camera2D
@onready var score_label      = $CanvasLayer/ScoreLabel
@onready var high_score_label = $CanvasLayer/HighScoreLabel
@onready var delivery_arrow  = $Car/DeliveryArrow
@onready var distance_label  = $CanvasLayer/DistanceLabel
@onready var spawn_points_node = $SpawnPoints
@onready var customer_label = $CanvasLayer/CustomerLabel
func _get_spawn_positions() -> Array:
	var positions = []
	for child in spawn_points_node.get_children():
		positions.append(child.global_position)
	return positions
func _update_score_display() -> void:
	score_label.text      = "SCORE: %d" % score
	high_score_label.text = "BEST: %d" % Names.high_score
func _on_pizza_delivered(customer_name: String) -> void:
	deliveries_done += 1

	var current_pos = markers_node.get_children()[0].global_position if markers_node.get_children().size() > 0 else Vector2.ZERO
	var distance = last_delivery_pos.distance_to(current_pos)
	last_delivery_pos = current_pos

	var points = min(1000, int(distance))
	score += points

	_check_cop_spawn()

	var is_new_high = Names.update_high_score(score)
	if is_new_high and not high_score_beaten:
		high_score_beaten = true
		_on_high_score_beaten()


	_update_score_display()
	shake_camera()
	slow_mo()
	spawn_delivery_markers()
func _spawn_traffic() -> void:
	for zone_index in ZONES.size():
		var spawned := 0
		var attempts := 0
		while spawned < CARS_PER_ZONE and attempts < 200:
			attempts += 1
			var map_rid = NavigationServer2D.get_maps()[0]
			var try_pos = NavigationServer2D.map_get_random_point(map_rid, 1, false)
			
			# check it's in the right zone
			if not ZONES[zone_index].has_point(try_pos):
				continue
			
			# check it's not too close to player
			if try_pos.distance_to($Car.global_position) < 300:
				continue
			
			var car = TrafficCar.instantiate()
			car.global_position = try_pos
			car.assigned_zone = zone_index
			add_child(car)
			await get_tree().create_timer(0.05).timeout
			spawned += 1
func _on_high_score_beaten() -> void:
	Names.save_high_score()
	celebration_label.text = "NEW HIGH SCORE!"
	celebration_label.modulate = Color(1, 1, 0, 1)
	var original_pos = celebration_label.position

	var tween = create_tween()

	# flash and shake sequentially in quick bursts
	for i in 8:
		tween.tween_callback(func():
			celebration_label.modulate = Color(1, 1, 0, 1) if i % 2 == 0 else Color(1, 1, 1, 1)
			celebration_label.position = original_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		)
		tween.tween_interval(0.08)

	# reset position then fade out
	tween.tween_callback(func(): celebration_label.position = original_pos)
	tween.tween_interval(1.0)
	tween.tween_property(celebration_label, "modulate:a", 0.0, 1.0)


func shake_camera() -> void:
	var tween = create_tween()
	for i in 8:
		tween.tween_property(camera, "offset",
			Vector2(randf_range(-12, 12), randf_range(-12, 12)), 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func slow_mo() -> void:
	Engine.time_scale = 0.15
	await get_tree().create_timer(0.3, true, false, true).timeout
	var tween = create_tween()
	tween.tween_method(func(v): Engine.time_scale = v, 0.15, 1.0, 0.4)

func trigger_win() -> void:
	Engine.time_scale = 1.0
#ewwdsareen.show()



func spawn_delivery_markers() -> void:
	var points = _get_spawn_positions()
	var available = []
	for i in points.size():
		if i != last_spawn_index:
			available.append(i)
	available.shuffle()
	last_spawn_index = available[0]
	
	for child in markers_node.get_children():
		child.queue_free()
	
	var marker = DeliveryMarker.instantiate()
	marker.global_position = points[available[0]]
	marker.pizza_delivered.connect(_on_pizza_delivered)
	markers_node.add_child(marker)

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_traffic()
	last_delivery_pos = $Car.global_position
	_update_score_display()
	spawn_delivery_markers()
	
func _process(delta: float) -> void:
	_update_arrow()
	_update_health_bar()

func _update_arrow() -> void:
	var markers = markers_node.get_children()
	if markers.size() == 0:
		distance_label.text = ""
		customer_label.text = ""
		return
	
	var marker = markers[0]
	delivery_arrow.target = marker
	
	var distance = $Car.global_position.distance_to(marker.global_position)
	distance_label.text  = "NEXT: %dm" % int(distance / 10)
	customer_label.text  = "DELIVER TO: %s" % marker.customer_name
	
	
func _return_to_start() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://start_screen.tscn")

func _update_health_bar() -> void:
	health_bar.value = $Car.health
func _check_cop_spawn() -> void:
	var threshold = int(score / 1500) * 1500
	if threshold > last_cop_threshold:
		last_cop_threshold = threshold
		_spawn_cop()

var cop_spawn_angle := 0.0

func _spawn_cop() -> void:
	var cop = CopScene.instantiate()
	cop_spawn_angle += 137.5
	var angle_rad = deg_to_rad(cop_spawn_angle)
	var offset = Vector2(cos(angle_rad), sin(angle_rad)) * 550
	cop.global_position = $Car.global_position + offset
	add_child(cop)
