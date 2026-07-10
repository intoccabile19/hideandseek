extends CanvasLayer

@onready var command_label: Label = $HUDContainer/BottomPanel/CommandLabel
@onready var detection_bar: ProgressBar = $HUDContainer/TopPanel/VBox/DetectionBar
@onready var warning_label: Label = $HUDContainer/TopPanel/VBox/WarningLabel

var _seeker: Seeker = null
var _last_command_state: int = 0

func _ready() -> void:
	# Listen to family commands
	FamilyManager.command_broadcast.connect(_on_command_broadcast)
	# Listen to target selection changes
	FamilyManager.target_changed.connect(_on_target_changed)
	
	_update_command_text(0) # Default to FOLLOW
	
	# Find Seeker in scene
	_find_seeker()

func _on_target_changed(_new_target: FamilyMember) -> void:
	_update_command_text(_last_command_state)

func _process(_delta: float) -> void:
	if not is_instance_valid(_seeker):
		_find_seeker()
		
	# Update detection bar based on seeker alert level
	var active_alert: float = 0.0
	if is_instance_valid(_seeker):
		active_alert = _seeker.alert_level
		if _seeker.current_state == Seeker.State.CHASE or _seeker.current_state == Seeker.State.CAPTURE:
			active_alert = 1.0
		
	detection_bar.value = active_alert * 100.0
	
	# Update warning status text
	if is_instance_valid(_seeker):
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
	else:
		warning_label.text = "SYSTEM STATUS: SECURE"
		warning_label.modulate = Color(0.2, 0.8, 0.2, 1.0)
		
	# Continuously update the escape progress in target string
	_update_command_text(_last_command_state)

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
	_last_command_state = new_state
	_update_command_text(new_state)

func _update_command_text(state: int) -> void:
	if not is_instance_valid(command_label):
		return
		
	var mode_str: String = "FOLLOW" if state == 0 else "FREEZE & HIDE"
	var target_str: String = "ALL"
	
	if FamilyManager.current_target_member != null and is_instance_valid(FamilyManager.current_target_member):
		var target_idx: int = FamilyManager.active_members.find(FamilyManager.current_target_member)
		target_str = "MEMBER %d (%s)" % [target_idx + 1, FamilyManager.current_target_member.name.to_upper()]
		
	# Escape progress tally
	var escape_progress_str: String = ""
	var escape_zones = get_tree().get_nodes_in_group("escape_zones")
	if not escape_zones.is_empty():
		var zone = escape_zones[0]
		if "escaped_members" in zone:
			var escaped_count: int = zone.escaped_members.size()
			var total_count: int = FamilyManager.active_members.size()
			escape_progress_str = " | SAFE: %d/%d" % [escaped_count, total_count]
			
	var loudness_info: Dictionary = FamilyManager.get_projected_command_loudness()
	var loudness_type: String = "SHOUT" if loudness_info.is_shout else "WHISPER"
	var loudness_str := " | LOUDNESS: %s (%0.1fm)" % [loudness_type, loudness_info.radius]
	
	command_label.text = "MODE: %s | TARGET: %s%s%s" % [mode_str, target_str, escape_progress_str, loudness_str]
	
	if state == 0: # State.FOLLOW
		command_label.modulate = Color(0.2, 0.8, 0.2, 1.0) # Green
	else: # State.FREEZE
		command_label.modulate = Color(1.0, 0.4, 0.0, 1.0) # Orange
