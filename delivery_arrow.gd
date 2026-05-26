extends Node2D

var target: Node2D = null
var car: Node2D = null

func _ready() -> void:
	car = get_parent()

func _process(delta: float) -> void:
	if target != null and is_instance_valid(target) and car != null:
		var direction = target.global_position - car.global_position
		rotation = direction.angle() - car.rotation + PI / 2
