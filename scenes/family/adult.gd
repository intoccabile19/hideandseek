class_name Adult
extends FamilyMember

@export_group("Adult Settings")
## Speed of horizontal movement while pushing.
@export var push_speed: float = 1.8

var _push_target_box: RigidBody3D = null
var _push_dir: float = 0.0

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
		current_state = State.PUSHING
		print("[Adult %s] Commanded to push box %s in direction %f" % [name, box.name, direction])

func _physics_process(delta: float) -> void:
	if current_state == State.PUSHING:
		# If target box is destroyed or lost, abort.
		if not is_instance_valid(_push_target_box):
			_stop_pushing()
			return
			
		var space_state := get_world_3d().direct_space_state
		
		# PUSHING PHASE: Push the box forward until unsafe
		
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
		# Standard follower movement (includes base INTERACTING state processing!)
		super._physics_process(delta)

func _stop_pushing() -> void:
	current_state = State.FOLLOW
	_push_target_box = null
	velocity.x = 0.0
	print("[Adult %s] Stopped pushing box (rejoining follow queue)" % name)

func _on_command_broadcast(new_state_int: int) -> void:
	super._on_command_broadcast(new_state_int)
	# If player commanded us to follow/freeze, abort pushing
	if current_state == State.FOLLOW or current_state == State.FREEZE:
		_push_target_box = null
