# Phase 3.1 Walkthrough - Modular Interaction Framework

This document details the design, files modified, and verification results for the modular actor-target companion interaction framework and the co-op level progression mechanics.

## 1. Summary of Changes

### A. Core Component Scripts
* **[NEW] [interactable.gd](file:///d:/GameDev/hideandseek/scenes/objects/interactable.gd)**: Extends `Area3D` and serves as a decoupled component. Specifies a required actor class (`required_class`) and provides a virtual `execute_interaction(actor)` callback. Uses a global node group `"interactables"` for O(1) scanning.
* **[NEW] [pushable_box_interactable.gd](file:///d:/GameDev/hideandseek/scenes/objects/pushable_box_interactable.gd)**: Extends `Interactable` to bridge crates with the new framework. On interaction, it commands the Adult companion to push the parent crate.
* **[NEW] [bridge_gate.gd](file:///d:/GameDev/hideandseek/scenes/objects/bridge_gate.gd)**: Manages a retractable puzzle bridge node placed in the gap between Floor 1 and Floor 2. It starts lowered with disabled collisions and raises smoothly into position when activated.
* **[NEW] [terminal_interactable.gd](file:///d:/GameDev/hideandseek/scenes/objects/terminal_interactable.gd)**: Extends `Interactable` to generic terminal switches. Directs actors to hack bridge gates to raise them, or buttons to lower blocking obstacles.

### B. Companion Refactoring & Walk Navigation
* **[MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)**:
  * Implemented generic subclass checks: `is_toddler_class()`, `is_elder_class()`.
  * Added `State.INTERACTING` state.
  * Implemented a generalized horizontal walk navigation method (`interact_with`). This method reuses our robust locked-trajectory physics (jumping over hurdles when needed, preventing mid-air direction switching, and avoiding getting stuck on top of boxes).
  * Automatically fires `execute_interaction()` on target when grounded and aligned or overlapping the Area3D trigger.
* **[MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)**:
  * Removed all horizontal alignment walking code. The Adult now inherits walking alignment from `FamilyMember` during the `INTERACTING` phase.
  * Once aligned, `PushableBoxInteractable` triggers the transition to `State.PUSHING`, where `adult.gd` manages only the active box-pushing phase.
* **[MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)** & **[elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)**: Added subclass type-checking query method overrides.

### C. Player Director Scan
* **[MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)**:
  * Replaced the specific `_try_interact_push()` logic with a generalized `_try_interact()`.
  * Scans for adjacent `Interactable` Area3Ds in group `"interactables"`.
  * Filters the escort line for the nearest companion of the required class, and triggers `actor.interact_with(target, direction)`.

### D. Level Assembly
* **[MODIFY] [pushable_box.tscn](file:///d:/GameDev/hideandseek/scenes/objects/pushable_box.tscn)**: Added a child `Area3D` node labeled `InteractableArea` with the `pushable_box_interactable.gd` script and a `2.0` meter wide collision shape.
* **[MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)**:
  * Added a lowered **BridgeGate** in the central gap.
  * Added an **ObstacleConsole** at `X = -9.0` (requires a Toddler to retract the blocking obstacle).
  * Added a **BridgeConsole** at `X = -3.0` (requires the Elder to hack and raise the bridge gate across the gap).

### E. Visual Companion Passing & Pushing Rules
* **Companion Z-Depth Passing Offsets**: Modified the Z-depth positioning in [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd). When two companions are close to each other horizontally, they check their relative line order: the one further back in the escort queue steps into the background (Z = -0.6) and the one further forward steps into the foreground (Z = 0.6). This allows them to pass each other cleanly without overlapping.
* **Adult Obstacle Jump Refinement**: Updated the jumping logic in [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd). The Adult companion now treats the pushable box as a normal physical obstacle and jumps over it when they are simply following the player. They only skip jumping if they are actively in the `PUSHING` or `INTERACTING` state to push the box.

---

## 2. Test Verification Results

### Automated Unit Tests
The test suite **[test_interaction.gd](file:///d:/GameDev/hideandseek/tests/test_interaction.gd)** verifies manager queries, group registrations, walk-alignment-to-trigger execution, and terminal interaction mechanics. All **15 tests** compiled and executed successfully:

```
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

=========================================
Starting Godot Headless Test Runner...
=========================================

Running suite: test_classes.gd
[Toddler Toddler] Wandering off to X: -3.2
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

Running suite: test_interaction.gd
  [PASS] test_family_manager_class_filtering
  [PASS] test_interactable_registration
[Family Member Toddler] Ordered to interact with @Area3D@5 in direction 1.0
  [PASS] test_family_member_interacts_upon_arrival
[Terminal] Terminal activated by actor: @Area3D@6
[BridgeGate] Bridge activated and raised successfully!
[Terminal] Obstacle retracted into floor!
  [PASS] test_terminal_interaction_mechanics

Running suite: test_player.gd
  [PASS] test_player_scene_loads
  [PASS] test_player_instantiation_and_properties
  [PASS] test_player_z_axis_lock

=========================================
Test Summary:
Passed: 15
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
2. Walk right with your queue. Notice the Elder gets blocked by the first hurdle (`ObstacleBox1`).
3. Walk to the console at `X = -9.0` and press **`F`**.
4. The Player commands the **Toddler** to walk to the console and press it. Watch the Toddler walk to the console, press it, and watch the hurdle lower into the floor, allowing the Elder to follow again!
5. Walk towards the pit. The Elder lags behind and stops at the edge of the pit (unable to jump).
6. Walk to the security console at `X = -3.0` and press **`F`**.
7. The Player commands the **Elder** to hack the bridge console. Watch the Elder walk to the console, execute the hack, and watch the bridge gate rise out of the pit to form a solid bridge!
8. Call the family back to follow you (**`E`**) and walk across the raised bridge platform. The Elder will walk safely across to Floor 2!
9. Command the **Adult** to push the crate at `X = 6.0` to verify pushing mechanics work.
