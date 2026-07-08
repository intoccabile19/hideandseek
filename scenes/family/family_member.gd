class_name FamilyMember
extends CharacterBody3D

## States mapping to Follow, Freeze, Hidden, Wandering, and Pushing modes.
enum State { FOLLOW, FREEZE, HIDING, WANDER, PUSHING }

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
			var custom_jump_vel: float = jump_velocity
			var landing_x: float = global_position.x
			var space_state := get_world_3d().direct_space_state
			
			# 1. Climbing jumps: Target is on a higher, grounded platform.
			if to_target.y > 0.5 and target_grounded and is_on_floor() and dist_x < 2.0:
				should_jump = true
				# Calculate required height-based velocity
				var req_height: float = to_target.y + 0.1
				custom_jump_vel = sqrt(2.0 * _gravity * req_height)
				# Calculate landing spot
				var time_in_air := 2.0 * custom_jump_vel / _gravity
				landing_x = global_position.x + move_dir * speed * time_in_air

			# 2. Obstacle jumps: Ran into a wall or step.
			elif is_on_wall() and is_on_floor() and move_dir != 0.0:
				# Check if the wall is a pushable box.
				var is_pushable_wall: bool = false
				for i in get_slide_collision_count():
					var collision := get_slide_collision(i)
					var collider := collision.get_collider()
					if collider is RigidBody3D:
						is_pushable_wall = true
						break
				
				# Adults push the box horizontally; other subclasses (like Toddlers) jump over it.
				if not is_pushable_wall or not (self is Adult):
					# Scan upwards to determine exact obstacle height
					var obstacle_height: float = 0.0
					for step in range(1, 15):
						var y_offset: float = step * 0.15
						var origin := global_position + Vector3(0.0, y_offset, 0.0)
						var end := origin + Vector3(move_dir * 0.8, 0.0, 0.0)
						var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
						var result := space_state.intersect_ray(query)
						if result.is_empty():
							obstacle_height = y_offset
							break
					
					if obstacle_height > 0.0 and obstacle_height < 2.2:
						should_jump = true
						# Exact velocity to clear height
						custom_jump_vel = sqrt(2.0 * _gravity * (obstacle_height + 0.1))
						var time_in_air := 2.0 * custom_jump_vel / _gravity
						landing_x = global_position.x + move_dir * speed * time_in_air

			# 3. Gap jumps (Raycast): Look ahead to detect gap before walking off ledge.
			elif move_dir != 0.0 and is_on_floor():
				var origin := global_position + Vector3(move_dir * 0.5, 0.1, 0.0)
				var end := origin + Vector3(0.0, -1.5, 0.0)
				var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
				var result := space_state.intersect_ray(query)
				if result.is_empty() and dist_x > 0.5:
					# Scan forward to find the other side of the gap
					var gap_width: float = 0.0
					for step in range(1, 15):
						var check_offset := 0.5 + step * 0.4
						var gap_origin := global_position + Vector3(move_dir * check_offset, 0.5, 0.0)
						var gap_end := gap_origin + Vector3(0.0, -2.0, 0.0)
						var gap_query := PhysicsRayQueryParameters3D.create(gap_origin, gap_end, 1)
						var gap_result := space_state.intersect_ray(gap_query)
						if not gap_result.is_empty():
							gap_width = check_offset
							break
					
					if gap_width > 0.0:
						# Required time to clear the width plus landing buffer
						var clear_dist := gap_width + 0.3
						var req_time := clear_dist / speed
						var req_vel := (_gravity * req_time) / 2.0
						
						# Check if we can physically make the jump
						if req_vel <= jump_velocity:
							should_jump = true
							custom_jump_vel = req_vel
							landing_x = global_position.x + move_dir * clear_dist
			
			# 4. Gap jumps (Fallback): Just walked off a ledge while moving horizontally.
			elif not is_on_floor() and _was_on_floor_last_frame and velocity.x != 0.0:
				should_jump = true
				# Use fallback default jump
				custom_jump_vel = jump_velocity
				var time_in_air := 2.0 * custom_jump_vel / _gravity
				landing_x = global_position.x + move_dir * speed * time_in_air

			# Perform landing safety check if a jump was requested
			if should_jump:
				var land_origin := Vector3(landing_x, 1.0, 0.0)
				var land_end := land_origin + Vector3(0.0, -3.0, 0.0)
				var land_query := PhysicsRayQueryParameters3D.create(land_origin, land_end, 1)
				var land_result := space_state.intersect_ray(land_query)
				
				# If there is no floor at the projected landing spot, cancel the jump!
				if land_result.is_empty():
					should_jump = false
					velocity.x = 0.0 # Stop at the edge
					
			if should_jump:
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
	if current_state == State.FREEZE:
		print("[Family Member %s] State transitioned to: FREEZE" % name)
	elif current_state == State.FOLLOW:
		print("[Family Member %s] State transitioned to: FOLLOW" % name)

## Returns true if this subclass is of type Adult.
func is_adult_class() -> bool:
	return false
