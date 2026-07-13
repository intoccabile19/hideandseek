# Phase 13 Walkthrough: Seeker Look Spots and Volumetric Godbeams

This document details the predefined window/opening Seeker look spots and programmatic volumetric fog setup completed for Phase 13.

## Implementation Details

### 1. Predefined Seeker Look Spots
* Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):
  * **Predefined Look Spot Discovery**: Added `_find_all_look_spots()` which recursively scans the level viewport scene tree at startup for any `Node3D` node whose name contains `"seekerlookspot"` or has the `"seeker_look_spots"` group.
  * **Generic Node3D Type Support**: Relaxed the search from `Marker3D` to `Node3D` type check to make discovery immune to any custom classes or editor node mappings.
  * **Look Spot Selection & Coordination**: In `_on_sound_heard()`, if the Seeker enters High Alert, it queries other active Seekers to find currently reserved spots, filters them out, and chooses the closest unoccupied look spot near the sound origin. If one is found, it reserves it (`_assigned_look_spot = spot`) and walks to it.
  * **Yaw Rotation Alignment**: In `_process_suspicious()` Phase 3 (at the wall), if the Seeker is investigating an assigned look spot, it rotates itself to align exactly with the look spot's rotation (`_assigned_look_spot.global_rotation.y`). This allows designers to rotate window look spots, guiding exactly which way the Seeker faces when peering through that window.
  * **Self-cleaning Reservations**: Automatically releases the spot (`_assigned_look_spot = null`) when transitioning back to WANDER or entering State.CHASE.

### 2. Precise Z-Axis Targeting and Stuck Prevention
* Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):
  * **Look Spot Z Position Respect**: Updated the Z-axis target calculation in `_physics_process()` to respect `_target_pos.z` during `State.SUSPICIOUS` (previously it forced translation to `peer_z = -6.0`). This allows Seekers to stand exactly at the Z coordinate of the look spot (e.g. `Z = -9.0`), keeping their large collision shapes safely back from the walkway walls.
  * **Horizontal Arrival Check**: Cleaned up Phase 2 of `_process_suspicious()`. Removed the `is_on_wall()` check entirely. The Seeker will walk towards the spot X and translate towards the spot Z, transitioning to Phase 3 (looking) once it is within `0.5m` on X or if the `5.0` second safety timeout fires.

### 3. Volumetric Fog & Godbeams
* Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):
  * **Programmatic Fog Activation**: In `_ready()`, programmatically retrieves the scene's `WorldEnvironment` and enables `volumetric_fog` (with density `0.05` and a dark color to fit the dark-mode aesthetic). This avoids manual edits inside all environment files.
  * **Spotlight Godbeams**: Configured `spotlight.light_volumetric_fog_energy = 24.0` and enabled `spotlight.shadow_enabled = true`. This forms volumetric godbeams that shine through open windows but are physically blocked by solid walls.
  * **Mesh Cone Hiding**: Hidden the old visual `vision_cone` mesh programmatically (`vision_cone.visible = false`) to let the new volumetric light beams take over.

### 4. Tutorial Level Look Spots
* Modified [level_1_tutorial.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_1_tutorial.tscn):
  * Positioned the three look spots (`SeekerLookSpot1`, `SeekerLookSpot2`, `SeekerLookSpot3`) along `Z = -9.0` (which is safely behind the wall at `Z = -3.57`) at horizontal positions `X = -15`, `X = 0`, and `X = 15`.
