class_name PressurePlate
extends Interactable

@export var target_gate_path: NodePath
@export var linked_terminal_path: NodePath
## If true, this plate only triggers when a heavy weight (like Player, Adult, or Box) steps on it.
@export var requires_heavy_weight: bool = false
## If true, stepping on the plate deactivates the target (e.g. closes a door).
@export var invert_trigger: bool = false

signal plate_pressed(is_pressed: bool)

var _overlapping_bodies: Array[Node3D] = []
var is_disabled: bool = false

func _init() -> void:
	required_class = "Toddler"
	prompt_message = "Send Toddler to Bypass"

func _ready() -> void:
	super._ready()
	collision_layer = 0
	collision_mask = 7 # Detect Layer 1 (default/boxes), Layer 2 (Player), and Layer 3 (Hiders)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func execute_interaction(actor: Node3D) -> void:
	if is_disabled:
		return
	if actor.has_method("is_toddler_class") and actor.call("is_toddler_class"):
		if not linked_terminal_path.is_empty():
			var terminal := get_node_or_null(linked_terminal_path)
			if terminal:
				print("[PressurePlate %s] Redirecting Toddler %s to linked terminal: %s" % [name, actor.name, terminal.name])
				actor.call("interact_with", terminal, 0.0)

func disable_plate() -> void:
	is_disabled = true
	_overlapping_bodies.clear()
	# Restore to default unpressed state (which is invert_trigger)
	_activate_target(invert_trigger)
	plate_pressed.emit(invert_trigger)
	print("[PressurePlate %s] Plate has been permanently disabled!" % name)

func _on_body_entered(body: Node3D) -> void:
	if is_disabled:
		return
	# Filter out Toddlers if we require heavy weight
	if requires_heavy_weight:
		if body.has_method("is_toddler_class") and body.call("is_toddler_class"):
			print("[PressurePlate %s] Ignored toddler %s (too light!)" % [name, body.name])
			return
	
	_overlapping_bodies.append(body)
	if _overlapping_bodies.size() == 1:
		var target_state := not invert_trigger
		print("[PressurePlate %s] Emitting plate_pressed(%s)" % [name, str(target_state)])
		plate_pressed.emit(target_state)
		_activate_target(target_state)

func _on_body_exited(body: Node3D) -> void:
	if is_disabled:
		return
	if body in _overlapping_bodies:
		_overlapping_bodies.erase(body)
		if _overlapping_bodies.is_empty():
			var target_state := invert_trigger
			plate_pressed.emit(target_state)
			_activate_target(target_state)

func _activate_target(state: bool) -> void:
	if not target_gate_path.is_empty():
		var target := get_node_or_null(target_gate_path)
		if target and target.has_method("set_gate_open"):
			target.call("set_gate_open", state)
