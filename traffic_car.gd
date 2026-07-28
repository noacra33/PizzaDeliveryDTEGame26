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
	var random_point = NavigationServer2D.map_get_random_point(map_rid, 1, false)
	nav.target_position = random_point

func _show_sprite(type: String) -> void:
	for child in get_children():
		if child is AnimatedSprite2D:
			child.hide()
	get_node(node_names[type]).show()
	get_node(node_names[type]).play("default")

func _ready() -> void:
	nav = $NavigationAgent2D
	# spawn at a random point on the navmesh immediately
	var map_rid = NavigationServer2D.get_maps()[0]
	global_position = NavigationServer2D.map_get_random_point(map_rid, 1, false)
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
	
	velocity = velocity.lerp(direction * speed, 5.0 * delta)
	
	if velocity.length() > 10:
		rotation = lerp_angle(rotation, velocity.angle() + PI / 2, 8.0 * delta)
	
	move_and_slide()
