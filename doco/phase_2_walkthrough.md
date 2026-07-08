# Phase 2 Walkthrough: Family Queue & Whisper Network

Summarizes the changes made, verification procedures, and testing results for Phase 2.

## Changes Made

### 1. Custom Input Configuration
* **File**: [project.godot](file:///d:/GameDev/hideandseek/project.godot)
* **Description**: Added input actions:
  * `command_follow` mapped to **`E`** (calls the family to follow).
  * `command_freeze` mapped to **`Q`** (tells the family to freeze and hide).
  * Registered `FamilyManager` as a global Autoload script.

### 2. Central Escort Autoload
* **File**: [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* **Description**: Maintains a list of active family members in the scene and registers player node instances. Broadcasts follow/freeze commands and computes command sound projection (whisper vs. shout) based on the player's physical distance to the farthest trailing member.

### 3. Family Member Base Script and Scene
* **Files**: [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd) & [family_member.tscn](file:///d:/GameDev/hideandseek/scenes/family/family_member.tscn)
* **Description**: Base escort entity. It registers itself with `FamilyManager` on entering the scene. When in `FOLLOW` state, it calculates its index, fetches the corresponding historical path coordinate of the player, and moves toward it. Restricts movement to the 2.5D X-axis plane. It uses a Cylinder mesh to visually differentiate it from the player's Capsule mesh.

### 4. Player Updates
* **File**: [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* **Description**: Registers itself with `FamilyManager` on start. Maintains a historical coordinate queue (`_path_history`) prepending new coordinates when moving past a threshold (0.08 units). Listens to `command_follow` and `command_freeze` inputs to broadcast commands.

### 5. Level Setup
* **File**: [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* **Description**: Instantiates two family members placed slightly to the left of the player.

### 6. Automated Unit Tests
* **File**: [test_family.gd](file:///d:/GameDev/hideandseek/tests/test_family.gd)
* **Description**: Tests the member registration lifecycle, command state broadcast transitions, and proximity-based whisper sound radius calculations.

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

Running suite: test_player.gd
  [PASS] test_player_scene_loads
  [PASS] test_player_instantiation_and_properties
  [PASS] test_player_z_axis_lock

=========================================
Test Summary:
Passed: 7
Failed: 0
=========================================
All tests completed successfully!
```

### 2. Manual Verification
To manually test the queue following and command system in Godot:
1. Open the project in Godot 4.6.3 and run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Press **`E`**: You will see console output logs noting state transitions to `FOLLOW`.
3. Walk forward (WASD/Arrows): The two cylinder family members will walk behind you in a neat line, tracing your exact path (including jumping when you jump).
4. Press **`Q`**: The family members will slide to a halt and enter the `FREEZE` state.
5. Move far away from the family members and press **`E`** or **`Q`**: Look at the console logs to verify that the sound propagation is logged as `SHOUT` due to the distance, representing a larger noise circle.
