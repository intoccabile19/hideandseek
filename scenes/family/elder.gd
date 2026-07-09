class_name Elder
extends FamilyMember

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
