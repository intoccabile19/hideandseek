class_name Adult
extends FamilyMember

@export_group("Adult Settings")
## Speed of horizontal movement while pushing.
@export var push_speed: float = 1.8

var _push_target_box: RigidBody3D = null
var _push_dir: float = 0.0
var _is_aligned: bool = false
var _align_move_dir: float = 0.0

func _ready() -> void:
	super._ready()
	# Override base defaults for the adult subclass
	speed = 3.8
	spacing_steps = 15

## Declares to the manager that this class is an Adult.
func is_adult_class() -> bool:
	return true

## Commands the Adult to push a specific box in a direction.
func command_push_box(box: RigidBody3D, direction: float) -> void:
	if is_instance_valid(box):
		_push_target_box = box
		_push_dir = direction
		_is_aligned = false
		_align_move_dir = 0.0
		current_state = State.PUSHING
		print("[Adult %s] Commanded to push box %s in direction %f (walking to position)" % [name, box.name, direction])

func _physics_process(delta: float) -> void:
	if current_state == State.PUSHING:
		# If target box is destroyed or lost, abort.
		if not is_instance_valid(_push_target_box):
			_stop_pushing()
			return
			
		var space_state := get_world_3d().direct_space_state
		
		if not _is_aligned:
			# 1. ALIGNMENT PHASE: Walk to the pushing side of the box
			var box_target_x: float = _push_target_box.global_position.x - _push_dir * 0.8
			var to_target_x: float = box_target_x - global_position.x
			var dist_x: float = abs(to_target_x)
			
			# Verify if we are vertically aligned with the box's bottom (feet on the same ground level)
			var box_bottom_y := _push_target_box.global_position.y - 0.6
			var vertically_aligned: bool = abs(global_position.y - box_bottom_y) < 0.4
			
			# Verify if we are on the correct side of the box to perform the push
			var on_correct_side := false
			if _push_dir == 1.0 and global_position.x < _push_target_box.global_position.x:
				on_correct_side = true
			elif _push_dir == -1.0 and global_position.x > _push_target_box.global_position.x:
				on_correct_side = true
			
			# Only update horizontal moving direction if we are grounded on the actual floor level.
			var move_dir: float = 0.0
			if is_on_floor() and vertically_aligned:
				move_dir = sign(to_target_x)
				_align_move_dir = move_dir
			else:
				# If we are in the air or on top of the box, lock our direction!
				if _align_move_dir == 0.0:
					_align_move_dir = sign(to_target_x)
				move_dir = _align_move_dir
			
			# If we are grounded, touch the box, on the correct side, and vertically aligned, we are ready.
			var touching_box := false
			if is_on_wall() and is_on_floor() and on_correct_side and vertically_aligned:
				for i in get_slide_collision_count():
					var collision := get_slide_collision(i)
					if collision.get_collider() == _push_target_box:
						touching_box = true
						break
			
			if touching_box:
				velocity.x = 0.0
				_is_aligned = true
				print("[Adult %s] Reached box collision on correct side. Starting to push..." % name)
			elif dist_x > 0.2 or not vertically_aligned:
				velocity.x = move_dir * speed
			else:
				velocity.x = 0.0
				if is_on_floor() and vertically_aligned:
					_is_aligned = true
					print("[Adult %s] Aligned to box target. Starting to push..." % name)
			
			# Apply gravity.
			if not is_on_floor():
				velocity.y -= _gravity * delta
				
			# Jump check for alignment navigation (jump over obstacles, or the box if we need to get to the correct side)
			var should_jump: bool = false
			if is_on_wall() and is_on_floor() and not touching_box:
				should_jump = true
			elif move_dir != 0.0 and is_on_floor():
				var origin := global_position + Vector3(move_dir * 0.5, 0.1, 0.0)
				var end := origin + Vector3(0.0, -1.5, 0.0)
				var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
				var result := space_state.intersect_ray(query)
				if result.is_empty():
					should_jump = true
					
			if should_jump:
				velocity.y = jump_velocity
				
			velocity.z = 0.0
			var is_currently_on_floor := is_on_floor()
			move_and_slide()
			_was_on_floor_last_frame = is_currently_on_floor
			global_position.z = 0.0
			
		else:
			# 2. PUSHING PHASE: Push the box forward until unsafe
			
			# Apply gravity
			if not is_on_floor():
				velocity.y -= _gravity * delta
				
			# Push movement velocity
			velocity.x = _push_dir * push_speed
			velocity.z = 0.0
			
			# Drive the box horizontally in sync
			if is_instance_valid(_push_target_box):
				_push_target_box.linear_velocity.x = _push_dir * push_speed
				
			var is_currently_on_floor := is_on_floor()
			move_and_slide()
			_was_on_floor_last_frame = is_currently_on_floor
			global_position.z = 0.0
			
			# SAFETY CHECKS: Run after move_and_slide using current frame data
			
			# A. Ledge/Gap ahead
			var origin := global_position + Vector3(_push_dir * 0.32, 0.1, 0.0)
			var end := origin + Vector3(0.0, -1.5, 0.0)
			var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
			var result := space_state.intersect_ray(query)
			if result.is_empty():
				print("[Adult %s] Aborting push: Ledge/Gap ahead" % name)
				_stop_pushing()
				return
				
			# B. Wall blocked by static world element
			if is_on_wall() and is_on_floor():
				var blocked_by_real_wall := false
				for i in get_slide_collision_count():
					var collision := get_slide_collision(i)
					var collider := collision.get_collider()
					# Ignore the box we are pushing and other characters
					if collider != _push_target_box and not (collider is CharacterBody3D):
						blocked_by_real_wall = true
						break
				
				if blocked_by_real_wall:
					print("[Adult %s] Aborting push: Blocked by real wall" % name)
					_stop_pushing()
					return
	else:
		# Standard follower movement
		super._physics_process(delta)

func _stop_pushing() -> void:
	current_state = State.FOLLOW
	_push_target_box = null
	_is_aligned = false
	velocity.x = 0.0
	print("[Adult %s] Stopped pushing box (rejoining follow queue)" % name)

func _on_command_broadcast(new_state_int: int) -> void:
	super._on_command_broadcast(new_state_int)
	# If player commanded us to follow/freeze, abort pushing
	if current_state == State.FOLLOW or current_state == State.FREEZE:
		_push_target_box = null
		_is_aligned = false
