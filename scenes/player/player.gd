class_name Player
extends CharacterBody3D

## Speed of the player movement along the X axis.
@export_group("Movement Settings")
@export var speed: float = 5.0

## Velocity applied upwards when the player jumps.
@export var jump_velocity: float = 6.0

## Force applied continuously when pushing RigidBody3D obstacles.
@export var push_force: float = 600.0

# Fetch default gravity from project settings to sync with standard physics behavior.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Coordinates history tracked for the trailing family queue.
var _path_history: Array = []

# Tracks the direction of movement to trigger dynamic queue ordering.
var _last_dir_sign: float = 0.0

var is_hidden: bool = false
var _assigned_cover: CoverZone = null
var _cover_target_x: float = 0.0

func _ready() -> void:
	# Register player with family manager autoload.
	FamilyManager.register_player(self)
	# Push initial position into path history.
	_path_history.push_front({"position": global_position, "is_on_floor": is_on_floor()})

func _exit_tree() -> void:
	# Clean up player registration.
	_release_cover()
	FamilyManager.unregister_player()

## Returns the array of recent historical coordinates.
func get_path_history() -> Array:
	return _path_history

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("command_follow"):
		FamilyManager.broadcast_follow(global_position)
		SoundManager.play_whistle()
		_release_cover()
	elif event.is_action_pressed("command_freeze"):
		FamilyManager.broadcast_freeze(global_position)
		SoundManager.play_whistle()
	elif event.is_action_pressed("hide_action"):
		if _assigned_cover:
			_release_cover()
		else:
			_try_hide_in_current_cover()
	elif event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	# Apply gravity if not grounded.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Read input signals
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var jump_pressed := Input.is_action_just_pressed("jump")

	# Cancel cover state if player attempts manual movement override
	if (input_axis != 0.0 or jump_pressed) and _assigned_cover:
		_release_cover()

	# Process movement controls
	if _assigned_cover:
		# Lock player in place horizontally while hiding
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		
		# Step back to cover Z depth
		var target_z := _assigned_cover.global_position.z
		global_position.z = lerp(global_position.z, target_z, delta * 12.0)
		if abs(global_position.z - target_z) < 0.01:
			global_position.z = target_z
	else:
		# Manual navigation controls
		if jump_pressed and is_on_floor():
			velocity.y = jump_velocity

		var direction := Vector3(input_axis, 0.0, 0.0).normalized()
		if direction != Vector3.ZERO:
			velocity.x = direction.x * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)

		velocity.z = 0.0
		move_and_slide()

		# Standard Z-axis depth lock
		var target_z: float = 0.0
		global_position.z = lerp(global_position.z, target_z, delta * 12.0)
		if abs(global_position.z - target_z) < 0.01:
			global_position.z = target_z

	# Sort queue dynamically if direction has changed to avoid scrambling.
	var current_dir_sign: float = sign(velocity.x)
	if current_dir_sign != 0.0 and current_dir_sign != _last_dir_sign:
		_last_dir_sign = current_dir_sign
		FamilyManager.update_queue_order()

	# Record position in history if player moves past minimum threshold.
	if _path_history.is_empty() or global_position.distance_to(_path_history[0]["position"]) > 0.08:
		_path_history.push_front({"position": global_position, "is_on_floor": is_on_floor()})
		if _path_history.size() > 500:
			_path_history.pop_back()

## Checks if there is a cover zone behind/overlapping the player and steps into it if present
func _try_hide_in_current_cover() -> void:
	var cover := _find_overlapping_cover()
	if cover:
		_assigned_cover = cover
		_cover_target_x = global_position.x
		is_hidden = true
		print("[Player] Stepped back into cover at X: %0.2f" % _cover_target_x)
	else:
		print("[Player] No cover zone detected behind the player to hide!")

## Releases the player from their assigned cover slot
func _release_cover() -> void:
	if _assigned_cover:
		_assigned_cover.release_actor(self)
		_assigned_cover = null
	is_hidden = false

## Scans for an overlapping CoverZone
func _find_overlapping_cover() -> CoverZone:
	var zones: Array = get_tree().get_nodes_in_group("cover_zones")
	for zone in zones:
		if zone is CoverZone:
			# Calculate the horizontal half-width of the cover zone's collision shape
			var half_width: float = 1.5 # Default fallback
			var col_shape := zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col_shape and col_shape.shape is BoxShape3D:
				half_width = col_shape.shape.size.x * 0.5
				
			# Check if the player's horizontal X position is within the cover bounds
			var dist_x: float = abs(zone.global_position.x - global_position.x)
			if dist_x <= half_width:
				# Player (Medium size) can hide in Medium or Large cover zones regardless of companion capacity
				if zone.zone_size == "Medium" or zone.zone_size == "Large":
					return zone
	return null

## Attempts to find and command the nearest matching companion to interact with the adjacent object.
func _try_interact() -> void:
	var target := _find_nearest_interactable()
	if target:
		var actor = FamilyManager.get_nearest_member_of_class(target.required_class, global_position)
		if actor:
			# Determine interaction direction relative to player's position
			var interact_dir := 1.0
			if global_position.x > target.global_position.x:
				interact_dir = -1.0
			
			# Send directed command to companion
			actor.interact_with(target, interact_dir)
			print("[Player] Commanded %s to interact with %s in direction %0.1f" % [actor.name, target.name, interact_dir])
		else:
			print("[Player] No companion of class %s nearby to interact!" % target.required_class)
	else:
		print("[Player] No interactable object nearby!")

## Scans for an Interactable component area within 2.5m.
func _find_nearest_interactable() -> Interactable:
	var nearest: Interactable = null
	var min_dist: float = 2.5
	
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is Interactable:
			var dist := global_position.distance_to(node.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = node
				
	return nearest
