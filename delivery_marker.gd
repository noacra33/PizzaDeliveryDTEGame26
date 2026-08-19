extends Area2D

signal pizza_delivered(customer_name: String, travel_time: float)

var player_inside := false
var waiting_for_pizza := false
var customer_name := ""
var car_ref: Node = null
var time_started := 0.0

const SPIN_SPEED := 1.5

func _ready() -> void:
	customer_name = Names.random_name()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	time_started = Time.get_ticks_msec() / 1000.0

func _process(delta: float) -> void:
	$Circle.rotation += SPIN_SPEED * delta
	$Circle2.rotation -= SPIN_SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.name == "Car":
		player_inside = true
		waiting_for_pizza = true
		car_ref = body
		body.in_delivery_zone = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Car":
		player_inside = false
		body.in_delivery_zone = false

func receive_pizza() -> void:
	if waiting_for_pizza:
		waiting_for_pizza = false
		var travel_time = (Time.get_ticks_msec() / 1000.0) - time_started
		pizza_delivered.emit(customer_name, travel_time)
		queue_free()
