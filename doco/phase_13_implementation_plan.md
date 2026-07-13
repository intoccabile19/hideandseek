# Phase 13 Implementation Plan: Seeker Look Spots and Volumetric Godbeams

This plan details how we will implement Predefined Look Spots for Seeker robots to investigate wall openings/windows, hide the old vision cone meshes, and enable volumetric fog programmatically to render realistic godbeams that are physically blocked by walls.

## Proposed Changes

### [Seeker Component]

#### [MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)
* **Predefined Look Spot Searching**:
  * Declare `var _assigned_look_spot: Marker3D = null`.
  * Add a helper method `_find_all_look_spots() -> Array[Marker3D]` that programmatically scans the scene for any `Marker3D` node whose name starts with `"SeekerLookSpot"` or has the `"seeker_look_spots"` group.
  * In `_on_sound_heard()`, if the Seeker goes to High Alert (`alert_level >= 0.5`), scan for the closest unoccupied look spot near the sound origin. If one is found, reserve it (`_assigned_look_spot = spot`) and set `_target_pos` to its position.
  * In `_process_suspicious()`, if looking at the wall and `_assigned_look_spot` is valid, align the Seeker's rotation (`rotation.y`) to face the rotation of the look spot (`_assigned_look_spot.global_rotation.y`).
  * Release the reserved look spot (`_assigned_look_spot = null`) when transitioning back to WANDER, SCANNING, CHASE, or CAPTURE.
* **Volumetric Fog & Godbeams**:
  * In `_ready()`, programmatically locate the active scene's `WorldEnvironment` node and enable `volumetric_fog` (with a density of `0.05` and a dark albedo color to fit the dark-mode aesthetic).
  * Hide the `vision_cone` mesh instance programmatically (`vision_cone.visible = false`) to satisfy the request to remove the cone.
  * Set `spotlight.light_volumetric_fog_energy = 24.0` and guarantee `spotlight.shadow_enabled = true` so the spotlight forms volumetric godbeams that get physically blocked by walkway walls and shine through windows/openings.

### [Level Configurations]

#### [MODIFY] [level_1_tutorial.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_1_tutorial.tscn)
* Place `Marker3D` nodes named `"SeekerLookSpot1"`, `"SeekerLookSpot2"`, etc. at the wall openings/windows. Set their rotation to point through the openings.

#### [MODIFY] [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)
* Place `Marker3D` look spots at the wall openings/windows.

#### [MODIFY] [level_3_engine_room.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_3_engine_room.tscn)
* Place `Marker3D` look spots at the wall openings/windows.

---

## Verification Plan

### Automated Tests
* Run unit tests to confirm all existing functionality passes.

### Manual Verification
* Throw a pebble near a window and watch the Seeker move to the look spot, align its rotation with the window, and shine its volumetric godbeams through the opening into the walkway.
