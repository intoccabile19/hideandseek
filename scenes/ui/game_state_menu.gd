extends CanvasLayer

@onready var main_menu: Control = $MenuContainer/MainMenu
@onready var game_over_screen: Control = $MenuContainer/GameOverScreen
@onready var victory_screen: Control = $MenuContainer/VictoryScreen
@onready var score_label: Label = $MenuContainer/VictoryScreen/VBox/ScoreLabel
@onready var volume_slider: HSlider = $MenuContainer/MainMenu/VBox/VolumeSlider
@onready var volume_label: Label = $MenuContainer/MainMenu/VBox/VolumeLabel
@onready var continue_button: Button = $MenuContainer/MainMenu/VBox/ContinueButton

func _ready() -> void:
	add_to_group("game_state_menus")
	# Enable processing during pause so menu buttons are clickable
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	hide_all()
	
	# Listen to game over signal
	FamilyManager.game_over.connect(show_game_over)
	
	# Connect buttons
	$MenuContainer/MainMenu/VBox/StartButton.text = "RESUME"
	$MenuContainer/MainMenu/VBox/StartButton.pressed.connect(_on_start_pressed)
	$MenuContainer/MainMenu/VBox/QuitButton.text = "RETURN TO MAIN MENU"
	$MenuContainer/MainMenu/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$MenuContainer/GameOverScreen/VBox/RetryButton.pressed.connect(_on_retry_pressed)
	$MenuContainer/VictoryScreen/VBox/RestartButton.pressed.connect(_on_retry_pressed)
	
	if is_instance_valid(continue_button):
		continue_button.visible = false
	
	# Connect volume controls
	if is_instance_valid(volume_slider):
		volume_slider.value = SoundManager.master_volume
		volume_slider.value_changed.connect(_on_volume_changed)
		_update_volume_label(volume_slider.value)

func hide_all() -> void:
	main_menu.visible = false
	game_over_screen.visible = false
	victory_screen.visible = false

func show_main_menu() -> void:
	hide_all()
	main_menu.visible = true
	get_tree().paused = true

func show_game_over() -> void:
	hide_all()
	game_over_screen.visible = true
	get_tree().paused = true

func show_victory(saved_count: int) -> void:
	hide_all()
	victory_screen.visible = true
	score_label.text = "FAMILY MEMBERS ESCAPED: %d" % saved_count
	get_tree().paused = true

func _on_start_pressed() -> void:
	hide_all()
	get_tree().paused = false

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if game_over_screen.visible or victory_screen.visible:
			return
		
		get_viewport().set_input_as_handled()
		if main_menu.visible:
			_on_start_pressed()
		else:
			show_main_menu()

func _on_continue_pressed() -> void:
	var level_path := SaveManager.load_level()
	if level_path != "":
		hide_all()
		get_tree().paused = false
		get_tree().change_scene_to_file(level_path)

func _on_retry_pressed() -> void:
	hide_all()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_volume_changed(value: float) -> void:
	SoundManager.set_master_volume(value)
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	if is_instance_valid(volume_label):
		volume_label.text = "VOLUME: %d%%" % int(value * 100.0)
