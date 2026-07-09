# Phase 4: Cover Zones & Chain Hiding - Implementation Plan

Implement the core cover and stealth mechanics where companions search for, assign, and navigate to physical cover zones of varying capacities and sizes when ordered to "Freeze & Hide".

## Proposed Changes

### A. Cover Zone Component
#### [NEW] [cover_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/cover_zone.gd)
* Extends `Area3D`.
* Registers automatically in the `"cover_zones"` group.
* Properties:
  * `@export_enum("Small", "Medium", "Large") var zone_size: String = "Medium"`
  * `@export var capacity: int = 1`
* Maintains a list of currently assigned actors.
* Methods:
  * `has_space_for(actor_size: String) -> bool`: Checks if the zone has slots remaining and is of a compatible size class (Toddler fits Small/Medium/Large; Adult/Elder only fit Large).
  * `get_slot_x(actor: Node3D) -> float`: Returns the horizontally distributed X coordinate slot within the zone shape.
  * `assign_actor(actor: Node3D) -> float`: Assigns slot index and returns the X coordinate.
  * `release_actor(actor: Node3D) -> void`: Frees the actor's slot.

### B. Companion Cover Searching & Navigation
#### [MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
* Add `State.HIDING` state.
* Add properties:
  * `var is_hidden: bool = false`
  * `var _assigned_cover: Area3D = null`
  * `var _cover_target_x: float = 0.0`
* Update `_on_command_broadcast(new_state_int)`:
  * When `State.FREEZE` is commanded:
    * Search for the nearest valid `CoverZone` using the global `"cover_zones"` group.
    * If a zone is found, reserve a slot, transition to `State.HIDING`, and walk to `_cover_target_x`.
    * If no zone is found, stop in place (normal freeze/exposed behavior).
  * When `State.FOLLOW` is commanded:
    * If assigned to a cover zone, release the slot.
    * Set `is_hidden = false`, `_assigned_cover = null`.
* Update `_physics_process(delta)`:
  * In `State.HIDING`, walk horizontally towards `_cover_target_x`. Once arrived:
    * Set `velocity.x = 0.0`
    * Set `is_hidden = true`
    * Optionally apply a visual cue (fade alpha or scale down slightly) to indicate cover.

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
* Override size class identifier as `"Small"`.
* If curiosity kicks in while hiding, the Toddler should NOT wander off if they are successfully hidden in a cover zone, or their wandering should reveal them!

#### [MODIFY] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd) & [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
* Override size class identifier as `"Large"`.

### C. Level Cover Setup
#### [MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* Instantiate 3 cover zones:
  * **CoverZoneSmall** (Vent entrance/shadow): Placed on Floor 1.
  * **CoverZoneLarge** (Industrial pipes/crates): Placed on Floor 1.
  * **CoverZoneMedium** (Debris/panels): Placed on Floor 2.

---

## Verification Plan

### Automated Tests
Create **[test_cover.gd](file:///d:/GameDev/hideandseek/tests/test_cover.gd)**:
* `test_cover_zone_compatibility`: Verify size restrictions (Toddler fits Small; Elder/Adult reject Small/Medium).
* `test_cover_capacity_exhaustion`: Verify that when capacity is reached, subsequent actors are rejected and remain exposed.
* `test_cover_navigation_flow`: Command Freeze & Hide, tick physics, and verify that the companion reaches the cover slot and sets `is_hidden = true`.

### Manual Verification
1. Run `level_test.tscn`.
2. Move the family near the cover zones and press **`Q`** (Freeze & Hide).
3. Verify that the Toddler runs to the small cover zone, the Adult/Elder run to the large cover zone, and any extra/unassigned companions freeze exposed in the corridor.
4. Press **`E`** (Follow) to confirm they exit cover and rejoin the line.
