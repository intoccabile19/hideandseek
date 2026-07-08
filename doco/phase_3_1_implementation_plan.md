# Phase 3.1: Modular Interaction Framework

Introduce a decoupled component-based Interaction system allowing the Player to scan puzzle objects and direct specific family members (Adult, Toddler, Elder) to interact with them based on class capability.

## User Review Required

> [!IMPORTANT]
> This phase establishes a flexible, modular event framework:
> * **`Interactable` (Area3D Component)**: Can be attached to any level object (box, door terminal, vent, lever).
> * **Directing Commands**: Player presses **`F`** to scan for adjacent `Interactable` nodes, checks the class constraint (e.g., requires "Toddler"), finds the nearest candidate companion, and orders them to interact.
> * **Unified Companion Navigation**: Base `FamilyMember` class handles the alignment path walk (with locked-trajectory physics and jump avoidance), then calls the object's interaction script.

---

## Proposed Changes

### Scripts & Component Base

#### [NEW] [interactable.gd](file:///d:/GameDev/hideandseek/scenes/objects/interactable.gd)
* Inherits from `Area3D`.
* Defines properties:
  * `@export var required_class: String = "Any"` (choices: "Adult", "Toddler", "Elder", "Any").
  * `@export var prompt_message: String = "Interact"`.
  * `@export var interaction_offset_x: float = 0.8` (distance horizontal offset the actor should align to).
* Defines virtual method:
  * `func execute_interaction(actor: Node3D) -> void` (called when companion reaches target).

### Autoload Updates

#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* Implement `get_nearest_member_of_class(required_class: String, pos: Vector3) -> Node3D`.
* Supports filtering registered companions by their custom class identifiers.

### Base Companion Updates

#### [MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
* Register state-checking helpers:
  * `func is_toddler_class() -> bool: return false`
  * `func is_elder_class() -> bool: return false`
* Add `State.INTERACTING` to the `State` enum.
* Implement generic `interact_with(target: Interactable)`:
  * Transitions node to `State.INTERACTING`.
  * Walk-navigates towards target alignment spot (uses physics trajectory locks).
  * Calls `target.execute_interaction(self)` upon arrival, then returns to follow queue.

### Class Subclass Refactoring

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
* Override `is_toddler_class() -> bool: return true`.

#### [MODIFY] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)
* Override `is_elder_class() -> bool: return true`.

#### [MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
* Remove coordinate alignment logic from `adult.gd`'s `_physics_process()`.
* The Adult now only manages the active `PUSHING` state phase itself. The initial walking-alignment is fully inherited from the parent class `INTERACTING` phase.

### Player Interaction

#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* Update `_try_interact_push()` to generalized `_try_interact()`:
  * Scans for adjacent `Interactable` nodes.
  * Queries target class constraint.
  * Fetches the nearest candidate actor from the manager and commands it.

### Refactored Objects

#### [MODIFY] [pushable_box.tscn](file:///d:/GameDev/hideandseek/scenes/objects/pushable_box.tscn)
* Add a child `Area3D` node with `interactable.gd` component.
* Set property constraints:
  * `required_class = "Adult"`
  * `prompt_message = "Push Crate"`
  * `interaction_offset_x = 0.8`

### Tests

#### [NEW] [test_interaction.gd](file:///d:/GameDev/hideandseek/tests/test_interaction.gd)
* Verifies:
  * `FamilyManager` correctly filters members of a class.
  * `Interactable` component triggers commands.
  * Actor walks to alignment offset and runs execute callback.

---

## Verification Plan

### Automated Tests
* Run the verification suite:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
  ```
  Ensure all tests in `tests/test_interaction.gd` pass.

### Manual Verification
1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Walk up to the crate on Floor 2 and press **`F`**.
3. Observe that the Adult companion is commanded, walks up to the box, and pushes it horizontally to the edge of the pit.
