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

@onready var markers_node     = $DeliveryMarkers
@onready var progress_bar     = $CanvasLayer/ProgressBar
@onready var delivery_label   = $CanvasLayer/Label
@onready var win_screen       = $WinScreen
@onready var job_list         = $CanvasLayer/JobList
@onready var camera           = $Car/Camera2D

func _ready() -> void:
	win_screen.hide()
	progress_bar.max_value = TOTAL_DELIVERIES_TO_WIN
	progress_bar.value = 0
	spawn_delivery_markers()

func spawn_delivery_markers() -> void:
	for child in markers_node.get_children():
		child.queue_free()
	var points = spawn_points.duplicate()
	points.shuffle()
	for i in 3:
		var marker = DeliveryMarker.instantiate()
		marker.global_position = points[i]
		marker.pizza_delivered.connect(_on_pizza_delivered)
		markers_node.add_child(marker)
	_refresh_job_list()

func _on_pizza_delivered() -> void:
	deliveries_done += 1
	progress_bar.value = deliveries_done
	delivery_label.text = "DELIVERIES: %d / %d" % [deliveries_done, TOTAL_DELIVERIES_TO_WIN]

	shake_camera()
	slow_mo()

	if deliveries_done >= TOTAL_DELIVERIES_TO_WIN:
		trigger_win()
	else:
		spawn_delivery_markers()

func _refresh_job_list() -> void:
	for child in job_list.get_children():
		child.queue_free()
	var i := 1
	for marker in markers_node.get_children():
		var lbl = Label.new()
		lbl.text = "→ Stop #%d" % i
		job_list.add_child(lbl)
		i += 1

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
	win_screen.show()
