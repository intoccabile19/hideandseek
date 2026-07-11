class_name TestSeeker
extends BaseTest

var seeker: Seeker
var player: Player
var toddler: Toddler
var searchable: SearchableObject

func before_each() -> void:
	# Clear registrations
	FamilyManager.active_members.clear()
	FamilyManager.player = null
	
	seeker = load("res://scenes/seeker/seeker.tscn").instantiate()
	seeker.patrol_speed = 10.0
	seeker.chase_speed = 20.0
	seeker.background_z = -12.0
	seeker.peer_z = -3.5
	seeker.vision_range = 25.0
	seeker.wander_range_x = Vector2(-20.0, 20.0)
	# Disable background physics processing to prevent movement interference
	seeker.set_physics_process(false)
	Engine.get_main_loop().root.add_child(seeker)
	
	searchable = load("res://scenes/objects/searchable_object.gd").new()
	var mesh := MeshInstance3D.new()
	searchable.add_child(mesh)
	searchable.mesh = mesh
	searchable.name = "TestSearchable"
	searchable.global_position = Vector3(5.0, 0.0, -12.0)
	Engine.get_main_loop().root.add_child(searchable)
	
	player = null
	toddler = null

func after_each() -> void:
	if is_instance_valid(seeker):
		seeker.free()
	if is_instance_valid(player):
		player.free()
	if is_instance_valid(toddler):
		toddler.free()
	if is_instance_valid(searchable):
		searchable.free()

func test_seeker_wander_flow() -> void:
	assert_true(seeker.current_state == Seeker.State.WANDER)

func test_seeker_hears_sound() -> void:
	# Emit a sound circle within range
	seeker.global_position = Vector3.ZERO
	FamilyManager.sound_emitted.emit(Vector3(4.0, 0.0, 0.0), 5.0, true)
	
	# Should transition to SUSPICIOUS targeting X = 4.0
	assert_true(seeker.current_state == Seeker.State.SUSPICIOUS)
	assert_true(abs(seeker._target_pos.x - 4.0) < 0.01)

func test_seeker_spots_player() -> void:
	# Spawn player in vision path
	player = load("res://scenes/player/player.tscn").instantiate()
	player.global_position = Vector3(0.0, 0.0, 0.0)
	player.set_physics_process(false) # Disable gravity falling in test!
	Engine.get_main_loop().root.add_child(player)
	FamilyManager.register_player(player)
	
	# Place seeker directly facing the player from background (looking towards +Z walkway)
	seeker.global_position = Vector3(0.0, 0.0, -10.0)
	seeker._gravity = 0.0
	seeker.chase_speed = 0.0 # Prevent Seeker from moving away during chase frames
	seeker.rotation.y = PI
	seeker.spotlight.rotation.y = 0.0
	seeker.spotlight.rotation.x = deg_to_rad(-65.0)
	# Force sweep check
	seeker._check_vision()
	assert_true(seeker._spotted_target == player, "Player should be spotted by vision sweep")
	
	# Simulate physics process frames to accumulate alert level to max
	for i in range(40):
		seeker._physics_process(0.2)
		
	# Should transition to CHASE targeting the player
	assert_true(seeker.current_state == Seeker.State.CHASE)
	assert_true(seeker._chase_target == player)

func test_seeker_ignores_hidden_actor() -> void:
	toddler = load("res://scenes/family/toddler.tscn").instantiate()
	toddler.global_position = Vector3(0.0, 0.0, 0.0)
	toddler.set_physics_process(false)
	Engine.get_main_loop().root.add_child(toddler)
	FamilyManager.register_member(toddler)
	
	# Mark toddler as hidden
	toddler.is_hidden = true
	
	seeker.global_position = Vector3(0.0, 0.0, -3.5)
	seeker.mesh.rotation.y = PI
	seeker.spotlight.rotation.y = PI
	seeker.spotlight.rotation.x = deg_to_rad(-60.0)
	seeker._check_vision()
	
	# Seeker must NOT chase the hidden toddler
	assert_true(seeker.current_state != Seeker.State.CHASE)
