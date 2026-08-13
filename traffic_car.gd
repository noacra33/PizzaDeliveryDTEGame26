extends CharacterBody2D
const MIN_CARS_PER_ZONE := 15
const CAR_TYPES = {
	"bus":     { "speed": 60.0,  "erratic": 0.2, "weight": 5  },
	"truck":   { "speed": 70.0,  "erratic": 0.3, "weight": 8  },
	"tanker":  { "speed": 55.0,  "erratic": 0.1, "weight": 3  },
	"car":     { "speed": 120.0, "erratic": 0.8, "weight": 40 },
	"ute":     { "speed": 90.0,  "erratic": 0.5, "weight": 25 },
	"fastcar": { "speed": 140.0, "erratic": 1.0, "weight": 19 },
}

var node_names = {
	"bus":     "Bus",
	"truck":   "Truck",
	"tanker":  "Tanker",
	"car":     "Car",
	"ute":     "Ute",
	"fastcar": "Fastcar"
}

const SEPARATION_RADIUS := 120.0
const SEPARATION_FORCE  := 60.0
const SHORT_ROUTE       := 400.0
const LONG_ROUTE        := 2000.0
const LONG_ROUTE_CHANCE := 0.2

var assigned_zone := 0
var speed    := 120.0
var erratic  := 0.8
var nav: NavigationAgent2D
var wander_timer    := 0.0
var wander_interval := 2.0

func _weighted_random_type() -> String:
	var total = 0
	for key in CAR_TYPES:
		total += CAR_TYPES[key].weight
	var roll = randi() % total
	var cumulative = 0
	for key in CAR_TYPES:
		cumulative += CAR_TYPES[key].weight
		if roll < cumulative:
			return key
	return "car"

func _count_cars_in_zone(zone_index: int) -> int:
	var count := 0
	for car in get_tree().get_nodes_in_group("traffic"):
		if car.assigned_zone == zone_index:
			count += 1
	return count



func _pick_random_point_in_zone(zone_index: int) -> Vector2:
	var main = get_tree().current_scene
	var poly = main.zone_polygons[zone_index]
	var map_rid = NavigationServer2D.get_maps()[0]
	
	# get bounding box of zone polygon
	var points = poly.polygon
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	# try random points within bounding box
	for i in 30:
		var try_pos = poly.global_position + Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		# check it's inside the polygon
		if not main._point_in_zone(try_pos, zone_index):
			continue
		# snap to navmesh
		var snapped = NavigationServer2D.map_get_closest_point(map_rid, try_pos)
		# check snap didn't jump too far off road
		if snapped.distance_to(try_pos) > 200:
			continue
		return snapped
	
	# fallback to navmesh random if all attempts fail
	return NavigationServer2D.map_get_random_point(map_rid, 1, false)

func _pick_new_target() -> void:
	var use_long := randf() < LONG_ROUTE_CHANCE
	var cars_in_zone = _count_cars_in_zone(assigned_zone)
	var can_leave_zone = cars_in_zone > MIN_CARS_PER_ZONE
	var main = get_tree().current_scene

	# decide target zone
	var target_zone := assigned_zone
	if can_leave_zone and randf() < 0.1:
		# 10% chance to try moving to adjacent zone
		target_zone = randi() % main.zone_polygons.size()

	var point := _pick_random_point_in_zone(target_zone)
	
	# enforce minimum distance
	var min_dist = LONG_ROUTE if use_long else SHORT_ROUTE
	if global_position.distance_to(point) < min_dist:
		point = _pick_random_point_in_zone(target_zone)
	
	assigned_zone = target_zone
	nav.target_position = point

func _show_sprite(type: String) -> void:
	for child in get_children():
		if child is AnimatedSprite2D:
			child.hide()
	get_node(node_names[type]).show()
	get_node(node_names[type]).play("default")

func _get_separation_force() -> Vector2:
	var push := Vector2.ZERO
	for body in get_tree().get_nodes_in_group("traffic"):
		if body == self:
			continue
		var dist = global_position.distance_to(body.global_position)
		if dist < SEPARATION_RADIUS and dist > 0:
			var away = (global_position - body.global_position).normalized()
			push += away * (SEPARATION_FORCE * (1.0 - dist / SEPARATION_RADIUS))
	return push

func _ready() -> void:
	add_to_group("traffic")
	nav = $NavigationAgent2D
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var picked = _weighted_random_type()
	speed   = CAR_TYPES[picked].speed
	erratic = CAR_TYPES[picked].erratic
	_show_sprite(picked)
	wander_timer = randf_range(0, wander_interval)
	_pick_new_target()

func _physics_process(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0 or nav.is_navigation_finished():
		wander_timer = randf_range(
			wander_interval * (1.0 - erratic),
			wander_interval * (1.0 + erratic)
		)
		_pick_new_target()

	if nav.is_navigation_finished():
		return

	var next_pos  = nav.get_next_path_position()
	var direction = (next_pos - global_position).normalized()

	if erratic > 0.5:
		direction = direction.rotated(randf_range(-erratic * 0.3, erratic * 0.3))

	var sep = _get_separation_force()
	var final_dir = (direction * speed + sep).normalized()

	velocity = velocity.lerp(final_dir * speed, 5.0 * delta)

	if velocity.length() > 10:
		rotation = lerp_angle(rotation, velocity.angle() + PI / 2, 8.0 * delta)

	move_and_slide()
