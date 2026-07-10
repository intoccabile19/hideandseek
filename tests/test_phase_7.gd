extends BaseTest

func before_each() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = false
		for n in tree.get_nodes_in_group("game_state_menus"):
			n.free()
		for n in tree.get_nodes_in_group("escape_zones"):
			n.free()
		FamilyManager.active_members.clear()
		FamilyManager.current_target_member = null

func test_save_manager_save_and_load() -> void:
	var test_path := "res://scenes/levels/level_2_cargo_hold.tscn"
	
	# Save the path
	SaveManager.save_level(test_path)
	
	# Verify save exists
	assert_true(SaveManager.has_save(), "Save file should exist after saving")
	
	# Load and compare
	var loaded_path := SaveManager.load_level()
	assert_eq(loaded_path, test_path, "Loaded level path should match the saved path")

func test_level_scene_files_exist() -> void:
	assert_true(FileAccess.file_exists("res://scenes/levels/level_1_tutorial.tscn"), "Level 1 scene should exist")
	assert_true(FileAccess.file_exists("res://scenes/levels/level_2_cargo_hold.tscn"), "Level 2 scene should exist")
	assert_true(FileAccess.file_exists("res://scenes/levels/level_3_engine_room.tscn"), "Level 3 scene should exist")

func test_escape_zone_triggers_autosave() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	# Setup test escape zone pointing to Level 2
	var zone = EscapeZone.new()
	zone.next_level_path = "res://scenes/levels/level_2_cargo_hold.tscn"
	tree.root.add_child(zone)
	
	# Setup player to trigger escape
	var dummy_player = Player.new()
	tree.root.add_child(dummy_player)
	FamilyManager.register_player(dummy_player)
	
	# Put player inside the zone
	zone.escaped_members.append(dummy_player)
	
	# Trigger check
	zone._check_victory_condition()
	
	# Verify that SaveManager registered the next level as the active save!
	assert_eq(SaveManager.load_level(), "res://scenes/levels/level_2_cargo_hold.tscn", "Entering escape zone should auto-save next level path")
	
	# Clean up
	dummy_player.free()
	zone.free()

func test_lame_seeker_properties() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	var seeker_scene := load("res://scenes/seeker/seeker.tscn") as PackedScene
	var seeker := seeker_scene.instantiate() as Seeker
	seeker.seeker_type = Seeker.SeekerType.LAME
	tree.root.add_child(seeker)
	
	# Verify LAME properties: low patrol speed, zero alert growth
	assert_eq(seeker.patrol_speed, 1.5, "LAME seeker should have low patrol speed")
	assert_eq(seeker.alert_growth_multiplier, 0.0, "LAME seeker should have 0 alert growth")
	
	# Verify that calling _on_sound_heard does not change alert level
	seeker._on_sound_heard(Vector3(10, 0, 0), 20.0, true)
	assert_eq(seeker.alert_level, 0.0, "LAME seeker should ignore sound and maintain 0 alert")
	
	# Clean up
	seeker.free()
