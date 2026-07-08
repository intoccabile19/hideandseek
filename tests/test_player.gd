# tests/test_player.gd
extends BaseTest

const PLAYER_SCENE_PATH = "res://scenes/player/player.tscn"

func test_player_scene_loads() -> void:
	var player_scene = load(PLAYER_SCENE_PATH)
	assert_true(player_scene != null, "Player scene should load successfully")

func test_player_instantiation_and_properties() -> void:
	var player_scene = load(PLAYER_SCENE_PATH)
	if player_scene == null:
		return
		
	var player = player_scene.instantiate()
	assert_true(player != null, "Player scene should instantiate successfully")
	assert_true(player is CharacterBody3D, "Player should be a CharacterBody3D")
	
	# Check export values and initial values
	assert_eq(player.speed, 5.0, "Default movement speed should be 5.0")
	assert_eq(player.jump_velocity, 6.0, "Default jump velocity should be 6.0")
	
	player.free()

func test_player_z_axis_lock() -> void:
	var player_scene = load(PLAYER_SCENE_PATH)
	if player_scene == null:
		return
		
	var player = player_scene.instantiate() as CharacterBody3D
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(player)
		
	# Set Z to some value to test if it forces it to 0 in physics process
	player.global_position.z = 5.0
	
	# Manually run one physics step
	player._physics_process(0.016)
	
	assert_eq(player.global_position.z, 0.0, "Player Z position must be locked to 0.0")
	assert_eq(player.velocity.z, 0.0, "Player Z velocity must be locked to 0.0")
	
	if tree and player.get_parent():
		tree.root.remove_child(player)
	player.free()

