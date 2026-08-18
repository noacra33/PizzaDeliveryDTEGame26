extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("default")

func _on_body_entered(body: Node) -> void:
	if body.name == "Car":
		body.collect_rocket()
		queue_free()
