# Phase 3 Walkthrough: Family Classes & Physics

Summarizes the changes made, verification procedures, and testing results for Phase 3.

## Changes Made

### 1. Autoload Updates
* **File**: [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* **Description**: Added `toddler_chirped` signal and `emit_toddler_chirp(origin, radius)` helper method to print and broadcast toddler squeak event coordinates.

### 2. Toddler Class
* **Files**: [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd) & [toddler.tscn](file:///d:/GameDev/hideandseek/scenes/family/toddler.tscn)
* **Description**: A fast, small cylinder follower (`speed = 4.5`, cylinder height `0.7`, radius `0.2`). When commanded to `FREEZE` or `HIDING`, starts a curiosity timer (4.0s - 8.0s). If left idle, it transitions to `WANDER` state, walking horizontally to random points and chirping periodically (emits noise circle event). Resumes following immediately upon `command_follow` whistle.

### 3. Elder Class
* **Files**: [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd) & [elder.tscn](file:///d:/GameDev/hideandseek/scenes/family/elder.tscn)
* **Description**: A slow, large cylinder follower (`speed = 2.0`, cylinder height `1.4`, radius `0.45`). Disables all jump mechanics (`jump_velocity = 0.0`). It gets blocked by obstacles and cannot cross gaps on its own.

### 4. Adult Class
* **Files**: [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd) & [adult.tscn](file:///d:/GameDev/hideandseek/scenes/family/adult.tscn)
* **Description**: A normal follower (`speed = 3.8`). When commanded, it walks dynamically to the pushing side of the crate (climbing hurdles if needed), aligns itself, and pushes it continuously. The push halts safely if the Adult reaches a ledge, a wall blocks the path, or a player command overrides the action.

### 5. Pushable Box Scene
* **File**: [pushable_box.tscn](file:///d:/GameDev/hideandseek/scenes/objects/pushable_box.tscn)
* **Description**: A 20 kg physics crate (`RigidBody3D`) with size `(1.2, 1.2, 1.2)`. Linear Z-movement and angular rotation on all axes are locked, keeping it stable and strictly on the 2.5D plane.

### 6. Player Pushing
* **File**: [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* **Description**: Added continuous horizontal pushing logic (`push_force = 600.0`) to the player character after `move_and_slide()`, allowing the player to push crates.

### 7. Test Level updates
* **File**: [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* **Description**: Replaced generic placeholders with 1x Toddler, 1x Elder, and 1x Adult. Spawned a `PushableBox` on Floor 2.

### 8. Class Unit Tests
* **File**: [test_classes.gd](file:///d:/GameDev/hideandseek/tests/test_classes.gd)
* **Description**: Evaluates Toddler's speed and curiosity wander state transitions, Elder's slow speed and zero jump velocity, and Adult's speed and push force.

---

## Verification & Test Results

### 1. Automated Tests
Executed the verification runner from the project root:
```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```

**Results**:
```
Starting Godot Headless Test Runner...
-------------------------------------
Running suite: test_classes.gd
[Toddler Toddler] Wandering off to X: -4.0
  [PASS] test_toddler_properties_and_curiosity
  [PASS] test_elder_properties
  [PASS] test_adult_properties

Running suite: test_example.gd
  [PASS] test_example_math

Running suite: test_family.gd
  [PASS] test_family_member_lifecycle_registration
[Whisper Network] Whisper. Sound radius: 2.000000 units
[Family Member FamilyMember] State transitioned to: FOLLOW
[Whisper Network] Whisper. Sound radius: 2.000000 units
[Family Member FamilyMember] State transitioned to: FREEZE
  [PASS] test_command_broadcast_updates_state
[Whisper Network] Whisper. Sound radius: 2.000000 units
[Whisper Network] SHOUT! Sound radius: 15.000000 units (Farthest member is 10.0 units away)
  [PASS] test_whisper_sound_propagation
  [PASS] test_dynamic_queue_sorting

Running suite: test_player.gd
  [PASS] test_player_scene_loads
  [PASS] test_player_instantiation_and_properties
  [PASS] test_player_z_axis_lock

=========================================
Test Summary:
Passed: 11
Failed: 0
=========================================
All tests completed successfully!
```

### 2. Manual Verification
To manually verify these behaviors in Godot:
1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Walk right:
   * Notice the speed difference: the Toddler runs fast, the Adult walks normally, the Elder walks slowly.
   * Jump over `ObstacleBox1`. The Toddler and Adult will hop over it. The Elder will walk into it and stop.
3. Command **`Q`** (Freeze) and stand still:
   * After 5 seconds, the Toddler will exit the freeze line, wander around randomly, and output `[Whisper Network] Toddler Chirp!` console log alerts.
   * Press **`E`** (Follow) to call the Toddler back to the queue line.
4. Walk across the pit to Floor 2:
   * The Toddler and Adult will jump across.
   * The Elder will fall into the gap (unable to jump). This is expected and forms the level puzzle basis.
5. Push the `PushableBox`:
   * Control the Player or lead the Adult to collide with the crate. You will see the Adult push it horizontally.
