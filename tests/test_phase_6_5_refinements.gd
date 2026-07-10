extends BaseTest

func before_each() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = false
		for n in tree.get_nodes_in_group("game_state_menus"):
			n.free()
		for n in tree.get_nodes_in_group("cover_zones"):
			n.free()
		FamilyManager.active_members.clear()
		FamilyManager.current_target_member = null

func test_redundant_hide_commands_ignored() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
		
	# Setup cover zone
	var cover_zone = CoverZone.new()
	cover_zone.zone_size = "Medium"
	cover_zone.capacity = 2
	tree.root.add_child(cover_zone)
	cover_zone.add_to_group("cover_zones")
	
	# Setup companion
	var member = FamilyMember.new()
	tree.root.add_child(member)
	FamilyManager.register_member(member)
	
	# Initial freeze -> should assign cover and transition to HIDING
	FamilyManager.broadcast_freeze(Vector3.ZERO)
	assert_eq(member.current_state, FamilyMember.State.HIDING)
	var first_cover = member._assigned_cover
	assert_true(first_cover != null, "Companion should be assigned to a cover zone")
	
	# Repeated freeze -> should NOT release or reallocate cover
	FamilyManager.broadcast_freeze(Vector3.ZERO)
	assert_eq(member.current_state, FamilyMember.State.HIDING)
	assert_eq(member._assigned_cover, first_cover, "Cover assignment should remain identical upon repeated hide command")
	
	# Clean up
	member.free()
	cover_zone.free()
