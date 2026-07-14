extends Control

@onready var score_label: Label = $MenuContainer/VictoryScreen/VBox/ScoreLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Ensure the tree is unpaused
	get_tree().paused = false
	
	$MenuContainer/VictoryScreen/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$MenuContainer/VictoryScreen/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	
	if is_instance_valid(score_label):
		score_label.text = "FAMILY MEMBERS ESCAPED: %d" % FamilyManager.last_saved_count

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_1_tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
