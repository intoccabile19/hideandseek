# tests/test_family.gd
extends BaseTest

const PLAYER_SCENE_PATH = "res://scenes/player/player.tscn"
const MEMBER_SCENE_PATH = "res://scenes/family/family_member.tscn"

func test_family_member_lifecycle_registration() -> void:
	# Clean up previous registry if any
	FamilyManager.active_members.clear()
	
	var member_scene = load(MEMBER_SCENE_PATH)
	assert_true(member_scene != null, "Family member scene should load")
	
	var member1 = member_scene.instantiate()
	var member2 = member_scene.instantiate()
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(member1)
		tree.root.add_child(member2)
		
	# Verify registration
	assert_eq(FamilyManager.active_members.size(), 2, "Both members should register automatically")
	assert_eq(FamilyManager.get_follow_index(member1), 0, "First member index should be 0")
	assert_eq(FamilyManager.get_follow_index(member2), 1, "Second member index should be 1")
	
	# Verify unregistration
	if tree:
		tree.root.remove_child(member1)
	assert_eq(FamilyManager.active_members.size(), 1, "First member should unregister")
	
	if tree:
		tree.root.remove_child(member2)
	assert_eq(FamilyManager.active_members.size(), 0, "Second member should unregister")
	
	member1.free()
	member2.free()

func test_command_broadcast_updates_state() -> void:
	FamilyManager.active_members.clear()
	
	var member_scene = load(MEMBER_SCENE_PATH)
	var member = member_scene.instantiate() as FamilyMember
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(member)
		
	# Initial state should be FREEZE (1)
	assert_eq(member.current_state, 1, "Initial state should be FREEZE (1)")
	
	# Broadcast follow (0)
	FamilyManager.broadcast_follow(Vector3.ZERO)
	assert_eq(member.current_state, 0, "State should update to FOLLOW (0)")
	
	# Broadcast freeze (1)
	FamilyManager.broadcast_freeze(Vector3.ZERO)
	assert_eq(member.current_state, 1, "State should update to FREEZE (1)")
	
	if tree:
		tree.root.remove_child(member)
	member.free()

func test_whisper_sound_propagation() -> void:
	FamilyManager.active_members.clear()
	
	var member_scene = load(MEMBER_SCENE_PATH)
	var member = member_scene.instantiate() as FamilyMember
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(member)
		
	# Position member close to origin (2.0 units away)
	member.global_position = Vector3(2.0, 0.0, 0.0)
	
	# Whisper check: distance = 2.0 (<= 6.0 limit) -> Whisper
	var sound_info: Dictionary = FamilyManager._calculate_sound_propagation(Vector3.ZERO)
	assert_false(sound_info.is_shout, "Should be categorized as whisper")
	assert_eq(sound_info.radius, 2.0, "Whisper radius should be 2.0")
	
	# Shout check: position member far away (10.0 units)
	member.global_position = Vector3(10.0, 0.0, 0.0)
	sound_info = FamilyManager._calculate_sound_propagation(Vector3.ZERO)
	assert_true(sound_info.is_shout, "Should be categorized as shout")
	assert_eq(sound_info.radius, 15.0, "Shout radius should be 15.0")
	
	if tree:
		tree.root.remove_child(member)
	member.free()

func test_dynamic_queue_sorting() -> void:
	FamilyManager.active_members.clear()
	
	var member_scene = load(MEMBER_SCENE_PATH)
	var member1 = member_scene.instantiate()
	var member2 = member_scene.instantiate()
	
	var player_scene = load(PLAYER_SCENE_PATH)
	var player = player_scene.instantiate()
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(player)
		tree.root.add_child(member1)
		tree.root.add_child(member2)
		
	player.global_position = Vector3.ZERO
	# Member 1 far away, Member 2 close
	member1.global_position = Vector3(10.0, 0.0, 0.0)
	member2.global_position = Vector3(2.0, 0.0, 0.0)
	
	FamilyManager.update_queue_order()
	
	assert_eq(FamilyManager.get_follow_index(member2), 0, "Member 2 should be at index 0 (closest)")
	assert_eq(FamilyManager.get_follow_index(member1), 1, "Member 1 should be at index 1 (further)")
	
	if tree:
		tree.root.remove_child(player)
		tree.root.remove_child(member1)
		tree.root.remove_child(member2)
		
	player.free()
	member1.free()
	member2.free()

