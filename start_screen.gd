extends Control

@onready var high_score_label = $HighScoreLabel
@onready var start_button     = $StartButton

const STAT_FILLED   = "█"
const STAT_EMPTY    = "░"
const MAX_STAT      = 5

func _ready() -> void:
	high_score_label.text = "BEST: %d" % Names.high_score
	_setup_car_panels()

func _setup_car_panels() -> void:
	for i in 3:
		var car = Names.CAR_DATA[i]
		var panel_num = i + 1
		
		get_node("CarContainer/CarPanel%d/VBoxContainer/SpeedLabel%d" % [panel_num, panel_num]).text = "SPD  " + _stat_bar(car.speed)
		get_node("CarContainer/CarPanel%d/VBoxContainer/HandlingLabel%d" % [panel_num, panel_num]).text = "HND  " + _stat_bar(car.handling)
		get_node("CarContainer/CarPanel%d/VBoxContainer/AccelLabel%d" % [panel_num, panel_num]).text = "ACC  " + _stat_bar(car.acceleration)

func _stat_bar(value: int) -> String:
	var bar := ""
	for i in MAX_STAT:
		bar += STAT_FILLED if i < value else STAT_EMPTY
	return bar

func _on_select_button_1_pressed() -> void:
	Names.selected_car = 0
	_highlight_selected()

func _on_select_button_2_pressed() -> void:
	Names.selected_car = 1
	_highlight_selected()

func _on_select_button_3_pressed() -> void:
	Names.selected_car = 2
	_highlight_selected()

func _highlight_selected() -> void:
	for i in 3:
		var panel = get_node("CarContainer/CarPanel%d" % (i + 1))
		if i == Names.selected_car:
			panel.modulate = Color(1, 1, 0, 1)  # yellow highlight
		else:
			panel.modulate = Color(1, 1, 1, 1)  # normal

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tile_map_layer.tscn")
