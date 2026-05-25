extends Node2D

const DeliveryMarker = preload("res://delivery_marker.tscn")

const TOTAL_DELIVERIES_TO_WIN := 10

var deliveries_done := 0

var spawn_points := [
	Vector2(300, 200),
	Vector2(-400, 100),
	Vector2(150, -350),
	Vector2(-200, -200),
	Vector2(500, -100),
]
var score := 0
var last_delivery_pos := Vector2.ZERO
@onready var markers_node     = $DeliveryMarkers
@onready var progress_bar     = $CanvasLayer/ProgressBar


@onready var camera           = $Car/Camera2D
@onready var score_label      = $CanvasLayer/ScoreDisplay/ScoreLabel
@onready var high_score_label = $CanvasLayer/ScoreDisplay/HighScoreLabel


@onready var spawn_points_node = $SpawnPoints

func _get_spawn_positions() -> Array:
	var positions = []
	for child in spawn_points_node.get_children():
		positions.append(child.global_position)
	return positions
func _update_score_display() -> void:
	print("updating score display, score: ", score)
	print("score label: ", score_label)
	print("high score label: ", high_score_label)
	score_label.text      = "SCORE: %d" % score
	high_score_label.text = "BEST: %d" % Names.high_score
func _on_pizza_delivered(customer_name: String) -> void:
	deliveries_done += 1

	var current_pos = markers_node.get_children()[0].global_position if markers_node.get_children().size() > 0 else Vector2.ZERO
	var distance = last_delivery_pos.distance_to(current_pos)
	last_delivery_pos = current_pos

	var points = min(1000, int(distance))
	score += points

	var is_new_high = Names.update_high_score(score)
	if is_new_high:
		_on_high_score_beaten()

	progress_bar.value = deliveries_done
	_update_score_display()
	shake_camera()
	slow_mo()
	spawn_delivery_markers()

func _on_high_score_beaten() -> void:
	# placeholder for now — we'll make this juicy later
	print("NEW HIGH SCORE: ", score)



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

func _ready() -> void:
	last_delivery_pos = $Car.global_position
	progress_bar.max_value = TOTAL_DELIVERIES_TO_WIN
	progress_bar.value = 0
	_update_score_display()
	spawn_delivery_markers()

func spawn_delivery_markers() -> void:
	var points = _get_spawn_positions()
	points.shuffle()
	
	for child in markers_node.get_children():
		child.queue_free()
	
	var marker = DeliveryMarker.instantiate()
	marker.global_position = points[0]
	marker.pizza_delivered.connect(_on_pizza_delivered)
	markers_node.add_child(marker)
