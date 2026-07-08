class_name FamilyMember
extends CharacterBody3D

## States mapping to Follow, Freeze, and Hidden modes.
enum State { FOLLOW, FREEZE, HIDING }

@export_group("Escort Settings")
## The horizontal movement speed of this family member.
@export var speed: float = 3.8

## Jump velocity applied when attempting to traverse ledges or gaps.
@export var jump_velocity: float = 6.5

## Spacing gap (in frames/steps) behind the player in the historical path.
@export var spacing_steps: int = 15

## Current state of this member.
var current_state: State = State.FREEZE

# Gravity settings synchronized with default project parameters.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Cache state of floor status from the previous physics tick.
var _was_on_floor_last_frame: bool = true

func _ready() -> void:
	# Register self with the manager.
	FamilyManager.register_member(self)
	# Listen to player commands.
	FamilyManager.command_broadcast.connect(_on_command_broadcast)

func _exit_tree() -> void:
	# Unregister on removal.
	FamilyManager.unregister_member(self)

func _physics_process(delta: float) -> void:
	# Apply gravity.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Process queue tracking if in FOLLOW state and player is valid.
	if current_state == State.FOLLOW and FamilyManager.player:
		var p: Node3D = FamilyManager.player
		var follow_index: int = FamilyManager.get_follow_index(self)
		
		if follow_index != -1:
			var target_idx: int = (follow_index + 1) * spacing_steps
			var target_pos: Vector3 = p.global_position
			var target_grounded: bool = true
			
			# Extract player's coordinates history if available.
			if p.has_method("get_path_history"):
				var history: Array = p.call("get_path_history")
				if history.size() > target_idx:
					target_pos = history[target_idx]["position"]
					target_grounded = history[target_idx]["is_on_floor"]
				elif not history.is_empty():
					target_pos = history.back()["position"]
					target_grounded = history.back()["is_on_floor"]
			
			var to_target: Vector3 = target_pos - global_position
			to_target.z = 0.0 # Strict 2.5D constraint
			
			var dist_x: float = abs(to_target.x)
			
			# Drive X velocity to close distance.
			var move_dir: float = 0.0
			if dist_x > 0.2:
				move_dir = sign(to_target.x)
				velocity.x = move_dir * speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, speed)

			# Determine if the character needs to jump.
			var should_jump: bool = false
			
			# 1. Climbing jumps: Target is on a higher, grounded platform.
			if to_target.y > 0.5 and target_grounded and is_on_floor() and dist_x < 2.0:
				should_jump = true
			# 2. Obstacle jumps: Ran into a wall or step.
			elif is_on_wall() and is_on_floor():
				should_jump = true
			# 3. Gap jumps (Raycast): Look ahead to detect gap before walking off ledge.
			elif move_dir != 0.0 and is_on_floor():
				var space_state := get_world_3d().direct_space_state
				var origin := global_position + Vector3(move_dir * 0.5, 0.1, 0.0)
				var end := origin + Vector3(0.0, -1.5, 0.0) # Check 1.5 units down
				var query := PhysicsRayQueryParameters3D.create(origin, end, 1) # Mask 1 (World)
				var result := space_state.intersect_ray(query)
				if result.is_empty() and dist_x > 0.5:
					should_jump = true
			# 4. Gap jumps (Fallback): Just walked off a ledge while moving horizontally.
			elif not is_on_floor() and _was_on_floor_last_frame and velocity.x != 0.0:
				should_jump = true
				
			if should_jump:
				# Calculate context-aware jump velocity dynamically.
				var custom_jump_vel: float = jump_velocity
				
				if to_target.y > 0.5 and target_grounded:
					# Climbing: height-based physics formula: v = sqrt(2 * g * h)
					var req_height: float = to_target.y + 0.1 # Very tight 0.1 unit safety clearance
					custom_jump_vel = sqrt(2.0 * _gravity * req_height)
				elif to_target.y <= 0.5 and dist_x > 0.5:
					# Crossing a gap: distance-based physics formula: v = (g * t) / 2
					var req_time: float = dist_x / speed
					custom_jump_vel = (_gravity * req_time) / 2.0 + 0.2 # Tight 0.2 unit velocity safety buffer
					
				# Clamp between a small hop (2.0) and the max jump capacity (jump_velocity).
				velocity.y = clamp(custom_jump_vel, 2.0, jump_velocity)
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
	else:
		# Decay velocity to a halt when commanded to freeze/hide.
		velocity.x = move_toward(velocity.x, 0.0, speed)

	# Lock depth movement.
	velocity.z = 0.0

	# Cache current floor status before calling move_and_slide which resets is_on_floor().
	var is_currently_on_floor: bool = is_on_floor()

	move_and_slide()

	# Save for comparison in next frame.
	_was_on_floor_last_frame = is_currently_on_floor

	# Calculate Z-depth shifting to step back when player passes by.
	var target_z: float = 0.0
	if FamilyManager.player:
		var dist_x: float = abs(FamilyManager.player.global_position.x - global_position.x)
		if dist_x < 1.2:
			target_z = -0.6 # Step into the background

	# Smoothly lerp Z-axis to execute the visual step-back.
	global_position.z = lerp(global_position.z, target_z, delta * 12.0)

func _on_command_broadcast(new_state_int: int) -> void:
	current_state = new_state_int as State
	var state_name: String = "FOLLOW" if current_state == State.FOLLOW else "FREEZE"
	print("[Family Member %s] State transitioned to: %s" % [name, state_name])
