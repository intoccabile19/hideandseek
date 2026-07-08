class_name Toddler
extends FamilyMember

## Time (in seconds) the toddler remains quiet before wandering due to curiosity.
@export var curiosity_cooldown: float = 5.0

## Sound circle projection radius of the toddler's chirps.
@export var chirp_sound_radius: float = 3.5

var _curiosity_timer: float = 0.0
var _chirp_timer: float = 0.0
var _wander_target_x: float = 0.0

func _ready() -> void:
	super._ready()
	# Override base defaults for the toddler subclass
	speed = 4.5
	spacing_steps = 10
	_reset_curiosity_timer()
	_reset_chirp_timer()

func _physics_process(delta: float) -> void:
	# Handle curiosity timer when frozen/hiding.
	if current_state == State.FREEZE or current_state == State.HIDING:
		_curiosity_timer -= delta
		if _curiosity_timer <= 0.0:
			_start_wandering()
		# Run parent physics (just decelerate and stand).
		super._physics_process(delta)
		
	elif current_state == State.WANDER:
		# Decrement chirp timer.
		_chirp_timer -= delta
		if _chirp_timer <= 0.0:
			_chirp()
			
		# Apply gravity.
		if not is_on_floor():
			velocity.y -= _gravity * delta
			
		var to_target_x: float = _wander_target_x - global_position.x
		var dist_x: float = abs(to_target_x)
		
		var move_dir: float = 0.0
		if dist_x > 0.2:
			move_dir = sign(to_target_x)
			velocity.x = move_dir * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			# Reached target: wait, wander again, or stop.
			if randf() < 0.4:
				_start_wandering()
			else:
				_reset_curiosity_timer()
				current_state = State.FREEZE
				
		# Handle obstacles and gaps during wandering.
		var should_jump: bool = false
		if is_on_wall() and is_on_floor():
			should_jump = true
		elif move_dir != 0.0 and is_on_floor():
			var space_state := get_world_3d().direct_space_state
			var origin := global_position + Vector3(move_dir * 0.5, 0.1, 0.0)
			var end := origin + Vector3(0.0, -1.5, 0.0)
			var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
			var result := space_state.intersect_ray(query)
			if result.is_empty() and dist_x > 0.5:
				should_jump = true
		elif not is_on_floor() and _was_on_floor_last_frame and velocity.x != 0.0:
			should_jump = true
			
		if should_jump:
			velocity.y = jump_velocity
			
		velocity.z = 0.0
		var is_currently_on_floor: bool = is_on_floor()
		move_and_slide()
		_was_on_floor_last_frame = is_currently_on_floor
		global_position.z = 0.0
		
	else:
		# FOLLOW state: standard queue following handled by parent.
		super._physics_process(delta)
		_reset_curiosity_timer()

func _on_command_broadcast(new_state_int: int) -> void:
	super._on_command_broadcast(new_state_int)
	if current_state == State.FOLLOW:
		_reset_curiosity_timer()

func _reset_curiosity_timer() -> void:
	_curiosity_timer = curiosity_cooldown * randf_range(0.8, 1.2)

func _reset_chirp_timer() -> void:
	_chirp_timer = randf_range(2.0, 5.5)

func _start_wandering() -> void:
	current_state = State.WANDER
	var offset: float = randf_range(2.0, 4.0) * (1.0 if randf() > 0.5 else -1.0)
	_wander_target_x = global_position.x + offset
	print("[Toddler %s] Wandering off to X: %0.1f" % [name, _wander_target_x])

func _chirp() -> void:
	FamilyManager.emit_toddler_chirp(global_position, chirp_sound_radius)
	_reset_chirp_timer()
