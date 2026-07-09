# Phase 4 Walkthrough - Cover Zones & Chain Hiding

This document details the design, files modified, and verification results for the Cover Zones & Chain Hiding mechanics.

## 1. Summary of Changes

### A. Cover Zone Component
* **[NEW] [cover_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/cover_zone.gd)**: 
  * Extends `Area3D` and registers in `"cover_zones"` group.
  * **Physics Layer Insulation**: Set to `collision_layer = 8` and `collision_mask = 1` in `_ready()`. This isolates it completely from standard physical bodies and raycasts at Layer 1 (World), preventing the pushable box from stopping or colliding with it.
  * **Dynamic Slot Allocations**: Implemented `get_slot_x(actor: Node3D) -> float` to distribute slot coordinates horizontally based on the *current* count of assigned actors. If one companion hides, they occupy the center; if a second companion joins, they dynamically split to prevent overlapping.

### B. Companion Cover Searching & Navigation
* **[MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)**:
  * Added `State.HIDING` state.
  * Added properties `is_hidden`, `_assigned_cover`, and `_cover_target_x`.
  * Implemented `get_size_class() -> String` which returns `"Medium"` by default.
  * Modified `_on_command_broadcast(new_state_int)`:
    * When `State.FREEZE` (Freeze & Hide) is received, companions transition to `State.HIDING` using the cover zone and slot X centrally assigned to them by the `FamilyManager`'s coordinated matchmaking system.
    * **Coordinated central cover assignment**: When Freeze is broadcast, the `FamilyManager` coordinates assignment by sorting companions by size class restrictiveness (`Large` (Adult) -> `Medium` (Elder) -> `Small` (Toddler)). Larger members are matched first to ensure they get slots in Large cover zones, while smaller members (who have more choices) pick from the remaining slots. Tie-breaks are resolved by choosing the closest compatible zone.
    * **Standalone fallback**: Standalone unit tests bypass the coordinator and use an individual fallback search within the companion script to ensure test compatibility.
    * When `State.FOLLOW` is received, they release their cover slots and return to follow mode.
  * Modified `_physics_process(delta)`:
    * In `State.HIDING`, they navigate horizontally to their assigned slot X coordinate (queried dynamically every frame from the cover zone via `get_slot_x`), using obstacle jump navigation to traverse steps. Once within `0.15` meters of their slot, they stop and set `is_hidden = true`.
    * **Safe Z-Depth Walk Transit**: Hiding characters walk along the main walkway ($Z = 0.0$) while moving horizontally. They only slide back to their cover zone's background Z position ($Z = -1.2$) once they are within `0.3` meters of their slot X position, preventing them from falling off the floor during transit.
    * Added **Elder Gap Halting Safeguard**: During follow movement, if a companion cannot jump (`jump_velocity <= 0.0` like the Elder) and detects a pit ahead via the scan raycast, they immediately override their horizontal velocity to `0.0` and halt at the edge.
    * Implemented **Cumulative Follow Spacing**: Refactored follow path history indexing to be cumulative. Instead of target steps being `(follow_index + 1) * spacing_steps`, the index is the sum of the spacing steps of all preceding companions in the queue. This prevents crowding and overlapping (e.g. Toddler and Adult stood too close or behind each other).
    * **Fallback Jump Jitter Filter**: The fallback jump check (`not is_on_floor() and _was_on_floor_last_frame`) now casts a raycast straight down. If the floor is still within `1.2` meters, the jump is ignored as a physics boundary jitter, preventing the Adult from jumping when separating from the pushable box.
* **[MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)**:
  * Overrides `get_size_class() -> String: return "Small"`.
  * Curiosity wandering is automatically suspended while successfully hidden in a cover zone to prevent them from exposing themselves.
  * Tuned local spacing to `8` steps.
* **[MODIFY] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)**:
  * Overrides `get_size_class() -> String: return "Medium"`.
  * Tuned local spacing to `16` steps.
* **[MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)**:
  * Overrides `get_size_class() -> String: return "Large"`.
  * Tuned local spacing to `12` steps.
  * **Box Pushing Raycast**: Replaced the Adult's wall collision check with a front-of-box raycast check (pointing `0.7` meters in front of the box). If it intersects a static wall (Layer 1), the Adult stops pushing, resolving the issue where they pushed indefinitely against walls.

### C. Level Cover Setup
* **[MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)**:
  * Placed **CoverZoneSmall** (Vent shadow) at `X = -10.0, Z = -1.2` with capacity `1`.
  * Placed **CoverZoneLarge** (Industrial pipes) at `X = -4.0, Z = -1.2` with capacity `2`.
  * Placed **CoverZoneMedium** (Cargo panels) at `X = 8.0, Z = -1.2` with capacity `2`.
  * The cover zone nodes and visual meshes are placed at $Z = -1.2$ in the background. Hiding companions automatically align to their assigned zone's depth, smoothly stepping back into the background when hidden to ensure visibility remains clear on the main path.
  * **Thin Background Cover Zones**: Adjusted the Z-axis dimensions of all cover zones to a thin shape thickness of `0.8` meters and mesh thickness of `0.1` meters. This moves them completely out of the main path, preventing the box-pushing Adult from colliding with them at $Z = 0.0$.

### D. Test Runner Timeout
* **[MODIFY] [run_tests.ps1](file:///d:/GameDev/hideandseek/run_tests.ps1)**: Added a 5-second process timeout wrapper (`Wait-Process -Timeout 5`). If a test suite hangs or fails to exit, the runner terminates immediately and exits, avoiding blocking the development workflow.

---

## 2. Test Verification Results

### Automated Unit Tests
A new test suite **[test_cover.gd](file:///d:/GameDev/hideandseek/tests/test_cover.gd)** was created to verify size compatibility constraints, slot exhaustion rules, and cover navigation. All **18 tests** compiled and executed successfully:

```
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

=========================================
Starting Godot Headless Test Runner...
=========================================

Running suite: test_classes.gd
[Toddler Toddler] Wandering off to X: 2.5
  [PASS] test_toddler_properties_and_curiosity
  [PASS] test_elder_properties
  [PASS] test_adult_properties

Running suite: test_cover.gd
  [PASS] test_cover_zone_compatibility
  [PASS] test_cover_capacity_exhaustion
[Family Member @CharacterBody3D@3] State transitioned to: FREEZE
[Family Member @CharacterBody3D@3] Heading to cover at X: 5.00
[Family Member @CharacterBody3D@3] State transitioned to: FOLLOW
  [PASS] test_cover_navigation_flow

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

Running suite: test_interaction.gd
  [PASS] test_family_manager_class_filtering
  [PASS] test_interactable_registration
[Family Member Toddler] Ordered to interact with @Area3D@8 in direction 1.0
  [PASS] test_family_member_interacts_upon_arrival
[Terminal] Terminal activated by actor: @Area3D@9
[BridgeGate] Bridge raising initiated...
[RetractingObstacle] Retraction initiated...
  [PASS] test_terminal_interaction_mechanics

Running suite: test_player.gd
  [PASS] test_player_scene_loads
  [PASS] test_player_instantiation_and_properties
  [PASS] test_player_z_axis_lock

=========================================
Test Summary:
Passed: 18
Failed: 0
=========================================
All tests completed successfully!

=========================================
[SUCCESS] All tests and validations passed!
=========================================
```

---

## 3. Manual Verification Steps

1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Lead your family members right and stop near the pipes (around `X = -5.0`).
3. Press **`Q`** (Freeze & Hide command).
4. Watch the companions assign themselves to cover zones:
   * The **Toddler** runs left to **CoverZoneSmall** at `X = -10.0`.
   * The **Adult** and **Elder** walk to the closest large cover zone at **CoverZoneLarge** (`X = -4.0`), splitting into clean horizontal slots inside the zone.
5. Press **`E`** (Follow command) to confirm that they exit cover, release their slots, and rejoin the follow queue.
