# Phase 11 Implementation Plan: Retractable Obstacle Upward Movement and Multi-Seeker Coordination

This plan details how we will modify the retracting obstacles in all levels so that the box in the air (`VentWall`) moves upwards, and the unneeded box on the ground (`ObstacleBox1`) is removed.
Additionally, we will refine the Seeker robot's animations, and implement multi-seeker coordination to prevent them from colliding or visiting the same spots.

## Proposed Changes

### [Objects Component]

#### [MODIFY] [retracting_obstacle.gd](file:///d:/GameDev/hideandseek/scenes/objects/retracting_obstacle.gd)
* Change default `@export var inactive_y` to `4.0`.
* In `_physics_process(delta : float)`:
  * When `is_retracted` is true and the position matches the target `inactive_y` (using `is_equal_approx`), disable collision shape and set `visible = false` to make it disappear from the game.
  * In `_ready()`, if `is_retracted` is true, set `visible = false` initially.

### [Seeker Component]

#### [MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)
* **Chase Walk Fallback**: In `_process_animations()`, when in `State.CHASE`, check if `robot_walk_2` exists in the animation player. If not (e.g. on LAME/LAZY robots), fall back to `anim_walk` (`robot_walk_1`) to prevent sliding in an idle state.
* **Look Animation Completion**:
  * Expose `_look_duration` and `_look_timer` variables.
  * In `_select_random_look_anim()`, query the selected animation's length dynamically.
  * In `_process_suspicious()`, track `_look_timer`. Only change look animations or transition back to WANDER once the current look animation has completed its full duration.
* **Multi-Seeker Target Coordination**:
  * In `_choose_next_wander()`, iterate over other seekers in the `"seeker"` group and gather their currently targeted terminals and searchable objects.
  * Filter out those targets from the available pool so that multiple seekers do not choose the same spot.
* **Proximity Yielding**:
  * In `_physics_process()`, if another seeker is within `3.5` units of distance and neither is in the active chase/capture state, the seeker with the lower instance ID yields (stops and idles) until the path is clear.

### [Levels Component]

#### [MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
#### [MODIFY] [level_1_tutorial.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_1_tutorial.tscn)
#### [MODIFY] [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)
#### [MODIFY] [level_3_engine_room.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_3_engine_room.tscn)
* Delete `ObstacleBox1` and its child shape/mesh nodes.
* Set `target_obstacle_2` to empty/none on `ObstacleConsole`.
* Set `inactive_y = 6.0` on `VentWall` so that it retracts upwards (into the ceiling) instead of downwards.

---

## Verification Plan

### Automated Tests
* Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all 41 test cases pass.

### Manual Verification
* Run the levels and verify that the console only retracts the `VentWall` upwards, and that `ObstacleBox1` is removed.
* Verify Seeker walks animations match speed scale and does not slide when starting to chase.
* Verify Seeker completes look animations fully.
* Verify multiple Seekers in the tutorial level do not choose the same work/search spots and stop to let each other pass when close.
