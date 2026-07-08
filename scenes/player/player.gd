class_name Player
extends CharacterBody3D

## Speed of the player movement along the X axis.
@export_group("Movement Settings")
@export var speed: float = 5.0

## Velocity applied upwards when the player jumps.
@export var jump_velocity: float = 6.0

# Fetch default gravity from project settings to sync with standard physics behavior.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _physics_process(delta: float) -> void:
	# Apply gravity if not grounded.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Handle jump action.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the left/right input axis.
	var input_axis: float = Input.get_axis("move_left", "move_right")
	
	# Restrict motion to the X-axis for 2.5D movement.
	var direction: Vector3 = Vector3(input_axis, 0.0, 0.0).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	# Lock Z velocity to prevent depth movement.
	velocity.z = 0.0

	# Call Godot's built-in physics solver.
	move_and_slide()

	# Lock Z position strictly to 0.0 to prevent drifting over time.
	global_position.z = 0.0
