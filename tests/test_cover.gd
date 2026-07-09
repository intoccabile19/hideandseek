extends BaseTest

func test_cover_zone_compatibility() -> void:
	var small_zone := CoverZone.new()
	small_zone.zone_size = "Small"
	small_zone.capacity = 2
	
	assert_true(small_zone.has_space_for("Small"), "Small cover zone should accommodate Small size")
	assert_false(small_zone.has_space_for("Large"), "Small cover zone should reject Large size")
	
	var medium_zone := CoverZone.new()
	medium_zone.zone_size = "Medium"
	medium_zone.capacity = 2
	assert_true(medium_zone.has_space_for("Small"), "Medium cover zone should accommodate Small size")
	assert_true(medium_zone.has_space_for("Medium"), "Medium cover zone should accommodate Medium size")
	assert_false(medium_zone.has_space_for("Large"), "Medium cover zone should reject Large size")
	
	var large_zone := CoverZone.new()
	large_zone.zone_size = "Large"
	large_zone.capacity = 2
	assert_true(large_zone.has_space_for("Small"), "Large cover zone should accommodate Small size")
	assert_true(large_zone.has_space_for("Large"), "Large cover zone should accommodate Large size")
	
	small_zone.free()
	medium_zone.free()
	large_zone.free()

func test_cover_capacity_exhaustion() -> void:
	var zone := CoverZone.new()
	zone.zone_size = "Small"
	zone.capacity = 1
	
	var dummy_actor1 := Node3D.new()
	var dummy_actor2 := Node3D.new()
	
	assert_true(zone.has_space_for("Small"), "Zone should have space initially")
	zone.assign_actor(dummy_actor1)
	assert_false(zone.has_space_for("Small"), "Zone should be full when capacity is reached")
	
	zone.release_actor(dummy_actor1)
	assert_true(zone.has_space_for("Small"), "Zone should have space again after actor release")
	
	zone.free()
	dummy_actor1.free()
	dummy_actor2.free()

func test_cover_navigation_flow() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	
	var toddler := Toddler.new()
	toddler.global_position = Vector3(0.0, 0.0, 0.0)
	
	var zone := CoverZone.new()
	zone.zone_size = "Small"
	zone.capacity = 1
	zone.global_position = Vector3(5.0, 0.0, 0.0)
	
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 2.0)
	col.shape = shape
	zone.add_child(col)
	
	if tree:
		tree.root.add_child(toddler)
		tree.root.add_child(zone)
		
	# Broadcast FREEZE (starts cover search)
	toddler._on_command_broadcast(1) # State.FREEZE
	
	assert_eq(toddler.current_state, 2, "Toddler should transition to State.HIDING (2)")
	assert_eq(toddler._assigned_cover, zone, "Toddler should be assigned to the nearby cover zone")
	assert_false(toddler.is_hidden, "Toddler should not be marked hidden immediately")
	
	# Process physics ticks to walk to cover
	for i in range(120):
		toddler._physics_process(0.016)
		if toddler.is_hidden:
			break
			
	assert_true(toddler.is_hidden, "Toddler should reach the cover slot and hide")
	assert_true(toddler.global_position.x > 3.9, "Toddler should be close to the cover zone center")
	
	# Broadcast FOLLOW (exits cover)
	toddler._on_command_broadcast(0) # State.FOLLOW
	assert_eq(toddler.current_state, 0, "Toddler should transition back to State.FOLLOW (0)")
	assert_true(toddler._assigned_cover == null, "Toddler should release the cover assignment")
	assert_false(toddler.is_hidden, "Toddler should not be marked hidden anymore")
	
	if tree:
		tree.root.remove_child(toddler)
		tree.root.remove_child(zone)
		
	toddler.free()
	zone.free()
