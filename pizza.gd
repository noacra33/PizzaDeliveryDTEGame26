extends Area2D

var velocity := Vector2.ZERO
const SPEED := 500.0
const LIFETIME := 2.5
const HOME_STRENGTH := 18.0

var target_zone: Area2D = null
var throw_origin := Vector2.ZERO

func launch(direction: Vector2) -> void:
	velocity = direction * SPEED
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if target_zone != null and is_instance_valid(target_zone):
		var to_center = (target_zone.global_position - global_position).normalized()
		velocity = velocity.lerp(to_center * SPEED, HOME_STRENGTH * delta)
		
		if global_position.distance_to(target_zone.global_position) < 20:
			var throw_distance = throw_origin.distance_to(global_position)
			target_zone.receive_pizza()
			queue_free()
			return
	
	global_position += velocity * delta

func _on_area_entered(area: Node) -> void:
	if area is Area2D and area.has_method("receive_pizza"):
		if area.waiting_for_pizza:
			target_zone = area

func _ready() -> void:
	await get_tree().create_timer(LIFETIME).timeout
	if is_instance_valid(self):
		queue_free()
