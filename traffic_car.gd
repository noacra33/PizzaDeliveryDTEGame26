extends CharacterBody2D

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

const MIN_ROUTE_LENGTH := 2000.0
const SEPARATION_RADIUS := 120.0
const SEPARATION_FORCE  := 60.0

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

func _pick_new_target() -> void:
	var map_rid = NavigationServer2D.get_maps()[0]
	var attempts := 0
	var point := Vector2.ZERO
	while attempts < 10:
		point = NavigationServer2D.map_get_random_point(map_rid, 1, false)
		if global_position.distance_to(point) >= MIN_ROUTE_LENGTH:
			break
		attempts += 1
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

	var map_rid = NavigationServer2D.get_maps()[0]
	var best_pos := Vector2.ZERO
	var best_dist := 0.0

	for i in 50:
		var try_pos = NavigationServer2D.map_get_random_point(map_rid, 1, false)

		if try_pos == Vector2.ZERO:
			continue
		if try_pos.distance_to($"../Car".global_position) < 300:
			continue

		var min_dist := INF
		for car in get_tree().get_nodes_in_group("traffic"):
			if car == self:
				continue
			min_dist = min(min_dist, try_pos.distance_to(car.global_position))
		if min_dist == INF:
			min_dist = 9999.0
		if min_dist > best_dist:
			best_dist = min_dist
			best_pos = try_pos

	if best_pos == Vector2.ZERO:
		await get_tree().physics_frame
		await get_tree().physics_frame
		best_pos = NavigationServer2D.map_get_random_point(map_rid, 1, false)

	global_position = best_pos

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
