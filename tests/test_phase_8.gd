class_name TestPhase8
extends BaseTest

var player: Player
var adult: Adult
var toddler: Toddler
var elder: Elder
var seeker: Seeker
var signal_triggered := false

func before_each() -> void:
	# Clean registrations
	FamilyManager.active_members.clear()
	FamilyManager.player = null
	signal_triggered = false
	
	player = load("res://scenes/player/player.tscn").instantiate()
	player.set_physics_process(false)
	Engine.get_main_loop().root.add_child(player)
	FamilyManager.register_player(player)
	
	adult = load("res://scenes/family/adult.tscn").instantiate()
	adult.set_physics_process(false)
	Engine.get_main_loop().root.add_child(adult)
	FamilyManager.register_member(adult)
	
	toddler = load("res://scenes/family/toddler.tscn").instantiate()
	toddler.set_physics_process(false)
	Engine.get_main_loop().root.add_child(toddler)
	FamilyManager.register_member(toddler)
	
	elder = load("res://scenes/family/elder.tscn").instantiate()
	elder.set_physics_process(false)
	Engine.get_main_loop().root.add_child(elder)
	FamilyManager.register_member(elder)
	
	seeker = load("res://scenes/seeker/seeker.tscn").instantiate()
	seeker.set_physics_process(false)
	Engine.get_main_loop().root.add_child(seeker)
	seeker.add_to_group("seekers")

func after_each() -> void:
	if is_instance_valid(player): player.free()
	if is_instance_valid(adult): adult.free()
	if is_instance_valid(toddler): toddler.free()
	if is_instance_valid(elder): elder.free()
	if is_instance_valid(seeker): seeker.free()
	Engine.time_scale = 1.0

func test_focus_slows_time() -> void:
	# Simulate pressing focus action
	Input.action_press("focus_action")
	player._physics_process(0.1)
	assert_eq(Engine.time_scale, 0.25, "Time scale should be slowed down to 0.25 when focus is active")
	
	# Release focus
	Input.action_release("focus_action")
	player._physics_process(0.1)
	assert_eq(Engine.time_scale, 1.0, "Time scale should return to 1.0 when focus is released")

func test_pebble_throw_directional() -> void:
	player.facing_direction = -1.0
	var initial_pebble_count = 0
	for child in Engine.get_main_loop().root.get_children():
		if child is Pebble:
			initial_pebble_count += 1
			
	player._throw_pebble()
	
	var new_pebbles = []
	for child in Engine.get_main_loop().root.get_children():
		if child is Pebble:
			new_pebbles.append(child)
			
	assert_eq(new_pebbles.size() - initial_pebble_count, 1, "One pebble should be instantiated")
	var pebble = new_pebbles.back() as Pebble
	assert_eq(sign(pebble.velocity.x), -1.0, "Pebble horizontal launch velocity should match player facing direction")
	
	# Cleanup pebble
	pebble.free()

func test_player_ladder_climbing() -> void:
	var ladder_area := Area3D.new()
	ladder_area.add_to_group("ladders")
	
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 5.0, 2.0)
	col.shape = shape
	col.name = "CollisionShape3D"
	ladder_area.add_child(col)
	
	Engine.get_main_loop().root.add_child(ladder_area)
	
	player._climbable_areas.append(ladder_area)
	
	# Trigger climbing state manually by simulating move_up input
	Input.action_press("move_up")
	player._physics_process(0.1)
	
	assert_true(player._is_climbing, "Player should enter climbing state when moving up on a ladder")
	
	# Clean up input and ladder
	Input.action_release("move_up")
	ladder_area.free()

func test_adult_toddler_launch() -> void:
	var launcher: LedgeLauncher = load("res://scenes/objects/ledge_launcher.gd").new()
	launcher.global_position = Vector3(5.0, 0.0, 0.0)
	Engine.get_main_loop().root.add_child(launcher)
	
	# Position characters near launcher
	adult.global_position = Vector3(1.0, 0.0, 0.0)
	toddler.global_position = Vector3(1.5, 0.0, 0.0)
	
	adult.try_launch_toddler(launcher)
	
	assert_eq(toddler.current_state, FamilyMember.State.LAUNCHED, "Toddler should enter LAUNCHED state")
	assert_true(toddler.velocity.y > 10.0, "Toddler should be launched upwards with positive Y velocity")
	assert_true(toddler.velocity.x > 0.0, "Toddler should be tossed forward in the direction of the launcher point")
	
	launcher.free()

func test_elder_hacking_sleep_overload() -> void:
	var console: HackConsole = load("res://scenes/objects/hack_console.gd").new()
	console.is_sleep_overload = true
	Engine.get_main_loop().root.add_child(console)
	
	elder.start_hacking(console)
	assert_true(elder._hack_ui != null, "Elder should show hacking UI panel")
	
	# Complete the hack manually
	console.complete_hack()
	
	assert_eq(seeker.current_state, Seeker.State.SLEEP, "Seeker should be put to sleep upon successful console overload")
	assert_true(seeker._sleep_timer > 5.0, "Seeker sleep duration should be set")
	
	console.free()

func _on_plate_pressed(pressed: bool) -> void:
	print("[Test Phase 8] _on_plate_pressed callback caught: ", pressed)
	signal_triggered = pressed

func test_toddler_weightless_infiltrator() -> void:
	var plate: PressurePlate = load("res://scenes/objects/pressure_plate.gd").new()
	plate.requires_heavy_weight = true
	
	plate.plate_pressed.connect(_on_plate_pressed)
	
	# Toddler enters plate
	plate._on_body_entered(toddler)
	assert_false(signal_triggered, "Toddler should not trigger heavy pressure plates")
	print("[Test Infiltrator] After toddler, overlapping size: ", plate._overlapping_bodies.size())
	
	# Adult enters plate
	plate._on_body_entered(adult)
	print("[Test Infiltrator] After adult, overlapping size: ", plate._overlapping_bodies.size())
	print("[Test Infiltrator] signal_triggered status: ", signal_triggered)
	
	assert_true(signal_triggered, "Adult should trigger heavy pressure plates")
	plate.free()
