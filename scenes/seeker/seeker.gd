class_name Seeker
extends CharacterBody3D

enum State {
	WANDER,
	SEARCHING,
	SCANNING,
	SUSPICIOUS,
	CHASE,
	CAPTURE
}

@export_group("Seeker Settings")
@export var wander_range_x: Vector2 = Vector2(-15.0, 15.0)
@export var wander_range_z: Vector2 = Vector2(-15.0, -6.0)
@export var background_z: float = -12.0
@export var peer_z: float = -6.0 # Safe distance from walkway walls to prevent physical collision jitter
@export var patrol_speed: float = 2.0 # Slow curious search walk
@export var chase_speed: float = 3.5 # Tracking walk
@export var vision_range: float = 18.0
@export var vision_angle: float = 45.0 # Spotlight degrees
@export var capture_time_limit: float = 2.0 # Warning window seconds before grab

@onready var spotlight: SpotLight3D = $SpotLight3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var alert_label: Label3D = $AlertLabel

var current_state: State = State.WANDER
var _target_pos: Vector3 = Vector3.ZERO
var _target_object: SearchableObject = null
var _chase_target: Node3D = null
var _last_seen_x: float = 0.0
var _state_timer: float = 0.0
var _chase_timer: float = 0.0
var _gravity: float = 15.0
var _has_heard_anything: bool = false

# Alert system variables
var alert_level: float = 0.0
var _faint_look_timer: float = 0.0
var _footstep_accum: float = 0.0
const FOOTSTEP_DIST: float = 3.5

func _ready() -> void:
	add_to_group("seeker")
	# Subscribe to sound cues on the whisper network
	FamilyManager.sound_emitted.connect(_on_sound_heard)
	FamilyManager.toddler_chirped.connect(_on_toddler_chirped)
	_choose_next_wander()

func _physics_process(delta: float) -> void:
	# Decay alert level slowly when not chasing, searching, or suspicious
	if current_state != State.CHASE and current_state != State.CAPTURE and current_state != State.SUSPICIOUS:
		alert_level = max(0.0, alert_level - delta * 0.06)

	var active_alert: float = alert_level
	if current_state == State.CHASE or current_state == State.CAPTURE:
		active_alert = 1.0
	SoundManager.update_heartbeat(active_alert)

	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	# Process current state
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

	# Run physics movement
	move_and_slide()

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

	# Lerp Z-axis based on state (in State.WANDER we lerp back to the target's background Z position)
	var target_z := _target_pos.z if current_state == State.WANDER else peer_z
	if current_state == State.SEARCHING and _target_object:
		target_z = _target_object.global_position.z
	
	# Slow Z-lerp for casual walk look/wander, fast Z-lerp when actively chasing/alerted
	var lerp_factor: float = 4.0 if (current_state == State.CHASE or current_state == State.CAPTURE) else 1.2
	global_position.z = lerp(global_position.z, target_z, delta * lerp_factor)

	# Constrain rotation pitch/roll to remain upright
	rotation.x = 0.0
	rotation.z = 0.0

	# Check vision to detect intruders
	if current_state != State.CHASE and current_state != State.CAPTURE:
		_check_vision()

func _process_wander(delta: float) -> void:
	# Reset spotlight defaults
	spotlight.light_energy = 32.0
	spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)

	# Handle alert look action
	if _faint_look_timer > 0.0:
		_faint_look_timer -= delta
		velocity = Vector3.ZERO
		# Pause and rotate head towards suspicious target position
		var dir_to_target := (_target_pos - global_position).normalized()
		var target_yaw := atan2(-dir_to_target.x, -dir_to_target.z)
		mesh.rotation.y = rotate_toward(mesh.rotation.y, target_yaw, delta * 4.0)
		spotlight.rotation.y = mesh.rotation.y
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
		
		# Rotate visual mesh to face 3D walking direction (Godot forward is -Z)
		var target_yaw := atan2(-velocity.x, -velocity.z)
		mesh.rotation.y = rotate_toward(mesh.rotation.y, target_yaw, delta * 6.0)
		spotlight.rotation.y = mesh.rotation.y
		spotlight.rotation.x = deg_to_rad(-10.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		# We reached the target opening/object
		if _target_object:
			current_state = State.SEARCHING
			_state_timer = 0.0
		else:
			current_state = State.SCANNING
			_state_timer = 0.0

func _process_searching(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer += delta

	# Face the searchable object/window
	mesh.rotation.y = rotate_toward(mesh.rotation.y, PI, delta * 6.0)
	spotlight.rotation.y = mesh.rotation.y

	# Phase 1: Lift the background debris/object and point spotlight down
	if _state_timer < 1.0:
		if _state_timer - delta <= 0.0 and _target_object:
			_target_object.lift(1.5, 0.8)
		spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-60.0), delta * 4.0)
	# Phase 2: Sweep light underneath
	elif _state_timer < 2.5:
		spotlight.rotation.y = mesh.rotation.y + sin(_state_timer * 6.0) * deg_to_rad(20.0)
	# Phase 3: Lower object and return light
	elif _state_timer < 3.5:
		if _state_timer - delta < 2.5 and _target_object:
			_target_object.lower(0.8)
		spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-15.0), delta * 4.0)
		spotlight.rotation.y = lerp(spotlight.rotation.y, mesh.rotation.y, delta * 4.0)
	else:
		_target_object = null
		current_state = State.SCANNING
		_state_timer = 0.0

func _process_scanning(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer += delta

	# Turn forward towards the walkway opening (Z = 0.0)
	mesh.rotation.y = rotate_toward(mesh.rotation.y, PI, delta * 6.0)
	spotlight.rotation.x = lerp(spotlight.rotation.x, deg_to_rad(-15.0), delta * 4.0)

	# Sweep spotlight left and right across the opening
	var sweep_angle := sin(_state_timer * 3.0) * deg_to_rad(35.0)
	spotlight.rotation.y = mesh.rotation.y + sweep_angle

	if _state_timer > 4.0:
		spotlight.rotation.y = mesh.rotation.y
		_choose_next_wander()

func _process_suspicious(delta: float) -> void:
	var to_target: float = _target_pos.x - global_position.x
	var dist: float = abs(to_target)

	# Reset spotlight defaults
	spotlight.light_energy = 32.0
	spotlight.light_color = Color(1.0, 0.2, 0.2, 1.0)

	if dist > 0.4:
		# Walk slowly towards the sound opening (progression alert)
		velocity.x = sign(to_target) * patrol_speed
		velocity.z = 0.0
		var target_yaw := PI * 0.5 if velocity.x < 0.0 else -PI * 0.5
		mesh.rotation.y = rotate_toward(mesh.rotation.y, target_yaw, delta * 6.0)
		spotlight.rotation.y = mesh.rotation.y
		spotlight.rotation.x = deg_to_rad(-15.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_state_timer += delta
		# Peer through opening and perform intensive sweep at sound site
		mesh.rotation.y = rotate_toward(mesh.rotation.y, PI, delta * 6.0)
		spotlight.rotation.y = mesh.rotation.y + sin(_state_timer * 4.0) * deg_to_rad(45.0)
		
		if _state_timer > 4.5:
			spotlight.rotation.y = mesh.rotation.y
			_choose_next_wander()

func _process_chase(delta: float) -> void:
	if not is_instance_valid(_chase_target):
		_choose_next_wander()
		return

	var to_target: float = _chase_target.global_position.x - global_position.x
	var dist_x: float = abs(to_target)

	# Slowly shift head/eye horizontally to track player
	if dist_x > 0.4:
		velocity.x = sign(to_target) * chase_speed
		velocity.z = 0.0
		mesh.rotation.y = rotate_toward(mesh.rotation.y, PI, delta * 8.0)
		spotlight.rotation.y = mesh.rotation.y
		
		# Point light directly at chased target
		var dir_to_char: Vector3 = (_chase_target.global_position + Vector3(0.0, 1.0, 0.0) - spotlight.global_position).normalized()
		spotlight.rotation.x = asin(dir_to_char.y)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Check line of sight and cone angle continuously
	var space_state := get_world_3d().direct_space_state
	var spotlight_forward: Vector3 = -spotlight.global_transform.basis.z.normalized()
	var dir_to_char: Vector3 = (_chase_target.global_position + Vector3(0.0, 1.0, 0.0) - spotlight.global_position).normalized()
	var angle: float = rad_to_deg(spotlight_forward.angle_to(dir_to_char))
	
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
	
	# Dramatic blinding flash grab effect (energy = 200, bright white/cyan light)
	if _state_timer < 0.4:
		spotlight.light_color = Color(1.0, 1.0, 1.0, 1.0)
		spotlight.light_energy = 200.0
	else:
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
	
	var objects: Array[Node] = get_tree().get_nodes_in_group("searchable_objects")
	
	# Always prioritize background searchable objects to look like it is doing work
	if not objects.is_empty():
		var obj: SearchableObject = objects.pick_random() as SearchableObject
		if is_instance_valid(obj):
			_target_object = obj
			_target_pos = obj.global_position
			print("[Seeker %s] Heading to search background object: %s at 3D pos: %s" % [name, obj.name, str(_target_pos)])
			return

	# Otherwise (fallback), choose a random 3D position in the background wander range
	_target_pos = Vector3(
		randf_range(wander_range_x.x, wander_range_x.y),
		global_position.y,
		randf_range(wander_range_z.x, wander_range_z.y)
	)
	_target_object = null
	print("[Seeker %s] Giant wandering in background (fallback) to 3D pos: %s" % [name, str(_target_pos)])

func _check_vision() -> void:
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
				# Spotted! Transition to CHASE state immediately (entering 2.0s warning window)
				_chase_target = target
				current_state = State.CHASE
				_chase_timer = 0.0
				_has_heard_anything = true
				alert_level = 1.0 # Instant max alert upon visual sighting
				print("[Seeker %s] Giant SPOTTED target: %s! Warning flash started..." % [name, target.name])
				break

func _on_sound_heard(origin: Vector3, radius: float, is_shout: bool) -> void:
	if current_state == State.CHASE or current_state == State.CAPTURE:
		return
	
	var dist_x: float = abs(global_position.x - origin.x)
	if dist_x <= radius:
		_has_heard_anything = true
		
		# Increase alert level based on sound severity
		var alert_inc := 0.6 if is_shout else 0.35
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
			_target_pos = Vector3(origin.x, global_position.y, peer_z)
			_faint_look_timer = 1.8
			_target_object = null
			print("[Seeker %s] Giant heard noise at X: %0.2f on Low Alert (%0.2f). Looking but disregarding..." % [name, origin.x, alert_level])

func _on_toddler_chirped(origin: Vector3, radius: float) -> void:
	_on_sound_heard(origin, radius, false)
