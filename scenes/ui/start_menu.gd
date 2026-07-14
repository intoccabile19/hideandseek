extends Control

@onready var continue_button: Button = $MenuContainer/MainMenu/VBox/ContinueButton
@onready var volume_slider: HSlider = $MenuContainer/MainMenu/VBox/VolumeSlider
@onready var volume_label: Label = $MenuContainer/MainMenu/VBox/VolumeLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	$MenuContainer/MainMenu/VBox/StartButton.pressed.connect(_on_start_pressed)
	$MenuContainer/MainMenu/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	
	continue_button.visible = SaveManager.has_save()
	
	volume_slider.value = SoundManager.master_volume
	volume_slider.value_changed.connect(_on_volume_changed)
	_update_volume_label(volume_slider.value)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_1_tutorial.tscn")

func _on_continue_pressed() -> void:
	var level_path := SaveManager.load_level()
	if level_path != "":
		get_tree().change_scene_to_file(level_path)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	SoundManager.set_master_volume(value)
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	volume_label.text = "VOLUME: %d%%" % int(value * 100.0)
