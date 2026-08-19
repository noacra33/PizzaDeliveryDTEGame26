extends Node2D

var last_spawn_index := -1
const DeliveryMarker = preload("res://delivery_marker.tscn")
var last_cop_threshold := 0
const TOTAL_DELIVERIES_TO_WIN := 10
const CopScene = preload("res://cop.tscn")
var deliveries_done := 0
var high_score_beaten := false

var score := 0
var last_delivery_pos := Vector2.ZERO
var total_stars := 0
var star_deliveries := 0

const CARS_PER_ZONE := 20
const MIN_CARS_PER_ZONE := 15
const TrafficCar = preload("res://traffic_car.tscn")
const RocketPickup = preload("res://rocket_pickup.tscn")
const ROCKET_SPAWN_COUNT := 5

# scoring constants
const DIST_SCALE        := 0.4    # points per pixel of distance
const MAX_DIST_POINTS   := 800    # cap on distance points
const MIN_DIST_POINTS   := 50     # minimum so short trips still score
const TIME_BONUS_3STAR  := 750
const TIME_BONUS_2STAR  := 250
const TIME_BONUS_1STAR  := 100
# time multipliers — distance / these = time limit in seconds
const TIME_3STAR_DIV    := 250.0  # very tight — you need to haul
const TIME_2STAR_DIV    := 120.0  # moderate — solid driving needed
const TIME_1STAR_DIV    := 60.0  # generous — just don't dawdle

var zone_polygons: Array = []

@onready var markers_node       = $DeliveryMarkers
@onready var celebration_label  = $CanvasLayer/CelebrationLabel
@onready var health_bar         = $CanvasLayer/HealthBar
@onready var camera             = $Car/Camera2D
@onready var score_label        = $CanvasLayer/ScoreLabel
@onready var high_score_label   = $CanvasLayer/HighScoreLabel
@onready var delivery_arrow     = $Car/DeliveryArrow
@onready var distance_label     = $CanvasLayer/DistanceLabel
@onready var spawn_points_node  = $SpawnPoints
@onready var customer_label     = $CanvasLayer/CustomerLabel
@onready var rocket_label       = $CanvasLayer/RocketLabel
@onready var star_label         = $CanvasLayer/StarLabel
@onready var avg_star_label     = $CanvasLayer/AvgStarLabel

func _build_zones() -> void:
	for zone_node in $Zones.get_children():
		zone_polygons.append(zone_node)

func _point_in_zone(point: Vector2, zone_index: int) -> bool:
	var poly = zone_polygons[zone_index]
	var local_point = poly.to_local(point)
	return Geometry2D.is_point_in_polygon(local_point, poly.polygon)

func _get_spawn_positions() -> Array:
	var positions = []
	for child in spawn_points_node.get_children():
		positions.append(child.global_position)
	return positions

func _spawn_rockets() -> void:
	var map_rid = NavigationServer2D.get_maps()[0]
	for i in ROCKET_SPAWN_COUNT:
		var rocket = RocketPickup.instantiate()
		var pos = NavigationServer2D.map_get_random_point(map_rid, 1, false)
		rocket.global_position = pos
		add_child(rocket)

func _update_rocket_display() -> void:
	var count = $Car.rocket_count
	rocket_label.text = "🚀 x%d" % count
	rocket_label.visible = count > 0

func _update_score_display() -> void:
	score_label.text      = "SCORE: %d" % score
	high_score_label.text = "BEST: %d" % Names.high_score

func _update_avg_star() -> void:
	if star_deliveries == 0:
		avg_star_label.text = ""
		return
	var avg = float(total_stars) / float(star_deliveries)
	var stars = ""
	var rounded = int(round(avg))
	for i in 3:
		stars += "★" if i < rounded else "☆"
	avg_star_label.text = "AVG: %s (%.1f)" % [stars, avg]

func _calculate_score(distance: float, travel_time: float) -> Dictionary:
	var car_speed = $Car.MAX_SPEED
	var speed_factor = car_speed / 264.0  # 264 is slowest car's max speed, so factor >= 1.0

	var dist_points = clamp(int(distance * DIST_SCALE), MIN_DIST_POINTS, MAX_DIST_POINTS)

	var time_3star = (distance / TIME_3STAR_DIV) / speed_factor
	var time_2star = (distance / TIME_2STAR_DIV) / speed_factor
	var time_1star = (distance / TIME_1STAR_DIV) / speed_factor

	var time_bonus := 0
	var stars := 0
	if travel_time <= time_3star:
		time_bonus = TIME_BONUS_3STAR
		stars = 3
	elif travel_time <= time_2star:
		time_bonus = TIME_BONUS_2STAR
		stars = 2
	elif travel_time <= time_1star:
		time_bonus = TIME_BONUS_1STAR
		stars = 1
	else:
		stars = 0

	return {
		"dist_points": dist_points,
		"time_bonus": time_bonus,
		"total": dist_points + time_bonus,
		"stars": stars
	}

func _flash_star_label(stars: int, dist_points: int, time_bonus: int) -> void:
	var star_str = ""
	for i in 3:
		star_str += "★" if i < stars else "☆"
	
	if stars == 0:
		star_label.text = "☆☆☆ NO BONUS\n+%d pts" % dist_points
		star_label.modulate = Color(0.6, 0.6, 0.6, 1)
	elif stars == 1:
		star_label.text = "%s GOOD\n+%d +%d pts" % [star_str, dist_points, time_bonus]
		star_label.modulate = Color(1, 0.8, 0.2, 1)
	elif stars == 2:
		star_label.text = "%s GREAT\n+%d +%d pts" % [star_str, dist_points, time_bonus]
		star_label.modulate = Color(1, 0.6, 0, 1)
	else:
		star_label.text = "%s PERFECT!\n+%d +%d pts" % [star_str, dist_points, time_bonus]
		star_label.modulate = Color(1, 1, 0, 1)

	star_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(star_label, "modulate:a", 0.0, 0.8)

func _on_pizza_delivered(customer_name: String, travel_time: float) -> void:
	deliveries_done += 1

	var current_pos = markers_node.get_children()[0].global_position if markers_node.get_children().size() > 0 else Vector2.ZERO
	var distance = last_delivery_pos.distance_to(current_pos)
	last_delivery_pos = current_pos

	var result = _calculate_score(distance, travel_time)
	score += result.total
	total_stars += result.stars
	star_deliveries += 1

	_flash_star_label(result.stars, result.dist_points, result.time_bonus)
	_update_avg_star()
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
	var map_rid = NavigationServer2D.get_maps()[0]
	for zone_index in zone_polygons.size():
		var spawned := 0
		var attempts := 0
		while spawned < CARS_PER_ZONE and attempts < 200:
			attempts += 1
			var try_pos = NavigationServer2D.map_get_random_point(map_rid, 1, false)
			if try_pos == Vector2.ZERO:
				continue
			if not _point_in_zone(try_pos, zone_index):
				continue
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
	for i in 8:
		tween.tween_callback(func():
			celebration_label.modulate = Color(1, 1, 0, 1) if i % 2 == 0 else Color(1, 1, 1, 1)
			celebration_label.position = original_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		)
		tween.tween_interval(0.08)
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
	_build_zones()
	await get_tree().create_timer(0.5).timeout
	_spawn_traffic()
	last_delivery_pos = $Car.global_position
	_update_score_display()
	_update_rocket_display()
	spawn_delivery_markers()
	_start_zone_debug()
	_spawn_rockets()

func _start_zone_debug() -> void:
	while true:
		await get_tree().create_timer(10.0).timeout
		for i in zone_polygons.size():
			var count = 0
			for car in get_tree().get_nodes_in_group("traffic"):
				if car.assigned_zone == i:
					count += 1
			print("zone ", zone_polygons[i].name, ": ", count, " cars")

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
	distance_label.text = "NEXT: %dm" % int(distance / 10)
	customer_label.text = "DELIVER TO: %s" % marker.customer_name

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
