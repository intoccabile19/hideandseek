class_name Interactable
extends Area3D

## The class name required to interact: "Adult", "Toddler", "Elder", or "Any".
@export var required_class: String = "Any"

## The display label prompt (e.g., "Push Crate", "Hack Console").
@export var prompt_message: String = "Interact"

## The horizontal offset (in units) the actor should align to relative to this object's X center.
@export var interaction_offset_x: float = 0.8

## Execute the interaction. Overridden by specific interactable components.
func execute_interaction(actor: Node3D) -> void:
	pass

func _ready() -> void:
	add_to_group("interactables")

func _exit_tree() -> void:
	remove_from_group("interactables")
