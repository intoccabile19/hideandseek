# Phase 6.5 Refinements Implementation Plan

This plan details the implementation of double-sided stairs for the pushable box and the stabilization of hiding coordinates when commands are repeated.

## Proposed Changes

### 1. Pushable Box as a Double-Sided Staircase
To allow the Elder and other companions to walk up and over the box to clear obstructions, the `PushableBox` rigid body will be restructured into a double-sided staircase layout with 5 steps ascending to the center on each side.
* **[MODIFY] [pushable_box.tscn](file:///d:/GameDev/hideandseek/scenes/objects/pushable_box.tscn)**:
  * Remove the single large box collision shape and box mesh.
  * Define 9 smaller step collision shapes and matching mesh blocks (1 center, 4 on the left, 4 on the right).
  * Outermost steps are `0.24m` high to make them easily step-traversable by any character.

### 2. Stabilization of Hiding Coordinates
To prevent companions from jumping out of hiding and shuffling around when the player repeats the hide command:
* **[MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)**:
  * Update `assign_hiding_covers()` to preserve cover assignments for companions who are already in the `HIDING` or `FREEZE` state.
* **[MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)**:
  * Update `_on_command_broadcast()` to ignore redundant `State.FREEZE` (Hide) commands if the companion is already in the `HIDING` or `FREEZE` state.

---

## Verification Plan

### Automated Tests
* Create `tests/test_phase_6_5_refinements.gd` verifying:
  * Repeated freeze commands do not change the companion's cover assignment.
  * Hiding state remains stable when the freeze command is broadcast multiple times.

### Manual Verification
* Run the game and command companions to hide twice. Verify they stay in place.
* Push the box against the wall in the test level and observe the Elder walking up and over the obstruction.
