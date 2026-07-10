extends CanvasLayer

@onready var command_label: Label = $HUDContainer/BottomPanel/CommandLabel
@onready var detection_bar: ProgressBar = $HUDContainer/TopPanel/VBox/DetectionBar
@onready var warning_label: Label = $HUDContainer/TopPanel/VBox/WarningLabel

var _seeker: Seeker = null

func _ready() -> void:
	# Listen to family commands
	FamilyManager.command_broadcast.connect(_on_command_broadcast)
	_update_command_text(0) # Default to FOLLOW
	
	# Find Seeker in scene
	_find_seeker()

func _process(_delta: float) -> void:
	if not is_instance_valid(_seeker):
		_find_seeker()
		return
		
	# Update detection bar based on seeker alert level
	var active_alert: float = _seeker.alert_level
	if _seeker.current_state == Seeker.State.CHASE or _seeker.current_state == Seeker.State.CAPTURE:
		active_alert = 1.0
		
	detection_bar.value = active_alert * 100.0
	
	# Update warning status text
	if _seeker.current_state == Seeker.State.CHASE:
		warning_label.text = "WARNING: SPOTTED!"
		warning_label.modulate = Color(1.0, 0.0, 0.0, 1.0) # Pulsing Red
	elif _seeker.current_state == Seeker.State.SUSPICIOUS:
		warning_label.text = "ALERT: INVESTIGATING..."
		warning_label.modulate = Color(1.0, 0.8, 0.0, 1.0) # Yellow
	elif active_alert > 0.05:
		warning_label.text = "CAUTION: SEARCHING..."
		warning_label.modulate = Color(0.9, 0.6, 0.1, 1.0) # Orange
	else:
		warning_label.text = "SYSTEM STATUS: SECURE"
		warning_label.modulate = Color(0.2, 0.8, 0.2, 1.0) # Green

func _find_seeker() -> void:
	var seekers := get_tree().get_nodes_in_group("seeker")
	if not seekers.is_empty():
		_seeker = seekers[0] as Seeker
	else:
		# Search by class name
		if get_tree().current_scene:
			for child in get_tree().current_scene.get_children():
				if child is Seeker:
					_seeker = child
					break

func _on_command_broadcast(new_state: int) -> void:
	_update_command_text(new_state)

func _update_command_text(state: int) -> void:
	if not is_instance_valid(command_label):
		return
	if state == 0: # State.FOLLOW
		command_label.text = "MODE: FOLLOW"
		command_label.modulate = Color(0.2, 0.8, 0.2, 1.0) # Green
	else: # State.FREEZE
		command_label.text = "MODE: FREEZE & HIDE"
		command_label.modulate = Color(1.0, 0.4, 0.0, 1.0) # Orange
