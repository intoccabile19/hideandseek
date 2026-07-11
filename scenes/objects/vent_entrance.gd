class_name VentEntrance
extends Interactable

@export var connected_exit_path: NodePath

func _ready() -> void:
	super._ready()
	required_class = "Toddler"
	prompt_message = "Enter Vent"
	add_to_group("vents")

func execute_interaction(actor: Node3D) -> void:
	if actor.has_method("crawl_through_vent") and not connected_exit_path.is_empty():
		var exit_node = get_node_or_null(connected_exit_path)
		if exit_node:
			actor.call("crawl_through_vent", self, exit_node)
