class_name Elder
extends FamilyMember

var _hack_console: HackConsole = null
var _hack_ui: CanvasLayer = null
var _hack_cursor: float = 0.0
var _hack_dir: float = 1.0
var _hack_speed: float = 1.3
var _sweet_spot_min: float = 0.35
var _sweet_spot_max: float = 0.65
var _slider_pointer: ColorRect = null

func _ready() -> void:
	super._ready()
	# Override base defaults for the elder subclass
	speed = 2.0
	spacing_steps = 16
	jump_velocity = 0.0 # Disabled

func get_size_class() -> String:
	return "Medium"

## Declares to the manager that this class is an Elder.
func is_elder_class() -> bool:
	return true

## Start systems hacking terminal minigame
func start_hacking(console: HackConsole) -> void:
	if _hack_ui != null:
		return
	_hack_console = console
	FamilyManager.is_hacking = true
	current_state = State.FREEZE
	velocity = Vector3.ZERO
	_hack_cursor = 0.0
	_hack_dir = 1.0
	
	# Pause the rest of the game tree
	get_tree().paused = true
	process_mode = PROCESS_MODE_ALWAYS
	
	# Instantiate Hacking UI CanvasLayer programmatically
	_hack_ui = CanvasLayer.new()
	_hack_ui.process_mode = PROCESS_MODE_ALWAYS
	
	var base_panel := Panel.new()
	base_panel.name = "HackingPanel"
	base_panel.custom_minimum_size = Vector2(400, 150)
	base_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_hack_ui.add_child(base_panel)
	
	var label := Label.new()
	label.text = "ELDER OVERLOAD HACK\nPress 'F' or Interact inside the Green Zone!"
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.position.y += 15
	label.position.x -= 20 # center adjustments
	base_panel.add_child(label)
	
	# Horizontal slider track
	var track := ColorRect.new()
	track.color = Color(0.15, 0.15, 0.15)
	track.custom_minimum_size = Vector2(300, 20)
	track.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	track.position.y += 15
	base_panel.add_child(track)
	
	# Sweet Spot (Green zone: width 90, centered at 105)
	var sweet := ColorRect.new()
	sweet.color = Color(0.2, 0.7, 0.2)
	sweet.custom_minimum_size = Vector2(90, 20)
	sweet.position = Vector2(105, 0)
	track.add_child(sweet)
	
	# Pointer (Yellow slider bar)
	_slider_pointer = ColorRect.new()
	_slider_pointer.color = Color(1.0, 0.9, 0.1)
	_slider_pointer.custom_minimum_size = Vector2(8, 24)
	_slider_pointer.position = Vector2(0, -2)
	track.add_child(_slider_pointer)
	
	Engine.get_main_loop().root.add_child(_hack_ui)
	print("[Elder] Console hack minigame started.")

func _process(delta: float) -> void:
	if _hack_ui == null:
		return
		
	# Oscillate the sweet-spot cursor back and forth
	_hack_cursor += _hack_dir * _hack_speed * delta
	if _hack_cursor >= 1.0:
		_hack_cursor = 1.0
		_hack_dir = -1.0
	elif _hack_cursor <= 0.0:
		_hack_cursor = 0.0
		_hack_dir = 1.0
		
	if is_instance_valid(_slider_pointer):
		_slider_pointer.position.x = _hack_cursor * (300 - 8)

func _unhandled_input(event: InputEvent) -> void:
	if _hack_ui == null:
		return
		
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		# Set input as handled immediately to prevent Player or other objects from receiving it
		get_viewport().set_input_as_handled()
		
		if _hack_cursor >= _sweet_spot_min and _hack_cursor <= _sweet_spot_max:
			print("[Elder] Hacking success!")
			if is_instance_valid(_hack_console):
				_hack_console.complete_hack()
			_close_hacking()
		else:
			print("[Elder] Hacking failed! Alerting nearby Seeker and aborting...")
			SoundManager.play_chirp(global_position)
			FamilyManager.sound_emitted.emit(global_position, 12.0, true)
			_close_hacking()

func _close_hacking() -> void:
	if _hack_ui != null:
		_hack_ui.queue_free()
		_hack_ui = null
	_hack_console = null
	# Resume the game tree
	get_tree().paused = false
	process_mode = PROCESS_MODE_INHERIT
	# Defer resetting the flag to prevent same-frame input processing by the player
	FamilyManager.set_deferred("is_hacking", false)
	current_state = State.FOLLOW

func _on_command_broadcast(new_state_int: int) -> void:
	super._on_command_broadcast(new_state_int)
	# Cancel hacking if player commands us to move away/freeze
	if current_state == State.FOLLOW or current_state == State.FREEZE:
		_close_hacking()
