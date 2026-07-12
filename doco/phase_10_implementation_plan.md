# Phase 10 Implementation Plan: Seeker Robot Models and Animations

This plan details how we will integrate the new visual meshes, terminal patrolling, and animation states into the Seeker Robot.

## Proposed Changes

### 1. Robot Model Selection
* Under the `Skeleton3D` node in the Seeker scene, there are three MeshInstance3D nodes:
  * `Character_Robot_01` (Linked to `LAME` and `LAZY` / easy robot types)
  * `Character_Android_Female_01` (Linked to `NORMAL` robot type)
  * `Character_CyborgNinja_01` (Linked to `AGGRESSIVE` robot type)
* In `_ready()`, we will hide the default cube/capsule mesh placeholder (`MeshInstance3D`) and toggle visibility of these three meshes to match the assigned `seeker_type`.

### 2. patrolled Terminals & Working State
* Expose `@export var terminals: Array[Node3D] = []` in `seeker.gd`.
* Add `State.WORKING` to the seeker state machine.
* Update `_choose_next_wander()` to randomly select from both background `searchable_objects` and set `terminals`.
* Walking to a terminal puts the Seeker into `State.WORKING` upon arrival, picking randomly between 5 configured work animations to play for a set duration.

### 3. State-based Animation Mapping
* Expose `@export_group("Animations")` properties:
  * `anim_idle = "robot_idle"`
  * `anim_walk = "robot_walk_1"`
  * `anim_work_1 = "robot_work_1"`
  * `anim_work_2 = "pulling_lever"`
  * `anim_work_3 = "sending_a_fax"`
  * `anim_work_4 = "standing_using_a_touchscreen"`
  * `anim_work_5 = "using_a_fax"`
  * `anim_alert = "robot_alert_look"`
  * `anim_grab = "robot_grab_1"`
  * `anim_look_1 = "robot_look_1"`
  * `anim_look_2 = "robot_look_2"`
  * `anim_look_3 = "robot_look_high"`
* Map state processing to play the animations dynamically:
  * **Alert/Suspicious**: Play `anim_alert`.
  * **Wandering/Patrolling**: Play `anim_walk` (or `robot_walk_2` on chase).
  * **Searching/Seeking at wall**: Sequence/alternate between `anim_look_1`, `anim_look_2`, and `anim_look_3`.
  * **Capture/Grab**: Play `anim_grab`.
  * **Working**: Play one of the 5 configured work animations picked randomly at the start of the state.
  * **Sleeping**: Play `anim_idle` (disabled/low energy).

---

## Verification Plan

### Automated Tests
* Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all 41 test cases pass.

### Manual Verification
* Run `level_test.tscn` with terminal target assignments on the Seeker, and verify the model swap and animation playbacks trigger correctly.
