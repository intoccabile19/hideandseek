class_name ElevatorButton
extends Interactable

@export var elevator_path: NodePath

func _ready() -> void:
	super._ready()
	prompt_message = "Toggle Elevator"

func execute_interaction(actor: Node3D) -> void:
	if not elevator_path.is_empty():
		var elevator := get_node_or_null(elevator_path)
		if elevator and elevator.has_method("toggle_elevator"):
			elevator.call("toggle_elevator")
