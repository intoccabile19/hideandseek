class_name Toddler
extends FamilyMember

## Time (in seconds) the toddler remains quiet before wandering due to curiosity.
@export var curiosity_cooldown: float = 5.0

## Sound circle projection radius of the toddler's chirps.
@export var chirp_sound_radius: float = 3.5

var _curiosity_timer: float = 0.0
var _chirp_timer: float = 0.0
var _wander_target_x: float = 0.0
var tension_label: Label3D = null

# Phase 8 vent properties
var _is_vent_crawling: bool = false
var _vent_exit_node: Node3D = null
var _vent_speed: float = 4.0
var _saved_interact_target: Node3D = null
var _saved_interact_dir: float = 0.0

func _ready() -> void:
	super._ready()
	# Override base defaults for the toddler subclass
	speed = 4.5
	spacing_steps = 8
	_reset_curiosity_timer()
	_reset_chirp_timer()
	
	# Programmatic floating tension indicator
	tension_label = Label3D.new()
	tension_label.billboard = 1 # Billboard enabled
	tension_label.position = Vector3(0.0, 1.8, 0.0)
	tension_label.pixel_size = 0.005
	tension_label.font_size = 24
	tension_label.outline_size = 6
	add_child(tension_label)

func get_size_class() -> String:
	return "Small"

func _physics_process(delta: float) -> void:
	if _is_vent_crawling:
		if is_instance_valid(_vent_exit_node):
			global_position = global_position.move_toward(_vent_exit_node.global_position, _vent_speed * delta)
			global_position.z = 0.0
			if global_position.distance_to(_vent_exit_node.global_position) < 0.2:
				global_position = _vent_exit_node.global_position
				_is_vent_crawling = false
				_vent_exit_node = null
				
				if is_instance_valid(_saved_interact_target):
					var target := _saved_interact_target
					var dir := _saved_interact_dir
					_saved_interact_target = null
					
					if target.is_in_group("vents"):
						is_hidden = true
						current_state = State.FREEZE
						print("[Toddler %s] Exited vent, stopping since destination target was a vent." % name)
					else:
						interact_with(target, dir)
						print("[Toddler %s] Exited vent, resuming interaction with: %s" % [name, target.name])
				else:
					is_hidden = true
					current_state = State.FREEZE
					print("[Toddler %s] Exited vent crawlspace, remaining hidden and frozen" % name)
		else:
			_is_vent_crawling = false
			is_hidden = true
			current_state = State.FREEZE
		return

	# Update floating tension indicator
	if is_instance_valid(tension_label):
		if current_state == State.FREEZE:
			var pct: float = clamp((curiosity_cooldown - _curiosity_timer) / curiosity_cooldown, 0.0, 1.0)
			var pct_int: int = int(pct * 100.0)
			tension_label.text = "TENSION: %d%%" % pct_int
			if pct < 0.5:
				tension_label.modulate = Color(0.2, 0.8, 0.2)
			elif pct < 0.8:
				tension_label.modulate = Color(1.0, 0.8, 0.0)
			else:
				tension_label.modulate = Color(1.0, 0.0, 0.0)
		elif current_state == State.WANDER:
			tension_label.text = "WANDERING!"
			tension_label.modulate = Color(1.0, 0.0, 0.0)
		else:
			tension_label.text = ""

	# Handle curiosity timer when frozen/hiding.
	if current_state == State.FREEZE or current_state == State.HIDING:
		if current_state == State.HIDING and is_hidden:
			_reset_curiosity_timer()
		else:
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
		# Auto-Vent Routing for FOLLOW and INTERACTING states
		var target_node: Node3D = null
		if current_state == State.FOLLOW:
			target_node = FamilyManager.player
		elif current_state == State.INTERACTING:
			target_node = _interact_target
			
		if is_instance_valid(target_node) and abs(target_node.global_position.y - global_position.y) > 2.0:
			var vents := get_tree().get_nodes_in_group("vents")
			var best_vent: Node3D = null
			var min_dist: float = 99999.0
			for vent in vents:
				if vent is Node3D and abs(vent.global_position.y - global_position.y) < 1.5:
					var dist := global_position.distance_to(vent.global_position)
					if dist < min_dist:
						min_dist = dist
						best_vent = vent
			if best_vent:
				var to_vent_x := best_vent.global_position.x - global_position.x
				if abs(to_vent_x) < 0.8:
					# Trigger vent crawl
					if best_vent.has_method("execute_interaction"):
						if current_state == State.INTERACTING:
							_saved_interact_target = _interact_target
							_saved_interact_dir = _interact_dir
						best_vent.call("execute_interaction", self)
				else:
					velocity.x = sign(to_vent_x) * speed
					velocity.z = 0.0
					if not is_on_floor():
						velocity.y -= _gravity * delta
					move_and_slide()
					global_position.z = 0.0
				return
				
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
	SoundManager.play_chirp(global_position)
	_reset_chirp_timer()

## Declares to the manager that this class is a Toddler.
func is_toddler_class() -> bool:
	return true

## Commanded to crawl through a vent pipeline
func crawl_through_vent(entrance: Node3D, exit_node: Node3D) -> void:
	_is_vent_crawling = true
	_vent_exit_node = exit_node
	current_state = State.FREEZE
	is_hidden = true
	global_position = entrance.global_position
	print("[Toddler %s] Entered vent crawlspace at X: %0.2f" % [name, global_position.x])
