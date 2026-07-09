# Phase 5 Walkthrough - Seeker Patrol & AI

This document details the design, files modified, and verification results for the Seeker Patrol & AI.

## 1. Summary of Changes

### A. Centralized Systems & Actors
* **[MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)**:
  * Implemented an `is_hidden` property and `_assigned_cover` reference.
  * Pressing the new dedicated **`hide_action`** button (mapped to `S` and `Down Arrow` keys) toggles cover hiding: checking if the player is currently overlapping a compatible `CoverZone`, and stepping back/hiding if so.
  * Manual controls (Left/Right/Jump) or pressing **`command_follow`** cancels cover and steps back to the walkway plane.
  * decouple player cover from the family's `command_freeze` key, which now purely controls companions.
* **[MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)**:
  * Automatically calls `_on_command_broadcast(State.FREEZE)` inside `_ready()` to start the game with all companions hidden inside compatible cover slots immediately at startup.
* **[MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)**:
  * Declared a global `game_over` signal to handle capture state events.

### B. Searchable Objects
* **[NEW] [searchable_object.gd](file:///d:/GameDev/hideandseek/scenes/objects/searchable_object.gd)**:
  * Extends `Node3D` and registers automatically in the `"searchable_objects"` group.
  * Exports `mesh: MeshInstance3D` to specify which visual part to animate.
  * Implements `lift(height, duration)` and `lower(duration)` using Godot 4 `create_tween()` to smoothly lift/lower background objects (like grates or panels) during seeker investigations.

### C. Seeker Droid AI
* **[NEW] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)**:
  * Implements the Seeker state machine:
    * **Two-Tier Alert System**: Maintains an `alert_level` (from `0.0` to `1.0`). Noise sources add to this level (e.g. whispers add `0.35`, shouts add `0.6`).
      * **Low Alert (< 0.5)**: The Seeker stops patrolling for `1.8` seconds and pivots its visual eye/mesh to peer towards the noise origin ("hmm did I hear something?"), then resumes wandering. Shows a yellow `?` above its head.
      * **High Alert (>= 0.5)**: The Seeker immediately transitions to `State.SUSPICIOUS`, walking to the opening in the wall to inspect the walkway slowly (`patrol_speed = 2.0`). Shows a yellow `?` above its head.
      * **Decay**: The alert level decays slowly over time at `0.06` per second when not actively investigating or chasing.
    * **Visual Alert Indicator**: Instanced an `AlertLabel` (`Label3D`) node above the Seeker's head, which automatically displays a yellow `?` when suspicious or looking curiously, a red `!` when spotting/chasing players, and clears when calm.
    * `State.SEARCHING`: Moves close to the window/opening or target box, lifts the background debris, sweeps its spotlight underneath, lowers it, and **immediately transitions to `State.SCANNING`** to sweep the walkway for any intruders before continuing its patrol.
    * `State.SCANNING`: Moves close to the window/opening ($Z = -6.0$ using a slow curious Z-lerp factor of `1.2`), turns forward towards the walkway (rotating Y to `PI`), and sweeps its spotlight angle left and right through the window.
    * `State.SUSPICIOUS`: Hears a noise on High Alert. Sound checks calculate horizontal ($X$-axis) distance. Once triggered, the Seeker faces forward, walks to the sound X coordinate, and slowly glides forward to the window ($Z = -6.0$ using a slow curious Z-lerp factor of `1.2`) to perform a wide spotlight sweep.
    * `State.CHASE` (Warning Phase): Spots an un-hidden player/companion through the window, tracks their horizontal coordinate and steps quickly forward to $Z = -6.0$ (using a fast Z-lerp factor of `4.0`), and begins a `2.0`-second warning timer. During this window, the spotlight rapidly flashes (cycles color between white and red and pulses intensity) and a red `!` is shown above its head to alert players. If the player hides in cover before the timer expires, the Seeker returns to `State.SUSPICIOUS` and drops the chase without grabbing them.
    * `State.CAPTURE` (Grab Flash): Triggers when a target fails to break line of sight within the warning window. The Seeker freezes and triggers a dramatic visual feedback grab effect: the spotlight surges to `200.0` light energy and flashes blinding pure white for `0.4` seconds before emitting `FamilyManager.game_over`.
  * Vision check `_check_vision()` scans for the player and active companions. Targets must be within the spotlight cone angle, within `vision_range` (extended to `18.0` meters), and have a clear line of sight. Hiding companions are completely ignored.
  * **Chest-Level Raycasting**: The vision raycast projects from the Seeker's spotlight global position to the target's chest (`global_position + Vector3(0.0, 1.0, 0.0)`), and utilizes strongly typed `Array[RID]` node exclusions to prevent self-collision or ground intersection bugs.
* **[NEW] [seeker.tscn](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.tscn)**:
  * Root: `CharacterBody3D` (Seeker) on Layer 1, scaled to `(10.0, 10.0, 10.0)` to establish a giant mechanical observer peering through portals in the distance.
  * Children: Capsule collision, capsule mesh, a red SpotLight3D acting as the volumetric searchlight, and a billboarded `AlertLabel` (`Label3D`) to render the `?` and `!` alert status text.

### D. Level Test Scene Setup
* **[MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)**:
  * Placed three background **SearchableBoxes** in the deep background at $Z = -12.0$ (at $X = -5.0, 2.0, 9.0$).
  * Instantiated the massive **Seeker** patrolling the deep background layer ($Z = -12.0$).

---

## 2. Test Verification Results

### Automated Unit Tests
A new test suite **[test_seeker.gd](file:///d:/GameDev/hideandseek/tests/test_seeker.gd)** was created. All **22 tests** passed successfully:

```
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

=========================================
Starting Godot Headless Test Runner...
=========================================

Running suite: test_classes.gd
  [PASS] test_toddler_properties_and_curiosity
  [PASS] test_elder_properties
  [PASS] test_adult_properties

Running suite: test_cover.gd
  [PASS] test_cover_zone_compatibility
  [PASS] test_cover_capacity_exhaustion
  [PASS] test_cover_navigation_flow

Running suite: test_example.gd
  [PASS] test_example_math

Running suite: test_family.gd
  [PASS] test_family_member_lifecycle_registration
  [PASS] test_command_broadcast_updates_state
  [PASS] test_whisper_sound_propagation
  [PASS] test_dynamic_queue_sorting

Running suite: test_interaction.gd
  [PASS] test_family_manager_class_filtering
  [PASS] test_interactable_registration
  [PASS] test_family_member_interacts_upon_arrival
  [PASS] test_terminal_interaction_mechanics

Running suite: test_player.gd
  [PASS] test_player_scene_loads
  [PASS] test_player_instantiation_and_properties
  [PASS] test_player_z_axis_lock

Running suite: test_seeker.gd
[Seeker Seeker] Wandering to background X: -8.59
  [PASS] test_seeker_wander_flow
[Seeker @CharacterBody3D@12] Heading to search background object: TestSearchable at X: 5.00
[Seeker Seeker] Heard noise at X: 4.00. Investigating...
[Seeker @CharacterBody3D@12] Heard noise at X: 4.00. Investigating...
  [PASS] test_seeker_hears_sound
[Seeker @CharacterBody3D@15] Heading to search background object: @Node3D@14 at X: 5.00
[Seeker @CharacterBody3D@15] SPOTTED target: Player! Chasing...
  [PASS] test_seeker_spots_player
[Seeker @CharacterBody3D@18] Wandering to background X: 8.67
  [PASS] test_seeker_ignores_hidden_actor

=========================================
Test Summary:
Passed: 22
Failed: 0
=========================================
All tests completed successfully!

=========================================
[SUCCESS] All tests and validations passed!
=========================================
```

---

## 3. Manual Verification Steps

1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Watch the Seeker in the background:
   * It wanders along the back layer ($Z = -12.0$).
   * It stops at the background boxes, lifts them up, shines its light underneath, and lowers them.
   * Every now and then, it stops, turns to face the walkway, and sweeps its searchlight left and right.
3. Stand in the open walkway when its searchlight sweeps over you:
   * Notice the Seeker transitions to `State.CHASE`, stepping forward to $Z = -6.0$ (safe buffer to avoid wall collision).
   * A red flashing **`!`** is shown above its head.
   * The red spotlight begins flashing rapidly to warn you.
   * If you stay in the light for `2.0` seconds, it triggers `State.CAPTURE` (blinding white flash) and game over.
4. **Test Player Hiding**:
   * Physically walk your player inside a compatible `CoverZone` area and press the **`S`** key or **`Down Arrow`** key (the dedicated `hide_action`).
   * Notice your player instantly steps back into Z-depth cover at their exact current X coordinate and enters hiding (`is_hidden = true`).
   * Stand in the Seeker's spotlight while hiding. Notice that it completely ignores you!
   * Press Left, Right, Jump, or **`command_follow`** to cancel cover. Notice you instantly regain manual control and step back to the walkway plane.
5. Command your family members to Freeze & Hide near cover zones. Watch them enter cover. Notice that when the Seeker's spotlight sweeps over them in cover, they are ignored.
6. Whistle (or let the toddler chirp). Watch the Seeker stop its search:
   * On low alert, it pauses in place for `1.8` seconds, showing a yellow **`?`** and looking in your direction before continuing.
   * On high alert, it walks slowly (`patrol_speed = 2.0`) to your horizontal coordinate, showing a yellow **`?`** and performing a wide sweep.
