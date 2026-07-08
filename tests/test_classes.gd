# tests/test_classes.gd
extends BaseTest

const TODDLER_SCENE_PATH = "res://scenes/family/toddler.tscn"
const ELDER_SCENE_PATH = "res://scenes/family/elder.tscn"
const ADULT_SCENE_PATH = "res://scenes/family/adult.tscn"

func test_toddler_properties_and_curiosity() -> void:
	FamilyManager.active_members.clear()
	
	var toddler_scene = load(TODDLER_SCENE_PATH)
	assert_true(toddler_scene != null, "Toddler scene should load")
	
	var toddler = toddler_scene.instantiate() as Toddler
	assert_true(toddler != null, "Toddler should instantiate")
	
	# Verify specific properties
	assert_eq(toddler.speed, 4.5, "Toddler speed should be 4.5")
	assert_eq(toddler.spacing_steps, 10, "Toddler spacing steps should be 10")
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(toddler)
		
	# Put in FREEZE state (1)
	toddler.current_state = 1 # State.FREEZE
	toddler.curiosity_cooldown = 2.0 # short cooldown for test
	toddler._reset_curiosity_timer()
	
	# Manually run physics step of 3 seconds to exceed cooldown
	toddler._physics_process(3.0)
	
	# State should transition to WANDER (3)
	assert_eq(toddler.current_state, 3, "Toddler should transition to WANDER state (3) after cooldown")
	
	if tree:
		tree.root.remove_child(toddler)
	toddler.free()

func test_elder_properties() -> void:
	FamilyManager.active_members.clear()
	
	var elder_scene = load(ELDER_SCENE_PATH)
	assert_true(elder_scene != null, "Elder scene should load")
	
	var elder = elder_scene.instantiate() as Elder
	assert_true(elder != null, "Elder should instantiate")
	
	# Verify elder speed is slower and spacing is wider
	assert_eq(elder.speed, 2.0, "Elder speed should be 2.0")
	assert_eq(elder.spacing_steps, 22, "Elder spacing steps should be 22")
	assert_eq(elder.jump_velocity, 0.0, "Elder jump velocity should be 0.0 (disabled)")
	
	elder.free()

func test_adult_properties() -> void:
	FamilyManager.active_members.clear()
	
	var adult_scene = load(ADULT_SCENE_PATH)
	assert_true(adult_scene != null, "Adult scene should load")
	
	var adult = adult_scene.instantiate() as Adult
	assert_true(adult != null, "Adult should instantiate")
	
	# Verify adult parameters
	assert_eq(adult.speed, 3.8, "Adult speed should be 3.8")
	assert_eq(adult.push_speed, 1.8, "Adult push speed should be 1.8")
	assert_true(adult.is_adult_class(), "Adult should identify as Adult class")
	
	adult.free()
