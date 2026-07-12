# Phase 10 Walkthrough: Seeker Robot Models and Animations

This document outlines how visual mesh loading, patrolling/working at terminals, and state-based animation selectors have been integrated into the Seeker Robot.

## Implementation Details

### 1. Seeker Robot Model Selection
* Toggle the default capsule/cube placeholder mesh (`MeshInstance3D`) to `visible = false` in `_ready()`.
* Toggle the respective skeletal meshes under `$Skeleton3D` based on `seeker_type`:
  * **LAME and LAZY** (Easy): Shows `Character_Robot_01`.
  * **NORMAL**: Shows `Character_Android_Female_01`.
  * **AGGRESSIVE**: Shows `Character_CyborgNinja_01`.
  * Safely checks for mesh presence via `get_node_or_null()` to prevent startup crashes.

### 2. Spotlight Head Bone Alignment
* Programmatically links the Seeker's `SpotLight3D` and child `VisionCone` position directly to the `"Head"` bone of the active visual model (`Skeleton3D`).
* Evaluated dynamically after `move_and_slide()` to ensure it stays perfectly synchronized with any head movements during walking or working animations.

### 3. Patrolling Terminals & Working State
* Exposes `@export var terminals: Array[Node3D] = []` on the Seeker.
* Created a new state `State.WORKING` in the Seeker state machine.
* Unified background patrol destination routing:
  * When choosing a new patrol target in `_choose_next_wander()`, the Seeker randomly selects from both the level's background `searchable_objects` and its assigned `terminals`.
  * If a terminal is selected, the Seeker moves to the terminal. Upon arrival, it transitions to `State.WORKING`.
  * During the working state, the Seeker faces the terminal, locks movement, and plays a random selection of 5 configured work animations.

### 4. Work Animation Selection & Search Sites
* **Search Site Work Integration**: When the Seeker patrols background `searchable_objects` (`State.SEARCHING`), it now randomly plays one of the 5 configured work animations (similar to terminals/work sites).
* **Guaranteed Animation Playback**: When starting a work task, `_select_random_work_anim()` queries the `AnimationPlayer` resource library for the chosen animation's length (e.g. `anim.length`) and stores it in `_work_duration`.
* The Seeker remains in `State.WORKING` and `State.SEARCHING` for exactly the duration of the animation, ensuring it completes fully before moving to another task.

### 5. Alert Phase & Random Wall Peering
* **Alert Animation Duration**: When transitioning to `State.SUSPICIOUS`, the Seeker queries the `AnimationPlayer` to determine the length of `anim_alert` and stores it in `_alert_duration`.
* **Standstill alerted**: It remains stationary playing the alerted animation for exactly `_alert_duration` seconds before moving.
* **Walk to Wall**: After the alert phase, it walks slowly towards the wall/sound position playing `anim_walk`.
* **Random Look Sequences**: Once it reaches the wall, it stands still and sweeps the area, randomly picking one of the look animations (`anim_look_1`, `anim_look_2`, `anim_look_3`) and cycling to a new look animation every `1.8` seconds.

### 6. Chase Grab & Capture Completion
* **Spotted Freeze Correction**: Resolved a bug where `_spotted_target` remained populated, causing the velocity to freeze during `State.CHASE`.
* `_spotted_target` is now explicitly set to `null` on chase start, and the freeze-velocity condition is restricted so it does not apply during `State.CHASE` or `State.CAPTURE`.
* **Grab Playback before Game Over**: During `State.CAPTURE`, the Seeker queries the `AnimationPlayer` for the duration of the grab animation (`anim_grab`). It halts movement and plays the grab animation fully. The Game Over screen is triggered only after the animation has finished playing out completely.

---

## Verification Results

### Headless Verification
* Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all 41 test cases pass.
* All 41 tests compile and pass successfully with zero animation/model related errors!
