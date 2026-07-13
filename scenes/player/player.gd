class_name Player
extends CharacterBody3D

@export_group("Animations")
@export var anim_idle: String = "Player/player_idle"
@export var anim_move: String = "Player/player_run"
@export var anim_jump: String = "Player/player_jump"
@export var anim_hide: String = ""
@export var anim_interact_1: String = "Player/player_climb"
@export var anim_interact_2: String = "Player/player_throw"
@export var anim_interact_3: String = ""

## Speed of the player movement along the X axis.
@export_group("Movement Settings")
@export var speed: float = 5.0

## Velocity applied upwards when the player jumps.
@export var jump_velocity: float = 6.0

## Force applied continuously when pushing RigidBody3D obstacles.
@export var push_force: float = 600.0

var _throw_timer: float = 0.0

var _last_freeze_press_time: float = 0.0
const DOUBLE_TAP_WINDOW: float = 0.35

func _play_anim(anim_name: String) -> void:
	if anim_name.is_empty():
		return
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if is_instance_valid(anim_player):
		if anim_player.has_animation(anim_name):
			if anim_player.current_animation != anim_name:
				anim_player.play(anim_name)

# Fetch default gravity from project settings to sync with standard physics behavior.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Coordinates history tracked for the trailing family queue.
var _path_history: Array = []

# Tracks the direction of movement to trigger dynamic queue ordering.
var _last_dir_sign: float = 0.0

var is_hidden: bool = false
var _assigned_cover: CoverZone = null
var _cover_target_x: float = 0.0

# Phase 8 properties
var _climbable_areas: Array[Area3D] = []
var _is_climbing: bool = false
var facing_direction: float = 1.0
var _original_collision_mask: int = 1
var _climbing_direction: float = 0.0
var _climb_target_y: float = 0.0

func _ready() -> void:
	# Register player with family manager autoload.
	FamilyManager.register_player(self)
	_original_collision_mask = collision_mask
	# Push initial position into path history.
	_path_history.push_front({"position": global_position, "is_on_floor": is_on_floor()})

	# Programmatic ladder/rope detector Area3D
	var detector := Area3D.new()
	detector.name = "ClimbDetector"
	detector.collision_layer = 0
	detector.collision_mask = 0xFFFFFFFF # Match all collision areas
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 1.8, 0.6)
	shape.shape = box
	detector.add_child(shape)
	add_child(detector)
	
	detector.area_entered.connect(func(area: Area3D):
		if area.is_in_group("ladders") or area.is_in_group("ropes"):
			_climbable_areas.append(area)
	)
	detector.area_exited.connect(func(area: Area3D):
		if area in _climbable_areas:
			_climbable_areas.erase(area)
			if _climbable_areas.is_empty():
				_set_climbing(false)
	)

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
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_freeze_press_time < DOUBLE_TAP_WINDOW:
			FamilyManager.broadcast_freeze(global_position)
			_last_freeze_press_time = 0.0
		else:
			FamilyManager.broadcast_stop(global_position)
			_last_freeze_press_time = now
		SoundManager.play_whistle()
	elif event.is_action_pressed("hide_action"):
		if _assigned_cover:
			_release_cover()
		else:
			_try_hide_in_current_cover()
	elif event.is_action_pressed("interact"):
		if FamilyManager.is_hacking:
			return
		_try_interact()
	elif event.is_action_pressed("target_all"):
		FamilyManager.select_target_by_index(-1)
	elif event.is_action_pressed("target_member_1"):
		FamilyManager.select_target_by_index(0)
	elif event.is_action_pressed("target_member_2"):
		FamilyManager.select_target_by_index(1)
	elif event.is_action_pressed("target_member_3"):
		FamilyManager.select_target_by_index(2)
	elif event.is_action_pressed("throw_pebble"):
		_throw_pebble()

func _physics_process(delta: float) -> void:
	# Handle Slow-Mo Focus
	if Input.is_action_pressed("focus_action"):
		Engine.time_scale = 0.25
	else:
		Engine.time_scale = 1.0

	# Read input signals
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var v_axis := Input.get_axis("move_up", "move_down")

	# Track horizontal facing direction
	if input_axis > 0.1:
		facing_direction = 1.0
	elif input_axis < -0.1:
		facing_direction = -1.0

	# Handle ladder entry criteria
	if not _is_climbing:
		if not _climbable_areas.is_empty():
			var ladder := _climbable_areas[0]
			var shape: BoxShape3D = ladder.get_node("CollisionShape3D").shape
			var half_height := shape.size.y * ladder.scale.y * 0.5
			var ladder_top_y := ladder.global_position.y + half_height
			var ladder_bottom_y := ladder.global_position.y - half_height
			
			if Input.is_action_pressed("move_up") and global_position.y <= ladder.global_position.y + 0.1:
				_climbing_direction = 1.0
				_climb_target_y = ladder_top_y + 0.05
				_set_climbing(true)
			elif Input.is_action_pressed("move_down") and global_position.y >= ladder.global_position.y - 0.1:
				_climbing_direction = -1.0
				_climb_target_y = ladder_bottom_y - 0.2
				_set_climbing(true)

	# Apply gravity if not grounded or climbing.
	if not is_on_floor() and not _is_climbing:
		velocity.y -= _gravity * delta

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
	elif _is_climbing:
		# Process climbing movement automatically to destination Y
		global_position.y = move_toward(global_position.y, _climb_target_y, speed * 1.1 * delta)
		
		# Lock Z and X coordinate alignment with the ladder
		if not _climbable_areas.is_empty():
			var ladder := _climbable_areas[0]
			global_position.x = ladder.global_position.x
			global_position.z = ladder.global_position.z
			
		# Check arrival
		if abs(global_position.y - _climb_target_y) < 0.15:
			global_position.y = _climb_target_y
			_set_climbing(false)
			return
			
		# Allow jumping off mid-climb
		if jump_pressed:
			_set_climbing(false)
			velocity.y = jump_velocity
			velocity.x = input_axis * speed
			return
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
			
	# Process animation selection
	if _throw_timer > 0.0:
		_throw_timer -= delta
		_play_anim(anim_interact_2)
	elif _is_climbing:
		_play_anim(anim_interact_1)
	elif not is_on_floor():
		_play_anim(anim_jump)
	elif _assigned_cover:
		_play_anim(anim_hide)
	elif abs(velocity.x) > 0.1:
		_play_anim(anim_move)
	else:
		_play_anim(anim_idle)

	# Update visual rotation to match facing direction
	var target_yaw := PI / 2.0 if facing_direction > 0.0 else -PI / 2.0
	for child in get_children():
		if child is Skeleton3D:
			child.rotation.y = lerp_angle(child.rotation.y, target_yaw, delta * 12.0)

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

## Instantiates and launches a pebble projectile in the current facing direction
func _throw_pebble() -> void:
	_throw_timer = 0.4
	var pebble_script := load("res://scenes/objects/pebble.gd")
	var pebble = pebble_script.new()
	pebble.global_position = global_position + Vector3(facing_direction * 0.6, 1.2, 0.0)
	Engine.get_main_loop().root.add_child(pebble)
	
	# Vector points slightly upwards to form a natural arc
	var launch_vector := Vector3(facing_direction, 0.6, 0.0).normalized()
	pebble.launch(launch_vector)
	print("[Player] Threw Pebble distraction in direction: %0.1f" % facing_direction)

func _set_climbing(climbing: bool) -> void:
	if _is_climbing == climbing:
		return
	_is_climbing = climbing
	if _is_climbing:
		_release_cover()
		# Disable Layer 1 collision so we can climb through platforms
		collision_mask &= ~1
	else:
		# Restore original collision mask
		collision_mask = _original_collision_mask
		# Snap to floor if we climbed off the top of the ladder
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(
			global_position + Vector3(0.0, 0.5, 0.0),
			global_position + Vector3(0.0, -1.5, 0.0),
			1
		)
		var result := space_state.intersect_ray(query)
		if not result.is_empty():
			global_position.y = result.position.y + 0.05

