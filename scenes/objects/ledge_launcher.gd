class_name LedgeLauncher
extends Interactable

func _ready() -> void:
	super._ready()
	required_class = "Adult"
	prompt_message = "Launch Toddler"

func execute_interaction(actor: Node3D) -> void:
	if actor.has_method("try_launch_toddler"):
		actor.call("try_launch_toddler", self)
