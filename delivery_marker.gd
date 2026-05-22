extends Area2D

signal pizza_delivered

var player_inside := false
var waiting_for_pizza := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Car":
		player_inside = true
		waiting_for_pizza = true
	if body.name == "Car":
		player_inside = true
		waiting_for_pizza = true
		body.in_delivery_zone = true
	

func _on_body_exited(body: Node) -> void:
	if body.name == "Car":
		player_inside = false

func receive_pizza() -> void:
	if waiting_for_pizza:
		waiting_for_pizza = false
		pizza_delivered.emit()
		queue_free()
	
