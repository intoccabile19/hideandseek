class_name PushableBoxInteractable
extends Interactable

func _ready() -> void:
	super._ready()
	required_class = "Adult"
	prompt_message = "Push Crate"
	interaction_offset_x = 0.8

func execute_interaction(actor: Node3D) -> void:
	var box := get_parent() as RigidBody3D
	if is_instance_valid(box) and actor.has_method("command_push_box"):
		var push_dir := 1.0
		var player := FamilyManager.player
		if player and player.global_position.x > box.global_position.x:
			push_dir = -1.0
			
		actor.call("command_push_box", box, push_dir)
