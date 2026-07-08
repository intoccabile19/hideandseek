class_name Player
extends CharacterBody3D

## Speed of the player movement along the X axis.
@export_group("Movement Settings")
@export var speed: float = 5.0

## Velocity applied upwards when the player jumps.
@export var jump_velocity: float = 6.0

# Fetch default gravity from project settings to sync with standard physics behavior.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Coordinates history tracked for the trailing family queue.
var _path_history: Array = []

# Tracks the direction of movement to trigger dynamic queue ordering.
var _last_dir_sign: float = 0.0

func _ready() -> void:
	# Register player with family manager autoload.
	FamilyManager.register_player(self)
	# Push initial position into path history.
	_path_history.push_front({"position": global_position, "is_on_floor": is_on_floor()})

func _exit_tree() -> void:
	# Clean up player registration.
	FamilyManager.unregister_player()

## Returns the array of recent historical coordinates.
func get_path_history() -> Array:
	return _path_history

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("command_follow"):
		FamilyManager.broadcast_follow(global_position)
	elif event.is_action_pressed("command_freeze"):
		FamilyManager.broadcast_freeze(global_position)

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

	# Sort queue dynamically if direction has changed to avoid scrambling.
	var current_dir_sign: float = sign(velocity.x)
	if current_dir_sign != 0.0 and current_dir_sign != _last_dir_sign:
		_last_dir_sign = current_dir_sign
		FamilyManager.update_queue_order()

	# Record position in history if player moves past minimum threshold.
	# We record a point every 0.08 units of distance to maintain high path resolution during jumps.
	if _path_history.is_empty() or global_position.distance_to(_path_history[0]["position"]) > 0.08:
		_path_history.push_front({"position": global_position, "is_on_floor": is_on_floor()})
		if _path_history.size() > 500:
			_path_history.pop_back()


