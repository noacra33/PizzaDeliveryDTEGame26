extends Area2D

signal pizza_delivered(customer_name: String)

var player_inside := false
var waiting_for_pizza := false
var customer_name := ""
var car_ref: Node = null

func _ready() -> void:
	customer_name = Names.random_name()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
		pizza_delivered.emit(customer_name)
		queue_free()

func _calculate_points(distance: float) -> int:
	# closer throw = fewer points, farther = more
	# max useful throw range is about 300px
	if distance < 50:
		return 100
	elif distance < 150:
		return 250
	elif distance < 300:
		return 500
	else:
		return 1000
	
