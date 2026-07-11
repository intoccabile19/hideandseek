class_name BraceGate
extends Interactable

signal gate_braced(is_braced: bool)

@export var wall_body_path: NodePath

func _ready() -> void:
	super._ready()
	required_class = "Adult"
	prompt_message = "Brace Gate"

func execute_interaction(actor: Node3D) -> void:
	if actor.has_method("brace_gate"):
		actor.call("brace_gate", self)

func set_gate_open(open_state: bool) -> void:
	gate_braced.emit(open_state)
	print("[BraceGate %s] Open state set to: %s" % [name, str(open_state)])
	
	if not wall_body_path.is_empty():
		var wall := get_node_or_null(wall_body_path) as Node3D
		if wall:
			var tween := create_tween()
			var target_pos := wall.position
			if open_state:
				target_pos.y = 4.0 # Raised / Open height
			else:
				target_pos.y = 1.0 # Dropped / Closed height
			tween.tween_property(wall, "position", target_pos, 0.4)
			
			# Disable collisions when raised, enable when closed
			if wall is CollisionObject3D:
				wall.process_mode = PROCESS_MODE_DISABLED if open_state else PROCESS_MODE_INHERIT
