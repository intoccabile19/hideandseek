class_name Adult
extends FamilyMember

@export_group("Adult Settings")
## Speed of horizontal movement while pushing.
@export var push_speed: float = 1.8

var _push_target_box: RigidBody3D = null
var _push_dir: float = 0.0
var _push_sound_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Override base defaults for the adult subclass
	speed = 3.8
	spacing_steps = 12

func get_size_class() -> String:
	return "Large"

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
		
		# Play periodic scraping sounds while pushing
		_push_sound_timer += delta
		if _push_sound_timer >= 0.25:
			_push_sound_timer = 0.0
			SoundManager.play_scrape(global_position)
		
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
			
		# B. Box blocked by static world element ahead of it
		var box_origin := _push_target_box.global_position
		# Box size.x is 1.2, so half-width is 0.6. Cast slightly in front (0.7m)
		var box_end := box_origin + Vector3(_push_dir * 0.7, 0.0, 0.0)
		var box_query := PhysicsRayQueryParameters3D.create(box_origin, box_end, 1)
		box_query.exclude = [self.get_rid(), _push_target_box.get_rid()]
		var box_result := space_state.intersect_ray(box_query)
		if not box_result.is_empty():
			print("[Adult %s] Aborting push: Box blocked by wall ahead" % name)
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
