extends Control

@onready var screenshot_rect = $ScreenshotRect
@onready var blood_rect      = $BloodRect
@onready var label           = $Label

func _ready() -> void:
	blood_rect.modulate.a = 0.0
	label.modulate.a      = 0.0
	label.text            = "BUSTED."

	if DeathScreen.last_screenshot != null:
		screenshot_rect.texture = DeathScreen.last_screenshot

	_play_death_sequence()

func _play_death_sequence() -> void:
	var tween = create_tween()

	# blood slowly creeps in
	tween.tween_property(blood_rect, "modulate:a", 0.6, 2.0)

	# BUSTED fades in
	tween.tween_property(label, "modulate:a", 1.0, 1.0)

	# wait then return to start
	tween.tween_interval(2.0)
	tween.tween_callback(func():
		DeathScreen.last_screenshot = null
		get_tree().change_scene_to_file("res://start_screen.tscn")
	)
