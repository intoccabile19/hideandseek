class_name Elder
extends FamilyMember

func _ready() -> void:
	super._ready()
	# Override base defaults for the elder subclass
	speed = 2.0
	spacing_steps = 22
	jump_velocity = 0.0 # Disabled

## Declares to the manager that this class is an Elder.
func is_elder_class() -> bool:
	return true
