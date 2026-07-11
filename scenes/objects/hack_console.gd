class_name HackConsole
extends Interactable

@export var is_sleep_overload: bool = false
@export var target_gate_path: NodePath

signal hack_completed

func _ready() -> void:
	super._ready()
	required_class = "Elder"
	prompt_message = "Hack Console"

func execute_interaction(actor: Node3D) -> void:
	if actor.has_method("start_hacking"):
		actor.call("start_hacking", self)

func complete_hack() -> void:
	hack_completed.emit()
	print("[HackConsole %s] Hack completed successfully!" % name)
	
	# Open target gate if configured
	if not target_gate_path.is_empty():
		var gate = get_node_or_null(target_gate_path)
		if gate and gate.has_method("set_gate_open"):
			gate.call("set_gate_open", true)
			
	# If this is a sleep overload, stun all seekers in the level
	if is_sleep_overload:
		var seekers = get_tree().get_nodes_in_group("seekers")
		for seeker in seekers:
			if seeker.has_method("put_to_sleep"):
				seeker.call("put_to_sleep", 8.0) # 8 seconds sleep duration
