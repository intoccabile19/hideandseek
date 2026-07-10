extends BaseTest

func before_each() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = false
		# Clean up any existing instances from groups to avoid pollution
		for n in tree.get_nodes_in_group("game_state_menus"):
			n.free()
		for n in tree.get_nodes_in_group("seeker"):
			n.free()

func test_sound_manager_methods() -> void:
	# Verify that autoload methods execute programmatically without crashing
	assert_true(SoundManager != null, "SoundManager autoload should be registered")
	
	# Trigger synthetic call playbacks
	SoundManager.play_whistle()
	SoundManager.play_chirp(Vector3.ZERO)
	SoundManager.play_footstep(Vector3.ZERO, -10.0)
	SoundManager.update_heartbeat(0.5)

func test_hud_overlay_updates() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	var hud_scene: PackedScene = load("res://scenes/ui/hud_overlay.tscn")
	var hud = hud_scene.instantiate()
	tree.root.add_child(hud)
	
	# Verify components exist
	assert_true(hud.get_node("HUDContainer/BottomPanel/CommandLabel") != null, "HUD should have command label")
	assert_true(hud.get_node("HUDContainer/TopPanel/VBox/DetectionBar") != null, "HUD should have detection bar")
	assert_true(hud.get_node("HUDContainer/TopPanel/VBox/WarningLabel") != null, "HUD should have warning label")
	
	# Test command text updates
	hud._update_command_text(0) # FOLLOW
	assert_eq(hud.command_label.text, "MODE: FOLLOW")
	hud._update_command_text(1) # FREEZE
	assert_eq(hud.command_label.text, "MODE: FREEZE & HIDE")
	
	hud.free()

func test_game_state_menu_behavior() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	var menu_scene: PackedScene = load("res://scenes/ui/game_state_menu.tscn")
	var menu = menu_scene.instantiate()
	tree.root.add_child(menu)
	
	# Verify group registration
	var groups = tree.get_nodes_in_group("game_state_menus")
	assert_true(groups.has(menu), "GameStateMenu should add itself to game_state_menus group")
	
	# Test menu visibility switches
	menu.show_main_menu()
	assert_true(menu.main_menu.visible, "Main menu should be visible")
	assert_true(tree.paused, "Tree should pause on menu show")
	
	menu.show_game_over()
	assert_true(menu.game_over_screen.visible, "Game over screen should be visible")
	
	menu.show_victory(3)
	assert_true(menu.victory_screen.visible, "Victory screen should be visible")
	assert_eq(menu.score_label.text, "FAMILY MEMBERS ESCAPED: 3")
	
	# Test volume slider changes
	assert_true(menu.volume_slider != null, "Volume slider should exist")
	assert_true(menu.volume_label != null, "Volume label should exist")
	menu._on_volume_changed(0.8)
	assert_eq(menu.volume_label.text, "VOLUME: 80%")

	# Start game resumes tree
	menu._on_start_pressed()
	assert_false(menu.main_menu.visible, "Main menu should hide on start")
	assert_false(tree.paused, "Tree should unpause on start")
	
	menu.free()

func test_escape_zone_victory_trigger() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	# Instantiate GameStateMenu
	var menu_scene: PackedScene = load("res://scenes/ui/game_state_menu.tscn")
	var menu = menu_scene.instantiate()
	tree.root.add_child(menu)
	
	var zone = EscapeZone.new()
	tree.root.add_child(zone)
	
	var player = Player.new()
	tree.root.add_child(player)
	
	# Emulate body entered escape zone
	zone._on_body_entered(player)
	
	# Verify menu transitioned to victory screen
	assert_true(menu.victory_screen.visible, "Victory screen should show up when player enters EscapeZone")
	
	# Clean up
	tree.paused = false
	player.free()
	zone.free()
	menu.free()
