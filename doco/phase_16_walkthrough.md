# Level 2 Vent Exit Paths & Ledge Launcher Fix Walkthrough

Fixed the misconfigured `connected_exit_path` properties on Level 2 vents, hid the Toddler's visibility during vent crawls, and implemented targeted flat trajectory throws for the Ledge Launcher with automatic post-landing interaction triggers.

## Changes Made

### Level 2 Cargo Hold Scene

#### [MODIFY] [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)
- Swapped vent `connected_exit_path` assignments to correctly link ground floor and upper floor vents.
- Added a `LandingTarget` (Node3D marker) child to `TestLedgeLauncher` and mapped it to the new `landing_target` property so that the throw trajectory targets it directly.
- Mapped the new `post_landing_interactable` property on `TestLedgeLauncher` to `TestElevatorButton2` to instruct the Toddler to interact with it upon landing.
- Set the first `TestElevatorButton`'s `required_class` specifically to `"Toddler"` so that only the Toddler can interact with it to raise/lower the elevator.
- Expanded the Seeker's `wander_range_x` to `Vector2(-32, 20)` to ensure it patrols the entire width of Level 2, bringing it close enough to hear players on the left side.

### Seeker Class

#### [MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)
- Implemented multi-point raycasting in both `_check_vision()` and `_process_chase()`. The Seeker now casts three rays (targeting the feet, chest, and head) rather than a single ray to the chest. This prevents the Seeker from being blind to characters standing behind window frames or half-height obstacles.
- Changed the spotlight rotation pitch (X-axis) from a static downward angle to a dynamic vertical sweep (modulating between `-5` and `-35` degrees using a sine wave) during `WANDER`, `SCANNING`, and `SUSPICIOUS` LOOKING states. This ensures the spotlight cone continuously sweeps both the ground floor and the second floor pathways.

#### [MODIFY] [ledge_launcher.gd](file:///d:/GameDev/hideandseek/scenes/objects/ledge_launcher.gd)
- Added exported `@export var landing_target: Node3D` and `@export var post_landing_interactable: Interactable` properties.

### Elevator Button

#### [MODIFY] [elevator_button.gd](file:///d:/GameDev/hideandseek/scenes/objects/elevator_button.gd)
- Removed overriding the `required_class` property in `_ready()`, preserving whatever values are set in the inspector (like `"Toddler"`).

### Adult Class

#### [MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
- Modified `try_launch_toddler()` to look for `landing_target` and `post_landing_interactable` on the launcher point.
- If a target is present, it calculates the exact horizontal and vertical initial velocity required to land the Toddler directly on the target coordinates.
- Set the horizontal throw speed to `12.0` m/s to create a flat, fast throw arc.
- Automatically copies `post_landing_interactable` to the Toddler's `post_launch_interact_target` and sets `post_launch_stop_after_interact = true`.

### Toddler Class

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
- Set `visible = false` inside `crawl_through_vent()` to hide the Toddler and label during vent crawl.
- Set `visible = true` in `_physics_process()` when they exit.
- Changed the vent crawl completion distance check to use a 2D distance calculation (X and Y coordinates only). This ensures the Toddler successfully exits the vent and reappears even if the vent exit node contains a slight Z-axis coordinate offset.

### Family Member Base Class

#### [MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
- Reordered `State.LAUNCHED` physics in `_physics_process()` to apply gravity and `move_and_slide()` *before* checking the `is_on_floor()` state to fix the stale collision bug.
- Added a `velocity.y <= 0.0` check to prevent landing while the Toddler is rising.
- Upon landing on the floor from a launch, automatically triggers `execute_interaction()` on the queued `post_launch_interact_target` directly, and sets `current_state = State.STOP` (waiting state) if `post_launch_stop_after_interact` is true, avoiding the need for the Toddler to walk or navigate to the button.

### Family Manager Class

#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
- Commented out the `print` statements in `_calculate_sound_propagation()` showing Whisper/Shout radius to clean up console outputs.

### Interactable Base Class

#### [MODIFY] [interactable.gd](file:///d:/GameDev/hideandseek/scenes/objects/interactable.gd)
- Added `collision_mask |= 1 | 4` in `_ready()` to ensure all interactable triggers automatically detect both the Player (Layer 1) and Family Members / Toddler (Layer 4).

## Verification Results

### Automated Tests
Ran the full test suite and confirmed all 41 test scenarios passed:
```
=========================================
[SUCCESS] All tests and validations passed!
=========================================
```
