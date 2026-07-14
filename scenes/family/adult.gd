class_name Adult
extends FamilyMember

@export_group("Adult Settings")
## Speed of horizontal movement while pushing.
@export var push_speed: float = 1.8

var _push_target_box: RigidBody3D = null
var _push_dir: float = 0.0
var _push_sound_timer: float = 0.0

# Phase 8 bracing variables
var _braced_gate: Node3D = null
var _is_bracing: bool = false
var _exiting_brace: bool = false
var _exit_brace_target_x: float = 0.0
var _launch_timer: float = 0.0

func _init() -> void:
	anim_idle = "Adult/adult_idle"
	anim_move = "Adult/adult_run"
	anim_jump = "Adult/adult_jump"
	anim_hide = ""
	anim_interact_1 = "Adult/adult_brace"
	anim_interact_2 = "Adult/adult_push"
	anim_interact_3 = "Adult/adult_launch"

func _ready() -> void:
	super._ready()
	# Override base defaults for the adult subclass
	speed = 3.8
	spacing_steps = 12

func _process_animations(delta: float) -> void:
	if _launch_timer > 0.0:
		_launch_timer -= delta
		_play_anim(anim_interact_3)
	elif _is_bracing:
		_play_anim(anim_interact_1)
	elif current_state == State.PUSHING:
		_play_anim(anim_interact_2)
	else:
		super._process_animations(delta)

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
		if _exiting_brace:
			velocity.z = 0.0
			if not is_on_floor():
				velocity.y -= _gravity * delta
			
			var to_target_x: float = _exit_brace_target_x - global_position.x
			if abs(to_target_x) < 0.2:
				velocity.x = 0.0
				_exiting_brace = false
				_is_bracing = false
				if is_instance_valid(_braced_gate) and _braced_gate.has_method("set_gate_open"):
					_braced_gate.call("set_gate_open", false)
				_braced_gate = null
				current_state = State.FOLLOW
				print("[Adult %s] Exited brace, dropped gate closed." % name)
			else:
				velocity.x = sign(to_target_x) * speed
				
			move_and_slide()
			_was_on_floor_last_frame = is_on_floor()
			global_position.z = 0.0
		elif _is_bracing:
			velocity.x = 0.0
			velocity.z = 0.0
			if not is_on_floor():
				velocity.y -= _gravity * delta
			move_and_slide()
			_was_on_floor_last_frame = is_on_floor()
			global_position.z = 0.0
		else:
			# Standard follower movement (includes base INTERACTING state processing!)
			super._physics_process(delta)
			return

	# Update visual orientation/animations for pushing/bracing states
	if abs(velocity.x) > 0.1:
		facing_direction = 1.0 if velocity.x > 0.0 else -1.0
	elif current_state == State.PUSHING:
		facing_direction = _push_dir
	elif _is_bracing and is_instance_valid(_braced_gate):
		facing_direction = sign(_braced_gate.global_position.x - global_position.x)
		if facing_direction == 0.0:
			facing_direction = 1.0

	var target_yaw := PI / 2.0 if facing_direction > 0.0 else -PI / 2.0
	for child in get_children():
		if child is Skeleton3D:
			child.rotation.y = lerp_angle(child.rotation.y, target_yaw, delta * 12.0)
			
	_process_animations(delta)

func _stop_pushing() -> void:
	current_state = State.FOLLOW
	_push_target_box = null
	velocity.x = 0.0
	print("[Adult %s] Stopped pushing box (rejoining follow queue)" % name)

func _on_command_broadcast(new_state_int: int) -> void:
	super._on_command_broadcast(new_state_int)
	
	# Release any braced gate when rejoining queue (trigger exit walk-through only if player is on opposite side)
	if _is_bracing and not _exiting_brace:
		if is_instance_valid(_braced_gate):
			var gate_x: float = _braced_gate.global_position.x
			var adult_side: float = sign(global_position.x - gate_x)
			var player_side: float = adult_side
			if is_instance_valid(FamilyManager.player):
				player_side = sign(FamilyManager.player.global_position.x - gate_x)
			
			if player_side != adult_side and player_side != 0.0 and adult_side != 0.0:
				# Player is on opposite side, walk through the door to follow
				_exit_brace_target_x = gate_x + player_side * 1.5
				_exiting_brace = true
				print("[Adult %s] Rejoining queue: Player on opposite side, walking through to X: %0.2f" % [name, _exit_brace_target_x])
			else:
				# Player on same side, just walk away directly
				_is_bracing = false
				if _braced_gate.has_method("set_gate_open"):
					_braced_gate.call("set_gate_open", false)
				_braced_gate = null
				print("[Adult %s] Rejoining queue: Player on same side, released gate immediately." % name)
		else:
			_is_bracing = false
		
	# If player commanded us to follow/freeze, abort pushing
	if current_state == State.FOLLOW or current_state == State.FREEZE:
		_push_target_box = null

## Commanded to brace a gate/shutter open
func brace_gate(gate: Node3D) -> void:
	_is_bracing = true
	_braced_gate = gate
	current_state = State.FREEZE
	if gate.has_method("set_gate_open"):
		gate.call("set_gate_open", true)
	print("[Adult %s] Braced gate: %s open" % [name, gate.name])

## Commanded to toss the Toddler onto a high platform
func try_launch_toddler(launcher_point: Node3D) -> void:
	var toddler: FamilyMember = FamilyManager.get_nearest_member_of_class("Toddler", global_position)
	if toddler and global_position.distance_to(toddler.global_position) <= 4.0:
		# Reposition toddler near hands
		toddler.global_position.x = global_position.x
		toddler.global_position.y = global_position.y + 1.2
		toddler.global_position.z = 0.0
		
		var landing_pt: Node3D = null
		if "landing_target" in launcher_point and launcher_point.landing_target:
			landing_pt = launcher_point.landing_target
			
		toddler.current_state = State.LAUNCHED
		
		if "post_landing_interactable" in launcher_point and launcher_point.post_landing_interactable:
			toddler.post_launch_interact_target = launcher_point.post_landing_interactable
			toddler.post_launch_stop_after_interact = true
			
		if landing_pt:
			# Calculate exact velocity to land at target
			var start_pos: Vector3 = toddler.global_position
			var target_pos: Vector3 = landing_pt.global_position
			var dx: float = target_pos.x - start_pos.x
			var dy: float = target_pos.y - start_pos.y
			
			var horizontal_speed: float = 12.0
			var t: float = abs(dx) / horizontal_speed
			if t < 0.1:
				t = 0.1
				
			var g: float = toddler._gravity if "_gravity" in toddler else 25.0
			
			toddler.velocity.x = sign(dx) * horizontal_speed
			toddler.velocity.y = (dy / t) + (0.5 * g * t)
			toddler.velocity.z = 0.0
			print("[Adult %s] Tossed Toddler %s to target %s (Y-vel=%f, X-vel=%f)" % [name, toddler.name, landing_pt.name, toddler.velocity.y, toddler.velocity.x])
		else:
			# Trigger launch velocity arc in direction of target launcher point
			var launch_dir: float = sign(launcher_point.global_position.x - global_position.x)
			if launch_dir == 0.0:
				launch_dir = 1.0
				
			toddler.velocity.y = 12.5
			toddler.velocity.x = launch_dir * 4.0
			toddler.velocity.z = 0.0
			print("[Adult %s] Tossed Toddler %s upwards (Y-vel=12.5, X-vel=%f)" % [name, toddler.name, launch_dir * 4.0])
		
		_launch_timer = 0.5
	else:
		print("[Adult %s] Launch failed: Toddler not found within 4.0 meters" % name)
