# tests/test_interaction.gd
extends BaseTest

const ADULT_SCENE_PATH = "res://scenes/family/adult.tscn"
const TODDLER_SCENE_PATH = "res://scenes/family/toddler.tscn"
const ELDER_SCENE_PATH = "res://scenes/family/elder.tscn"

# Custom dummy interactable for test callback verification
class DummyInteractable extends Interactable:
	var was_executed := false
	var executor: Node3D = null
	
	func _ready() -> void:
		super._ready()
		required_class = "Toddler"
		prompt_message = "Test Hack"
		interaction_offset_x = 0.5
		
	func execute_interaction(actor: Node3D) -> void:
		was_executed = true
		executor = actor

func test_family_manager_class_filtering() -> void:
	FamilyManager.active_members.clear()
	
	var adult = load(ADULT_SCENE_PATH).instantiate()
	var toddler = load(TODDLER_SCENE_PATH).instantiate()
	var elder = load(ELDER_SCENE_PATH).instantiate()
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(adult)
		tree.root.add_child(toddler)
		tree.root.add_child(elder)
		
	adult.global_position = Vector3(0.0, 0.0, 0.0)
	toddler.global_position = Vector3(5.0, 0.0, 0.0)
	elder.global_position = Vector3(10.0, 0.0, 0.0)
	
	# Verify queries
	var found_adult = FamilyManager.get_nearest_member_of_class("Adult", Vector3(1.0, 0.0, 0.0))
	assert_eq(found_adult, adult, "Should find adult when filtering for Adult")
	
	var found_toddler = FamilyManager.get_nearest_member_of_class("Toddler", Vector3(4.0, 0.0, 0.0))
	assert_eq(found_toddler, toddler, "Should find toddler when filtering for Toddler")
	
	var found_elder = FamilyManager.get_nearest_member_of_class("Elder", Vector3(9.0, 0.0, 0.0))
	assert_eq(found_elder, elder, "Should find elder when filtering for Elder")
	
	var found_any = FamilyManager.get_nearest_member_of_class("Any", Vector3(4.0, 0.0, 0.0))
	assert_eq(found_any, toddler, "Should find nearest member regardless of class when filtering for Any")
	
	# Clean up
	if tree:
		tree.root.remove_child(adult)
		tree.root.remove_child(toddler)
		tree.root.remove_child(elder)
	adult.free()
	toddler.free()
	elder.free()

func test_interactable_registration() -> void:
	var dummy = DummyInteractable.new()
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(dummy)
		
	# Verify group registration
	var list = tree.get_nodes_in_group("interactables")
	assert_true(list.has(dummy), "Interactable should auto-register on ready")
	
	if tree:
		tree.root.remove_child(dummy)
		
	list = tree.get_nodes_in_group("interactables")
	assert_false(list.has(dummy), "Interactable should unregister on removal")
	dummy.free()

func test_family_member_interacts_upon_arrival() -> void:
	FamilyManager.active_members.clear()
	var toddler = load(TODDLER_SCENE_PATH).instantiate()
	toddler.set_meta("test_mode", true)
	var dummy = DummyInteractable.new()
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(toddler)
		tree.root.add_child(dummy)
		
	# Setup positions
	toddler.global_position = Vector3(0.0, 0.0, 0.0)
	dummy.global_position = Vector3(5.0, 0.0, 0.0)
	
	# Order to interact. Offset is 0.5, direction is 1.0 (approaching from left to right).
	# Target X = 5.0 - (1.0 * 0.5) = 4.5.
	toddler.interact_with(dummy, 1.0)
	
	assert_eq(toddler.current_state, 5, "State should transition to INTERACTING (5)")
	
	# Process ticks to simulate walking
	for i in range(100):
		toddler._physics_process(0.016)
		if dummy.was_executed:
			break
			
	assert_true(dummy.was_executed, "Interaction should be executed by actor")
	assert_eq(dummy.executor, toddler, "Executor should be the commanded toddler")
	assert_eq(toddler.current_state, 0, "Actor should return to State.FOLLOW (0) after interaction finishes")
	
	# Clean up
	if tree:
		tree.root.remove_child(toddler)
		tree.root.remove_child(dummy)
	toddler.free()
	dummy.free()
