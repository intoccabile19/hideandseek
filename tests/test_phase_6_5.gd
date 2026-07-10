extends BaseTest

func before_each() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = false
		for n in tree.get_nodes_in_group("game_state_menus"):
			n.free()
		for n in tree.get_nodes_in_group("seeker"):
			n.free()
		for n in tree.get_nodes_in_group("escape_zones"):
			n.free()
		FamilyManager.active_members.clear()
		FamilyManager.current_target_member = null

func test_targeting_controls_by_index() -> void:
	var member1 = FamilyMember.new()
	var member2 = FamilyMember.new()
	FamilyManager.register_member(member1)
	FamilyManager.register_member(member2)
	
	# Select ALL
	FamilyManager.select_target_by_index(-1)
	assert_true(FamilyManager.current_target_member == null)
	
	# Select index 0
	FamilyManager.select_target_by_index(0)
	assert_eq(FamilyManager.current_target_member, member1)
	
	# Select index 1
	FamilyManager.select_target_by_index(1)
	assert_eq(FamilyManager.current_target_member, member2)
	
	# Clean up
	member1.free()
	member2.free()

func test_sound_propagation_scaling() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	var player = Player.new()
	var member = FamilyMember.new()
	
	tree.root.add_child(player)
	tree.root.add_child(member)
	
	FamilyManager.register_player(player)
	FamilyManager.register_member(member)
	
	player.global_position = Vector3(0, 0, 0)
	
	# Case 1: Member is very close (2.0 meters away) -> Whisper
	member.global_position = Vector3(2.0, 0, 0)
	FamilyManager.select_target_by_index(0)
	
	var sound_info_close = FamilyManager._calculate_sound_propagation(player.global_position)
	assert_false(sound_info_close.is_shout, "Close target should whisper")
	assert_eq(sound_info_close.radius, FamilyManager.WHISPER_SOUND_RADIUS)
	
	# Case 2: Member is far (10.0 meters away) -> Shout
	member.global_position = Vector3(10.0, 0, 0)
	
	var sound_info_far = FamilyManager._calculate_sound_propagation(player.global_position)
	assert_true(sound_info_far.is_shout, "Far target should shout")
	assert_eq(sound_info_far.radius, FamilyManager.SHOUT_SOUND_RADIUS)
	
	# Clean up
	FamilyManager.unregister_player()
	player.free()
	member.free()

func test_seeker_role_initialization() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	var seeker_scene: PackedScene = load("res://scenes/seeker/seeker.tscn")
	var seeker_lazy = seeker_scene.instantiate() as Seeker
	seeker_lazy.seeker_type = Seeker.SeekerType.LAZY
	
	tree.root.add_child(seeker_lazy)
	
	# Verify initialized values configured in Seeker._ready()
	assert_eq(seeker_lazy.patrol_speed, 2.2)
	assert_eq(seeker_lazy.investigate_speed, 1.3)
	assert_eq(seeker_lazy.alert_decay_rate, 0.15)
	assert_eq(seeker_lazy.alert_growth_multiplier, 0.5)
	
	seeker_lazy.free()

func test_escape_zone_multi_member_victory() -> void:
	# Instantiate GameStateMenu to capture show_victory
	var menu_scene: PackedScene = load("res://scenes/ui/game_state_menu.tscn")
	var menu = menu_scene.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(menu)
	
	var zone = EscapeZone.new()
	tree.root.add_child(zone)
	
	var player = Player.new()
	tree.root.add_child(player)
	
	var member = FamilyMember.new()
	tree.root.add_child(member)
	FamilyManager.register_member(member)
	
	# Case 1: Only player enters -> Should NOT win yet
	zone._on_body_entered(player)
	assert_false(menu.victory_screen.visible, "Should not trigger victory if companion is missing")
	
	# Case 2: Companion enters too -> Should win!
	zone._on_body_entered(member)
	assert_true(menu.victory_screen.visible, "Should win once all active members escape")
	
	# Clean up
	tree.paused = false
	player.free()
	member.free()
	zone.free()
	menu.free()
