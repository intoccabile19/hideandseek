# Phase 11 Walkthrough: Environment and Interactable Model Updates

This document details the environmental and Seeker speed/animation updates completed for Phase 11.

## Implementation Details

### 1. Retractable Obstacle Upward Movement & Disappearance
* Modified [retracting_obstacle.gd](file:///d:/GameDev/hideandseek/scenes/objects/retracting_obstacle.gd):
  * Changed the default retracted position `@export var inactive_y` from `-1.5` to `4.0` (upwards, raising above the level/ceiling).
  * Updated `_physics_process(delta)`: Once `is_retracted` is true and the obstacle finishes its upward movement (matching `inactive_y` via `is_equal_approx`), it disables its collision shape and sets `visible = false` to disappear from the game screen.
  * In `_ready()`, if `is_retracted` is true, set `visible = false` initially.
  * This prevents null reference errors or crashes in tests that hold references to retracted obstacles, while ensuring they disappear visually and physically.

### 2. Level Obstacle Configuration Updates
Updated the following scenes:
* [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* [level_1_tutorial.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_1_tutorial.tscn)
* [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)
* [level_3_engine_room.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_3_engine_room.tscn)

For each scene:
* **Removed Ground Box**: Deleted the `ObstacleBox1` node and its child shapes/meshes.
* **Console Target Reference**: Set `target_obstacle_2 = NodePath("")` (empty) on `ObstacleConsole` to remove the reference to the deleted `ObstacleBox1`.
* **Air Box Retract Upward**: Set `inactive_y = 6.0` on the `VentWall` (which starts in the air at `active_y = 2.0`) so that it retracts upwards (into the ceiling) when activated instead of downwards.

### 3. Seeker Movement Speed Increases
* Increased movement speeds (patrol, investigate, and chase) for all 4 Seeker archetypes (`LAZY`, `NORMAL`, `AGGRESSIVE`, `LAME`) in `_ready()` to make them faster and more challenging.

### 4. Walking Animation Speed Matching & Fallback
* Programmatically scales the `AnimationPlayer`'s `speed_scale` based on the Seeker's current horizontal movement velocity when playing a walk/chase animation (`anim_walk` or `robot_walk_2`).
* **Chase Slide Fix**: Added a fallback check when in `State.CHASE`. If the visual mesh's AnimationPlayer does not contain the `"robot_walk_2"` fast-walk animation (such as on LAME/LAZY robot models), it falls back to using `anim_walk` (`"robot_walk_1"`). This prevents them from sliding in an idle pose.
* **Alert & Search Z-Movement Slide Fix**: Computed a true 3D horizontal velocity vector `_actual_velocity` by combining their physics-driven X movement with their direct translation-driven Z movement (`move_toward` calculations). Using `_actual_velocity` instead of the node's slide-only velocity prevents the Seeker from sliding when walking to background search boxes or walking to investigate walls.

### 5. Invisible SeekerWorkSpot Editor Markers
* **Stand & Face Alignment**: When targeting a terminal to work or a searchable box to search, the Seeker checks if the target contains a child `Marker3D` node named `"SeekerWorkSpot"`.
* **Editor Visualization**: The designer can position and rotate the `SeekerWorkSpot` marker in the level editor to designate exactly where the robot should stand and which direction it should face when working or searching.
* **Tutorial Level Default Placements**: Added default `SeekerWorkSpot` Marker3D nodes under the three searchable boxes (`SearchableBox1`, `SearchableBox2`, and `SearchableBox3`) in `level_1_tutorial.tscn`.
* **Runtime Invisibility**: The spot is automatically set to `visible = false` at runtime, rendering it and any visual mesh helpers (such as arrow models pointing direction) completely invisible to players during gameplay.

### 6. Look Animation Interruption & Completion
* **Complete Look Sequence**: In `_process_suspicious()`, the Seeker queries the active look animation length dynamically. Once a look animation is started, it is guaranteed to complete its full duration before a new look animation is selected or before the Seeker transitions back to WANDER.
* **Chase Break Exception**: The only state transition allowed to break this look animation sequence is an active detection or grab transition (`State.CHASE` or `State.CAPTURE`).

### 7. Multi-Seeker Coordination & Collision Avoidance
* **Target Collision Avoidance**: When selecting a new target in `_choose_next_wander()`, Seekers query other active Seekers in the `"seeker"` group and filter out any terminals or searchable boxes currently occupied or targeted by another Seeker, preventing them from visiting/working in the same spot.
* **Proximity Yielding**: Added a proximity check before `move_and_slide()`. If two Seekers get within `3.5` units of each other (and neither is actively chasing the player), the Seeker with the lower instance ID yields (stops moving and idles) to let the other pass, preventing them from running into each other.
