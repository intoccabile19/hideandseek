class_name Seeker
extends CharacterBody3D

enum State {
	WANDER,
	SEARCHING,
	SCANNING,
	SUSPICIOUS,
	CHASE,
	CAPTURE,
	SLEEP,
	WORKING
}

enum SeekerType { LAZY, NORMAL, AGGRESSIVE, LAME }

@export_group("Animations")
@export var anim_idle: String = "robot_idle"
@export var anim_walk: String = "robot_walk_1"
@export var anim_work_1: String = "robot_work_1"
@export var anim_work_2: String = "pulling_lever"
@export var anim_work_3: String = "sending_a_fax"
@export var anim_work_4: String = "standing_using_a_touchscreen"
@export var anim_work_5: String = "using_a_fax"
@export var anim_alert: String = "robot_alert_look"
@export var anim_grab: String = "robot_grab_1"
@export var anim_look_1: String = "robot_look_1"
@export var anim_look_2: String = "robot_look_2"
@export var anim_look_3: String = "robot_look_high"

@export_group("Seeker Settings")
@export var seeker_type: SeekerType = SeekerType.NORMAL
@export var terminals: Array[Node3D] = []
@export var wander_range_x: Vector2 = Vector2(-15.0, 15.0)
@export var wander_range_z: Vector2 = Vector2(-15.0, -6.0)
@export var background_z: float = -12.0
@export var peer_z: float = -6.0 # Safe distance from walkway walls to prevent physical collision jitter
@export var patrol_speed: float = 2.0 # Slow curious search walk
@export var chase_speed: float = 3.5 # Tracking walk
@export var vision_range: float = 18.0
@export var vision_angle: float = 45.0 # Spotlight degrees
@export var capture_time_limit: float = 2.0 # Warning window seconds before grab
@export var alert_decay_rate: float = 0.06
@export var alert_growth_multiplier: float = 1.0
@export var search_wait_time: float = 1.8
@export var investigate_speed: float = 2.0

@onready var spotlight: SpotLight3D = $SpotLight3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var alert_label: Label3D = $AlertLabel
@onready var vision_cone: MeshInstance3D = $SpotLight3D/VisionCone

var current_state: State = State.WANDER
var _target_pos: Vector3 = Vector3.ZERO
var _target_object: SearchableObject = null
var _chase_target: Node3D = null
var _spotted_target: Node3D = null
var _last_seen_x: float = 0.0
var _state_timer: float = 0.0
var _chase_timer: float = 0.0
var _sleep_timer: float = 0.0
var _gravity: float = 15.0
var _has_heard_anything: bool = false
var _vision_cone_mat: StandardMaterial3D = null

# Alert system variables
var alert_level: float = 0.0
var _faint_look_timer: float = 0.0
var _look_target_x: float = 0.0
var _footstep_accum: float = 0.0
const FOOTSTEP_DIST: float = 3.5

var _target_terminal: Node3D = null
var _current_work_anim: String = ""
var _work_duration: float = 0.0
var _current_look_anim: String = ""
var _last_look_change_time: float = 0.0
var _alert_duration: float = 1.2
var _look_duration: float = 0.0
var _look_timer: float = 0.0
var _actual_velocity: Vector3 = Vector3.ZERO

func _select_random_look_anim() -> void:
	var list: Array[String] = []
	if not anim_look_1.is_empty(): list.append(anim_look_1)
	if not anim_look_2.is_empty(): list.append(anim_look_2)
	if not anim_look_3.is_empty(): list.append(anim_look_3)
	
	if not list.is_empty():
		_current_look_anim = list.pick_random()
	else:
		_current_look_anim = "robot_look_1"
		
	# Query look animation length
	_look_duration = 1.8 # default fallback
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if is_instance_valid(anim_player) and anim_player.has_animation(_current_look_anim):
		var anim = anim_player.get_animation(_current_look_anim)
		if anim:
			_look_duration = anim.length
	_look_timer = 0.0

func _play_anim(anim_name: String) -> void:
	if anim_name.is_empty():
		return
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if is_instance_valid(anim_player):
		if anim_player.has_animation(anim_name):
			if anim_player.current_animation != anim_name:
				anim_player.play(anim_name)

func _ready() -> void:
	add_to_group("seeker")
	add_to_group("seekers")
	_target_pos = global_position
	
	# Apply archetype settings
	match seeker_type:
		SeekerType.LAZY:
			patrol_speed = 3.0
			investigate_speed = 2.0
			chase_speed = 3.5
			alert_decay_rate = 0.15
			search_wait_time = 3.5
			alert_growth_multiplier = 0.5
		SeekerType.NORMAL:
			patrol_speed = 3.5
			investigate_speed = 2.8
			chase_speed = 4.8
			alert_decay_rate = 0.06
			search_wait_time = 4.5
			alert_growth_multiplier = 1.0
		SeekerType.AGGRESSIVE:
			patrol_speed = 4.0
			investigate_speed = 3.5
			chase_speed = 5.8
			alert_decay_rate = 0.03
			search_wait_time = 5.5
			alert_growth_multiplier = 1.5
		SeekerType.LAME:
			patrol_speed = 2.2
			investigate_speed = 1.8
			chase_speed = 2.2
			alert_decay_rate = 1.0
			search_wait_time = 1.0
			alert_growth_multiplier = 0.0

	# Subscribe to sound cues on the whisper network
	FamilyManager.sound_emitted.connect(_on_sound_heard)
	FamilyManager.toddler_chirped.connect(_on_toddler_chirped)
	_choose_next_wander()

	if is_instance_valid(vision_cone):
		_vision_cone_mat = vision_cone.material_override as StandardMaterial3D

	# Disable the default mesh placeholder
	if is_instance_valid(mesh):
		mesh.visible = false
		
	# Select which robot visual model to show based on seeker_type
	var robot_mesh = get_node_or_null("Skeleton3D/Character_Robot_01")
	var cyborg_mesh = get_node_or_null("Skeleton3D/Character_CyborgNinja_01")
	var android_mesh = get_node_or_null("Skeleton3D/Character_Android_Female_01")
	
	if is_instance_valid(robot_mesh): robot_mesh.visible = false
	if is_instance_valid(cyborg_mesh): cyborg_mesh.visible = false
	if is_instance_valid(android_mesh): android_mesh.visible = false
	
	match seeker_type:
		SeekerType.LAME, SeekerType.LAZY:
			if is_instance_valid(robot_mesh): robot_mesh.visible = true
		SeekerType.NORMAL:
			if is_instance_valid(android_mesh): android_mesh.visible = true
		SeekerType.AGGRESSIVE:
			if is_instance_valid(cyborg_mesh): cyborg_mesh.visible = true

func _physics_process(delta: float) -> void:
	if current_state == State.SLEEP:
		_sleep_timer -= delta
		velocity = Vector3.ZERO
		if not is_on_floor():
			velocity.y -= _gravity * delta
		move_and_slide()
		
		# Dim/purple vision cone albedo in sleep, tilt spotlight straight down
		if is_instance_valid(spotlight):
			spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-90.0), delta * 5.0)
			spotlight.rotation.y = lerp(spotlight.rotation.y, 0.0, delta * 5.0)
		if is_instance_valid(_vision_cone_mat):
			_vision_cone_mat.albedo_color = _vision_cone_mat.albedo_color.lerp(Color(0.5, 0.0, 0.8, 0.01), delta * 2.0)
			
		if _sleep_timer <= 0.0:
			# Wake up! Restore spotlight and vision cone
			if is_instance_valid(spotlight):
				spotlight.light_energy = 16.0
				spotlight.light_color = Color(1.0, 1.0, 0.8)
				spotlight.rotation.x = deg_to_rad(-65.0)
				spotlight.rotation.y = 0.0
			if is_instance_valid(_vision_cone_mat):
				_vision_cone_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
			_choose_next_wander()
		return

	_check_vision()
	
	# Process gradual visual detection
	if _spotted_target != null:
		if current_state != State.CHASE and current_state != State.CAPTURE:
			alert_level = min(alert_level + delta * alert_growth_multiplier * 0.15, 1.0)
			_last_seen_x = _spotted_target.global_position.x
			
			# Look directly at the spotted target
			var to_target := _spotted_target.global_position - global_position
			var target_yaw := atan2(-to_target.x, -to_target.z)
			rotation.y = rotate_toward(rotation.y, target_yaw, delta * 6.0)
			spotlight.rotation.y = 0.0
			
			# Freeze movement while alert accumulates
			velocity.x = 0.0
			velocity.z = 0.0
			
			if alert_level >= 1.0:
				_chase_target = _spotted_target
				current_state = State.CHASE
				_spotted_target = null
				_chase_timer = 0.0
				_has_heard_anything = true
				print("[Seeker %s] Giant SPOTTED target: %s! Warning flash started..." % [name, _chase_target.name])
	else:
		# Decay alert level slowly when not chasing, searching, or suspicious
		if current_state != State.CHASE and current_state != State.CAPTURE and current_state != State.SUSPICIOUS:
			var old_alert := alert_level
			alert_level = max(0.0, alert_level - delta * alert_decay_rate)
			
			# If we had high alert and lost target, transition to SUSPICIOUS to search
			if old_alert >= 0.4 and alert_level < 0.4:
				_target_pos = Vector3(_last_seen_x, global_position.y, peer_z)
				current_state = State.SUSPICIOUS
				_state_timer = 0.0
				_target_object = null
				_faint_look_timer = 0.0
				print("[Seeker %s] Target lost. Investigating last seen position X: %0.2f" % [name, _last_seen_x])

	# Update vision cone color based on state
	if is_instance_valid(_vision_cone_mat):
		var target_color := Color(0.2, 0.8, 1.0, 0.04) # Normal blue
		if seeker_type == SeekerType.LAME:
			target_color = Color(0.3, 0.8, 0.3, 0.02) # Passive green
			alert_level = 0.0
		elif current_state == State.CHASE or current_state == State.CAPTURE:
			target_color = Color(1.0, 0.1, 0.1, 0.12) # Alert red
		elif current_state == State.SUSPICIOUS:
			target_color = Color(1.0, 0.6, 0.1, 0.08) # Suspicious orange
		elif alert_level > 0.05:
			target_color = Color(1.0, 0.9, 0.2, 0.06) # Searching yellow
			
		# Smoothly interpolate color to prevent harsh snaps
		_vision_cone_mat.albedo_color = _vision_cone_mat.albedo_color.lerp(target_color, delta * 5.0)

	var active_alert: float = alert_level
	if current_state == State.CHASE or current_state == State.CAPTURE:
		active_alert = 1.0
	SoundManager.update_heartbeat(active_alert)

	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	# Process current state (freeze and look in place on Low Alert)
	if _spotted_target != null and current_state != State.CHASE and current_state != State.CAPTURE:
		# Gradually detecting: freeze velocity and do not run state movement
		velocity.x = 0.0
		velocity.z = 0.0
	elif _faint_look_timer > 0.0:
		_faint_look_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		# Turn mesh to face towards the look target
		var to_look := _look_target_x - global_position.x
		var target_yaw := PI * 0.5 if to_look < 0.0 else -PI * 0.5
		mesh.rotation.y = rotate_toward(mesh.rotation.y, target_yaw, delta * 6.0)
		spotlight.rotation.y = mesh.rotation.y
		spotlight.rotation.x = deg_to_rad(-15.0)
	else:
		match current_state:
			State.WANDER:
				_process_wander(delta)
			State.SEARCHING:
				_process_searching(delta)
			State.SCANNING:
				_process_scanning(delta)
			State.SUSPICIOUS:
				_process_suspicious(delta)
			State.CHASE:
				_process_chase(delta)
			State.CAPTURE:
				_process_capture(delta)
			State.WORKING:
				_process_working(delta)

	# Update Visual Alert Label Billboard
	if is_instance_valid(alert_label):
		if current_state == State.CHASE:
			alert_label.text = "!"
			alert_label.modulate = Color(1.0, 0.0, 0.0, 1.0) # Red
		elif current_state == State.SUSPICIOUS or _faint_look_timer > 0.0:
			alert_label.text = "?"
			alert_label.modulate = Color(1.0, 0.8, 0.0, 1.0) # Yellow
		else:
			alert_label.text = ""

	# Proximity Yielding: prevent Seekers from colliding or walking through each other
	if current_state != State.CHASE and current_state != State.CAPTURE:
		var too_close := false
		for other in get_tree().get_nodes_in_group("seeker"):
			if other != self and is_instance_valid(other):
				if other.current_state != State.CHASE and other.current_state != State.CAPTURE:
					var dist_to_other := global_position.distance_to(other.global_position)
					if dist_to_other < 3.5:
						if get_instance_id() < other.get_instance_id():
							too_close = true
							break
		if too_close:
			velocity.x = 0.0
			velocity.z = 0.0

	# Run physics movement
	move_and_slide()

	# Link spotlight / vision cone to the head bone of the active visual model
	var skeleton: Skeleton3D = get_node_or_null("Skeleton3D") as Skeleton3D
	if is_instance_valid(skeleton) and is_instance_valid(spotlight):
		var head_bone_idx: int = skeleton.find_bone("Head")
		if head_bone_idx != -1:
			var head_trans: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(head_bone_idx)
			spotlight.global_position = head_trans.origin

	# Play footstep sounds as we walk
	if is_on_floor() and velocity.length() > 0.1:
		_footstep_accum += velocity.length() * delta
		if _footstep_accum >= FOOTSTEP_DIST:
			_footstep_accum = 0.0
			var player_dist: float = 30.0
			if is_instance_valid(FamilyManager.player):
				player_dist = global_position.distance_to(FamilyManager.player.global_position)
			var vol_db: float = clamp(lerp(0.0, -20.0, player_dist / 30.0), -24.0, 0.0)
			SoundManager.play_footstep(global_position, vol_db)

	# Move Z-axis based on state (in State.WANDER we move back to the target's background Z position)
	var target_z := _target_pos.z if current_state == State.WANDER else peer_z
	if current_state == State.SEARCHING and _target_object:
		target_z = _target_object.global_position.z
	elif current_state == State.WORKING and _target_terminal:
		target_z = _target_terminal.global_position.z
	
	# Match Z-axis speed to active state movement speed
	var speed_z := patrol_speed
	if current_state == State.CHASE or current_state == State.CAPTURE:
		speed_z = chase_speed
	elif current_state == State.SUSPICIOUS:
		speed_z = investigate_speed
		
	var prev_z := global_position.z
	global_position.z = move_toward(global_position.z, target_z, delta * speed_z)

	# Constrain rotation pitch/roll to remain upright
	rotation.x = 0.0
	rotation.z = 0.0

	# Check vision to detect intruders
	if current_state != State.CHASE and current_state != State.CAPTURE:
		_check_vision()

	# Calculate actual combined horizontal velocity for animations
	_actual_velocity = Vector3(velocity.x, 0.0, (global_position.z - prev_z) / delta if delta > 0.0 else 0.0)

	_process_animations(delta)

func _process_wander(delta: float) -> void:
	# Reset spotlight defaults
	spotlight.light_energy = 32.0
	spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)

	# Handle alert look action
	if _faint_look_timer > 0.0:
		_faint_look_timer -= delta
		velocity = Vector3.ZERO
		# Pause and rotate towards suspicious target position
		var dir_to_target := (_target_pos - global_position).normalized()
		var target_yaw := atan2(-dir_to_target.x, -dir_to_target.z)
		rotation.y = rotate_toward(rotation.y, target_yaw, delta * 4.0)
		spotlight.rotation.y = 0.0
		spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-25.0), delta * 4.0)
		return

	var to_target: Vector3 = _target_pos - global_position
	# Ignore Y component for horizontal distance check
	var dir_xz := Vector3(to_target.x, 0.0, to_target.z)
	var dist_xz := dir_xz.length()

	if dist_xz > 0.4:
		var move_dir := dir_xz.normalized()
		velocity.x = move_dir.x * patrol_speed
		velocity.z = move_dir.z * patrol_speed
		
		# Rotate to face 3D walking direction (Godot forward is -Z)
		var target_yaw := atan2(-velocity.x, -velocity.z)
		rotation.y = rotate_toward(rotation.y, target_yaw, delta * 6.0)
		spotlight.rotation.y = 0.0
		spotlight.rotation.x = deg_to_rad(-10.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		# We reached the target opening/object/terminal
		if _target_terminal:
			current_state = State.WORKING
			_state_timer = 0.0
			_select_random_work_anim()
		elif _target_object:
			current_state = State.SEARCHING
			_state_timer = 0.0
			_select_random_work_anim()
		else:
			current_state = State.SCANNING
			_state_timer = 0.0

func _process_searching(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer += delta

	# Face the searchable object or work spot
	if is_instance_valid(_target_object):
		var spot: Marker3D = _target_object.get_node_or_null("SeekerWorkSpot") as Marker3D
		if is_instance_valid(spot):
			rotation.y = rotate_toward(rotation.y, spot.global_rotation.y, delta * 6.0)
		else:
			var dir_to_obj := (_target_object.global_position - global_position).normalized()
			var target_yaw := atan2(-dir_to_obj.x, -dir_to_obj.z)
			rotation.y = rotate_toward(rotation.y, target_yaw, delta * 6.0)
	spotlight.rotation.y = 0.0

	var phase_1_end := search_wait_time * 0.55
	var phase_2_end := search_wait_time * 1.38
	var phase_3_end := search_wait_time * 1.94

	# Phase 1: Lift the background debris/object and point spotlight down
	if _state_timer < phase_1_end:
		if _state_timer - delta <= 0.0 and _target_object:
			_target_object.lift(1.5, 0.8)
		spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-60.0), delta * 4.0)
	# Phase 2: Sweep light underneath
	elif _state_timer < phase_2_end:
		spotlight.rotation.y = sin(_state_timer * 6.0) * deg_to_rad(20.0)
	# Phase 3: Lower object and return light
	elif _state_timer < _work_duration:
		if _state_timer - delta < phase_2_end and _target_object:
			_target_object.lower(0.8)
		spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-15.0), delta * 4.0)
		spotlight.rotation.y = lerp(spotlight.rotation.y, 0.0, delta * 4.0)
	else:
		if _target_object:
			_target_object.lower(0.8)
		_target_object = null
		current_state = State.SCANNING
		_state_timer = 0.0

func _process_scanning(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer += delta

	# Turn forward towards the walkway opening (Z = 0.0, which is PI yaw)
	rotation.y = rotate_toward(rotation.y, PI, delta * 6.0)
	spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-15.0), delta * 4.0)

	# Sweep spotlight left and right across the opening
	var sweep_angle := sin(_state_timer * 3.0) * deg_to_rad(35.0)
	spotlight.rotation.y = sweep_angle

	if _state_timer > (search_wait_time * 2.2):
		spotlight.rotation.y = 0.0
		_choose_next_wander()

func _process_suspicious(delta: float) -> void:
	var to_target: float = _target_pos.x - global_position.x
	var dist: float = abs(to_target)

	# Reset spotlight defaults
	spotlight.light_energy = 32.0
	spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)

	_state_timer += delta
	
	if _state_timer - delta <= 0.0:
		_current_look_anim = ""
		_last_look_change_time = 0.0
		# Retrieve alert animation length to guarantee it completes fully
		_alert_duration = 1.2 # default fallback
		var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
		if is_instance_valid(anim_player) and anim_player.has_animation(anim_alert):
			var anim = anim_player.get_animation(anim_alert)
			if anim:
				_alert_duration = anim.length

	# Phase 1: Alert animation playback
	if _state_timer < _alert_duration:
		velocity.x = 0.0
		velocity.z = 0.0
		# Look directly at the sound target
		var dir_to_target := (_target_pos - global_position).normalized()
		var target_yaw := atan2(-dir_to_target.x, -dir_to_target.z)
		rotation.y = rotate_toward(rotation.y, target_yaw, delta * 6.0)
		spotlight.rotation.y = 0.0
		spotlight.rotation.x = deg_to_rad(-15.0)
	# Phase 2: Walk slowly to the sound opening/wall
	elif dist > 0.4:
		velocity.x = sign(to_target) * investigate_speed
		velocity.z = 0.0
		var dir_to_target := (_target_pos - global_position).normalized()
		var target_yaw := atan2(-dir_to_target.x, -dir_to_target.z)
		rotation.y = rotate_toward(rotation.y, target_yaw, delta * 6.0)
		
		# Point spotlight forward and sweep it left/right locally
		spotlight.rotation.y = sin(_state_timer * 5.0) * deg_to_rad(35.0)
		spotlight.rotation.x = deg_to_rad(-20.0)
	# Phase 3: At the wall, look animations randomly
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		# Peer through opening and perform intensive sweep at sound site
		rotation.y = rotate_toward(rotation.y, PI, delta * 6.0)
		spotlight.rotation.y = sin(_state_timer * 5.0) * deg_to_rad(45.0)
		spotlight.rotation.x = deg_to_rad(-20.0)
		
		if _current_look_anim.is_empty():
			_select_random_look_anim()
		else:
			_look_timer += delta
			if _look_timer >= _look_duration:
				if _state_timer > (search_wait_time * 2.5):
					spotlight.rotation.y = 0.0
					_choose_next_wander()
				else:
					_select_random_look_anim()

func _process_chase(delta: float) -> void:
	if not is_instance_valid(_chase_target):
		_choose_next_wander()
		return

	var to_target: float = _chase_target.global_position.x - global_position.x
	var dist_x: float = abs(to_target)

	# Rotate to track chased target
	var dir_to_char := (_chase_target.global_position - global_position).normalized()
	var target_yaw := atan2(-dir_to_char.x, -dir_to_char.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, delta * 8.0)
	spotlight.rotation.y = 0.0
	
	if dist_x > 0.4:
		velocity.x = sign(to_target) * chase_speed
		velocity.z = 0.0
		
		# Point light directly at chased target
		var dir_to_light: Vector3 = (_chase_target.global_position + Vector3(0.0, 1.0, 0.0) - spotlight.global_position).normalized()
		spotlight.rotation.x = asin(dir_to_light.y)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Check line of sight and cone angle continuously
	var space_state := get_world_3d().direct_space_state
	var spotlight_forward: Vector3 = -spotlight.global_transform.basis.z.normalized()
	var dir_to_char_spotlight: Vector3 = (_chase_target.global_position + Vector3(0.0, 1.0, 0.0) - spotlight.global_position).normalized()
	var angle: float = rad_to_deg(spotlight_forward.angle_to(dir_to_char_spotlight))
	
	var target_hidden: bool = false
	if _chase_target.has_method("is_hidden_class") and _chase_target.is_hidden:
		target_hidden = _chase_target.is_hidden
	elif _chase_target.get("is_hidden") != null:
		target_hidden = _chase_target.get("is_hidden")

	var clear_los := false
	if angle < vision_angle * 0.5 and not target_hidden:
		# Project from Seeker's spotlight to the target's chest (Y = 1.0)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			spotlight.global_position,
			_chase_target.global_position + Vector3(0.0, 1.0, 0.0),
			1
		)
		var exclude_list: Array[RID] = [self.get_rid(), _chase_target.get_rid()]
		query.exclude = exclude_list
		var result: Dictionary = space_state.intersect_ray(query)
		if result.is_empty():
			clear_los = true

	if clear_los:
		_chase_timer += delta
		
		# Spotlight Warning Flash Effects: "What the hell is that?!"
		# Rapidly cycle color between red and white, and pulse energy
		var flash_freq := 16.0
		var is_flash_white := int(_chase_timer * flash_freq) % 2 == 0
		spotlight.light_color = Color(1.0, 1.0, 1.0, 1.0) if is_flash_white else Color(1.0, 0.0, 0.0, 1.0)
		spotlight.light_energy = 48.0 + sin(_chase_timer * 30.0) * 16.0
		
		if _chase_timer >= capture_time_limit:
			current_state = State.CAPTURE
			_state_timer = 0.0
			return
	else:
		# Target broke line of sight or hid in cover! Safe from grab!
		_last_seen_x = _chase_target.global_position.x
		_target_pos = Vector3(_last_seen_x, global_position.y, peer_z)
		current_state = State.SUSPICIOUS
		_state_timer = 0.0
		_chase_timer = 0.0
		_chase_target = null
		
		# Restore spotlight defaults
		spotlight.light_energy = 32.0
		spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)
		print("[Seeker %s] Target escaped grab window! Investigating last seen position..." % name)

func _process_capture(delta: float) -> void:
	velocity = Vector3.ZERO
	_state_timer += delta
	
	# Find grab animation length dynamically
	var grab_len := 1.5 # default fallback
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if is_instance_valid(anim_player) and anim_player.has_animation(anim_grab):
		var anim = anim_player.get_animation(anim_grab)
		if anim:
			grab_len = anim.length
			
	# Dramatic blinding flash grab effect (energy = 200, bright white/cyan light) in the first 0.4 seconds
	if _state_timer < 0.4:
		spotlight.light_color = Color(1.0, 1.0, 1.0, 1.0)
		spotlight.light_energy = 200.0
	else:
		# Restore spotlight defaults
		spotlight.light_energy = 32.0
		spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)
		
	if _state_timer >= grab_len:
		print("[Seeker %s] Giant peer capture successful! Triggering Game Over." % name)
		FamilyManager.game_over.emit()
		set_physics_process(false)

func _choose_next_wander() -> void:
	current_state = State.WANDER
	_state_timer = 0.0
	_chase_timer = 0.0
	_faint_look_timer = 0.0
	
	# Restore spotlight default state
	spotlight.light_energy = 32.0
	spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)
	
	# Combine searchable objects and terminals into a unified job pool, avoiding busy targets
	var busy_targets := []
	for other in get_tree().get_nodes_in_group("seeker"):
		if other != self and is_instance_valid(other):
			var other_term = other.get("_target_terminal")
			if is_instance_valid(other_term):
				busy_targets.append(other_term)
			var other_obj = other.get("_target_object")
			if is_instance_valid(other_obj):
				busy_targets.append(other_obj)

	var pool: Array = []
	for obj in get_tree().get_nodes_in_group("searchable_objects"):
		if not obj in busy_targets:
			pool.append({"type": "searchable", "node": obj})
	for term in terminals:
		if is_instance_valid(term) and not term in busy_targets:
			pool.append({"type": "terminal", "node": term})
			
	# If everything is busy, fall back to the entire pool
	if pool.is_empty():
		for obj in get_tree().get_nodes_in_group("searchable_objects"):
			pool.append({"type": "searchable", "node": obj})
		for term in terminals:
			if is_instance_valid(term):
				pool.append({"type": "terminal", "node": term})

	if not pool.is_empty():
		var selected = pool.pick_random()
		if selected["type"] == "terminal":
			_target_terminal = selected["node"]
			_target_object = null
			var spot: Marker3D = _target_terminal.get_node_or_null("SeekerWorkSpot") as Marker3D
			if is_instance_valid(spot):
				spot.visible = false
				_target_pos = spot.global_position
			else:
				_target_pos = _target_terminal.global_position
			print("[Seeker %s] Heading to work at terminal: %s at 3D pos: %s" % [name, _target_terminal.name, str(_target_pos)])
		else:
			_target_terminal = null
			_target_object = selected["node"]
			var spot: Marker3D = _target_object.get_node_or_null("SeekerWorkSpot") as Marker3D
			if is_instance_valid(spot):
				spot.visible = false
				_target_pos = spot.global_position
			else:
				_target_pos = _target_object.global_position
			print("[Seeker %s] Heading to search background object: %s at 3D pos: %s" % [name, _target_object.name, str(_target_pos)])
		return

	# Otherwise (fallback), choose a random 3D position in the background wander range
	_target_pos = Vector3(
		randf_range(wander_range_x.x, wander_range_x.y),
		global_position.y,
		randf_range(wander_range_z.x, wander_range_z.y)
	)
	_target_object = null
	_target_terminal = null
	print("[Seeker %s] Giant wandering in background (fallback) to 3D pos: %s" % [name, str(_target_pos)])

func _check_vision() -> void:
	_spotted_target = null
	if seeker_type == SeekerType.LAME:
		return
	var space_state := get_world_3d().direct_space_state
	var potential_targets: Array[Node3D] = []

	if is_instance_valid(FamilyManager.player):
		potential_targets.append(FamilyManager.player)
	for member in FamilyManager.active_members:
		if is_instance_valid(member) and member.is_inside_tree():
			potential_targets.append(member)

	var spotlight_forward := -spotlight.global_transform.basis.z.normalized()

	for target in potential_targets:
		var target_hidden: bool = false
		if target.has_method("is_hidden_class") and target.is_hidden:
			target_hidden = target.is_hidden
		elif target.get("is_hidden") != null:
			target_hidden = target.get("is_hidden")

		if target_hidden:
			continue

		var dist := spotlight.global_position.distance_to(target.global_position + Vector3(0.0, 1.0, 0.0))
		if dist > vision_range:
			continue

		var dir_to_char := (target.global_position + Vector3(0.0, 1.0, 0.0) - spotlight.global_position).normalized()
		var angle := rad_to_deg(spotlight_forward.angle_to(dir_to_char))

		if angle < vision_angle * 0.5:
			# Project from Seeker's spotlight to the target's chest (Y = 1.0)
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				spotlight.global_position,
				target.global_position + Vector3(0.0, 1.0, 0.0),
				1
			)
			var exclude_list: Array[RID] = [self.get_rid(), target.get_rid()]
			query.exclude = exclude_list
			var result: Dictionary = space_state.intersect_ray(query)
			if result.is_empty():
				_spotted_target = target
				return

func _on_sound_heard(origin: Vector3, radius: float, is_shout: bool) -> void:
	if seeker_type == SeekerType.LAME:
		return
	if current_state == State.CHASE or current_state == State.CAPTURE:
		return
	
	var dist_x: float = abs(global_position.x - origin.x)
	if dist_x <= radius:
		_has_heard_anything = true
		
		# Increase alert level based on sound severity and archetype multiplier
		var alert_inc := (0.6 if is_shout else 0.35) * alert_growth_multiplier
		alert_level = min(alert_level + alert_inc, 1.0)
		
		if alert_level >= 0.5:
			# High Alert: Stop what we are doing and walk slowly to investigate the sound opening
			_target_pos = Vector3(origin.x, global_position.y, peer_z)
			current_state = State.SUSPICIOUS
			_state_timer = 0.0
			_target_object = null
			_faint_look_timer = 0.0
			print("[Seeker %s] Giant heard noise at X: %0.2f on High Alert (%0.2f). Investigating opening..." % [name, origin.x, alert_level])
		else:
			# Low Alert: Pause in place and look towards the sound source without walking there
			_look_target_x = origin.x
			_faint_look_timer = 1.8
			_target_object = null
			print("[Seeker %s] Giant heard noise at X: %0.2f on Low Alert (%0.2f). Looking but disregarding..." % [name, origin.x, alert_level])

func _on_toddler_chirped(origin: Vector3, radius: float) -> void:
	_on_sound_heard(origin, radius, false)

## Puts the Seeker robot to sleep/stuns them temporarily
func put_to_sleep(duration: float) -> void:
	current_state = State.SLEEP
	_sleep_timer = duration
	_spotted_target = null
	_chase_target = null
	velocity = Vector3.ZERO
	alert_level = 0.0
	
	# Dim spotlight and change color to sleep purple, point straight down
	if is_instance_valid(spotlight):
		spotlight.light_energy = 2.0
		spotlight.light_color = Color(0.5, 0.0, 0.8)
		spotlight.rotation.x = deg_to_rad(-90.0)
	print("[Seeker %s] Giant robot put to sleep for %0.1f seconds." % [name, duration])

func _process_working(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer += delta

	# Face the terminal or work spot
	if is_instance_valid(_target_terminal):
		var spot: Marker3D = _target_terminal.get_node_or_null("SeekerWorkSpot") as Marker3D
		if is_instance_valid(spot):
			rotation.y = rotate_toward(rotation.y, spot.global_rotation.y, delta * 6.0)
		else:
			var dir_to_term := (_target_terminal.global_position - global_position).normalized()
			var target_yaw := atan2(-dir_to_term.x, -dir_to_term.z)
			rotation.y = rotate_toward(rotation.y, target_yaw, delta * 6.0)
	spotlight.rotation.y = 0.0
	spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-25.0), delta * 4.0)

	# When the time runs out, finish working
	if _state_timer >= _work_duration:
		_target_terminal = null
		current_state = State.SCANNING
		_state_timer = 0.0

func _select_random_work_anim() -> void:
	var list: Array[String] = []
	if not anim_work_1.is_empty(): list.append(anim_work_1)
	if not anim_work_2.is_empty(): list.append(anim_work_2)
	if not anim_work_3.is_empty(): list.append(anim_work_3)
	if not anim_work_4.is_empty(): list.append(anim_work_4)
	if not anim_work_5.is_empty(): list.append(anim_work_5)
	
	if not list.is_empty():
		_current_work_anim = list.pick_random()
	else:
		_current_work_anim = "robot_work_1"
		
	# Retrieve animation length to guarantee it completes fully
	_work_duration = search_wait_time * 1.5 # default fallback
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if is_instance_valid(anim_player) and anim_player.has_animation(_current_work_anim):
		var anim = anim_player.get_animation(_current_work_anim)
		if anim:
			_work_duration = anim.length

func _process_animations(delta: float) -> void:
	if current_state == State.SLEEP:
		_play_anim(anim_idle)
	elif current_state == State.CAPTURE:
		_play_anim(anim_grab)
	elif current_state == State.WORKING:
		_play_anim(_current_work_anim)
	elif current_state == State.SEARCHING:
		# Search site: randomly play one of the work animations
		_play_anim(_current_work_anim)
	elif current_state == State.SUSPICIOUS:
		# Alert phase -> walk to wall -> random look animations at the wall
		if _state_timer < _alert_duration:
			_play_anim(anim_alert)
		elif _actual_velocity.length() > 0.1:
			_play_anim(anim_walk)
		else:
			_play_anim(_current_look_anim)
	elif _spotted_target != null:
		# Alert/detected but freezing
		_play_anim(anim_alert)
	elif current_state == State.CHASE:
		# Chasing: play fast walk animation
		if _actual_velocity.length() > 0.1:
			var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
			if is_instance_valid(ap) and ap.has_animation("robot_walk_2"):
				_play_anim("robot_walk_2")
			else:
				_play_anim(anim_walk)
		else:
			_play_anim(anim_idle)
	else:
		# Normal patrol or wandering
		if _actual_velocity.length() > 0.1:
			_play_anim(anim_walk)
		else:
			_play_anim(anim_idle)

	# Adjust playback speed for walk animations to match physical speed
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if is_instance_valid(anim_player):
		var curr := anim_player.current_animation
		if curr == anim_walk or curr == "robot_walk_2":
			var horizontal_speed := _actual_velocity.length()
			if horizontal_speed > 0.1:
				anim_player.speed_scale = horizontal_speed / 2.2
			else:
				anim_player.speed_scale = 1.0
		else:
			anim_player.speed_scale = 1.0
