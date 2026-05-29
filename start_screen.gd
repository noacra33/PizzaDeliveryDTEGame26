extends Control

func _ready() -> void:
	$HighScoreLabel.text = "BEST: %d" % Names.high_score

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tile_map_layer.tscn")
