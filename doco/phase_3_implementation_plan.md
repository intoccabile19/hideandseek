# Phase 3: Family Classes & Physics

Implement specialized subclasses for the three family member types (Toddler, Elder, Adult) to introduce distinct mechanical behaviors, physical constraints, and physics interactions like pushing crates.

## User Review Required

> [!IMPORTANT]
> This phase establishes the core physical puzzle dynamics:
> * **The Toddler**: High speed, wanders off and chirps (making noise) if left idle.
> * **The Elder**: Low speed, completely disabled jumping (gets blocked by boxes, falls in gaps).
> * **The Adult**: Standard speed, capable of pushing physics crates (`RigidBody3D`) to fill gaps or build ramps.

---

## Proposed Changes

### Scripts & Subclasses

#### [NEW] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
* Inherits from `FamilyMember`.
* Overrides defaults: `speed = 4.5`, `spacing_steps = 10` (follows closer).
* Implements a `curiosity_timer`. When the state transitions to `FREEZE` or `HIDING`, start a random countdown (e.g., 4.0 to 8.0 seconds).
* On timeout, if still idle, enter `WANDER` state, pick a nearby X coordinate, and move towards it.
* Periodically emits a chirp sound circle using a new helper method on `FamilyManager`.

#### [NEW] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)
* Inherits from `FamilyMember`.
* Overrides defaults: `speed = 2.0`, `spacing_steps = 22` (trails further back).
* Overrides jump logic: completely disables jumping (`jump_velocity = 0.0`, returns `false` on jump triggers).

#### [NEW] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
* Inherits from `FamilyMember`.
* Overrides defaults: `speed = 3.8`.
* Implements a push force check in `_physics_process`. When colliding with a `RigidBody3D`, applies a central impulse to push the box horizontally.

### Scenes

#### [NEW] [toddler.tscn](file:///d:/GameDev/hideandseek/scenes/family/toddler.tscn)
* Inherits from [family_member.tscn](file:///d:/GameDev/hideandseek/scenes/family/family_member.tscn).
* Visual mesh scale set smaller (cylinder height = 0.7, radius = 0.2).

#### [NEW] [elder.tscn](file:///d:/GameDev/hideandseek/scenes/family/elder.tscn)
* Inherits from [family_member.tscn](file:///d:/GameDev/hideandseek/scenes/family/family_member.tscn).
* Visual mesh scale set larger and wider (cylinder height = 1.4, radius = 0.45).

#### [NEW] [adult.tscn](file:///d:/GameDev/hideandseek/scenes/family/adult.tscn)
* Inherits from [family_member.tscn](file:///d:/GameDev/hideandseek/scenes/family/family_member.tscn).
* Uses standard size mesh but with a distinct color or secondary visual marker to identify it.

### Physics Objects

#### [NEW] [pushable_box.tscn](file:///d:/GameDev/hideandseek/scenes/objects/pushable_box.tscn)
* A `RigidBody3D` node with a `CollisionShape3D` (box shape) and `MeshInstance3D` (cube mesh).
* Configured with moderate mass (e.g., 20 kg) and locked rotation on Y and Z axes to keep it stable when pushed on the 2.5D plane.
* Set on Layer 1 (World) so it collides with floors and characters.

### Autoload Updates

#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* Add a `emit_toddler_chirp(origin: Vector3, radius: float)` helper method to signal toddler noise events (which will propagate sound circles).

### Level Setup

#### [MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* Replace the generic family members with:
  * 1x Toddler
  * 1x Elder
  * 1x Adult
* Add a `pushable_box.tscn` next to the Adult to verify box-pushing physics.

### Tests

#### [NEW] [test_classes.gd](file:///d:/GameDev/hideandseek/tests/test_classes.gd)
* Verifies:
  * Elder cannot jump and moves slower.
  * Toddler moves faster and triggers its curiosity timer when freezing.
  * Adult handles rigid body collisions and applies push forces.

---

## Verification Plan

### Automated Tests
* Run the verification suite:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
  ```
  Ensure all tests in `tests/test_classes.gd` pass.

### Manual Verification
1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Move right: Observe the Toddler runs fast and keeps up easily, the Adult moves at normal speed, and the Elder walks slowly and lags behind.
3. Jump over the first box: The Toddler and Adult will hop over it cleanly. The Elder will walk into the box and stop (unable to jump).
4. Command **`Q`** (Freeze): Stand still. After 5 seconds, observe the Toddler wanders off to the left/right and emits a debug chirp console message.
5. Control the Player to push the box, or lead the Adult to collide with the box: Verify that the Adult pushes the box horizontally.
