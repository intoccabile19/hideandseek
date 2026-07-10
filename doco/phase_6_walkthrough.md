# Phase 6 Walkthrough - UI & Audio Systems

This document details the design, files modified, and verification results for the UI & Audio systems.

## 1. Summary of Changes

### A. Synthetic Audio System
* **[NEW] [sound_manager.gd](file:///d:/GameDev/hideandseek/scenes/audio/sound_manager.gd)**:
  * Registered as a global autoload `SoundManager` in `project.godot`.
  * Generates pure procedural sine waves using Godot 4 `AudioStreamGeneratorPlayback` to play whistle, chirp, mechanical footstep, and heartbeat sounds without requiring any local asset files, but exposes `@export` streams to easily drop in `.wav`/`.ogg` audio files.
  * Plays 3D spatialized footsteps and chirps at their respective origins.
  * Synthesizes a double heartbeat thud ("lub-dub") that dynamically scales its volume and speeds up its tempo based on the Seeker's current alert level.
  * Added `play_interact(pos)` playing a pleasant two-tone beep indicating action completion.
  * Added `play_object_move(pos)` playing a low mechanical hum indicating doors/bridges sliding.
  * Added `play_scrape(pos)` playing friction squeaks periodically when pushing crates.
* **[MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)**:
  * Triggers `SoundManager.play_whistle()` when commands (Follow/Freeze) are broadcast.
* **[MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)**:
  * Triggers `SoundManager.play_chirp(global_position)` when the toddler wanders off and chirps.
* **[MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)**:
  * Triggers `SoundManager.play_footstep(global_position, vol_db)` dynamically as it moves.
  * Calls `SoundManager.update_heartbeat(alert_level)` during its physics loop.
* **[MODIFY] [terminal_interactable.gd](file:///d:/GameDev/hideandseek/scenes/objects/terminal_interactable.gd)**:
  * Triggers `SoundManager.play_interact(global_position)` when a terminal is hacked/activated.
* **[MODIFY] [bridge_gate.gd](file:///d:/GameDev/hideandseek/scenes/objects/bridge_gate.gd)** & **[retracting_obstacle.gd](file:///d:/GameDev/hideandseek/scenes/objects/retracting_obstacle.gd)**:
  * Triggers `SoundManager.play_object_move(global_position)` when retraction or bridge raising starts.
* **[MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)**:
  * Triggers `SoundManager.play_scrape(global_position)` periodically (every 0.25 seconds) while pushing a RigidBody3D crate.

### B. User Interface & Menu Systems
* **[NEW] [hud_overlay.tscn](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.tscn)** & **[hud_overlay.gd](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.gd)**:
  * Implements a HUD Overlay Canvas featuring:
    * **Command Mode Indicator**: Shows `MODE: FOLLOW` (Green) or `MODE: FREEZE & HIDE` (Orange).
    * **Detection Warning Bar**: Displays the Seeker's alert percentage (0-100%).
    * **Warning Labels**: Stencils status texts: `SYSTEM STATUS: SECURE` (Green), `CAUTION: SEARCHING` (Orange), `ALERT: INVESTIGATING` (Yellow), and `WARNING: SPOTTED` (Pulsing Red).
    * **CRT Post-Process Shader**: Viewport color rect shader that creates retro scanlines, vignette shading, and corner screen bending.
* **[NEW] [game_state_menu.tscn](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.tscn)** & **[game_state_menu.gd](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.gd)**:
  * Displays:
    * **Main Menu**: Screen title with "Start Escort" and "Quit" buttons.
    * **Game Over Screen**: Warning text and retry buttons.
    * **Victory Screen**: Saved survivors score tally and restart buttons.
  * Uses `PROCESS_MODE_ALWAYS` to ensure buttons remain interactive when the SceneTree is paused.
* **[MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)**:
  * Instantiates a floating `Label3D` above the toddler's head that renders their real-time curiosity panic percentage (e.g., `TENSION: 65%`), dynamically shifting color (Green -> Yellow -> Red) before they break follow and wander off.

### C. Escape Zone
* **[NEW] [escape_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/escape_zone.gd)**:
  * Area3D zone positioned at the end of the walkway ($X = 20.0$).
  * Triggers the victory screen on player contact, calculating the total survivors saved.

---

## 2. Test Verification Results

### Automated Unit Tests
A new test suite **[test_ui_audio.gd](file:///d:/GameDev/hideandseek/tests/test_ui_audio.gd)** was created. All **26 tests** passed successfully:

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
  [PASS] test_seeker_wander_flow
  [PASS] test_seeker_hears_sound
  [PASS] test_seeker_spots_player
  [PASS] test_seeker_ignores_hidden_actor

Running suite: test_ui_audio.gd
  [PASS] test_sound_manager_methods
  [PASS] test_hud_overlay_updates
  [PASS] test_game_state_menu_behavior
  [PASS] test_escape_zone_victory_trigger

=========================================
Test Summary:
Passed: 26
Failed: 0
=========================================
All tests completed successfully!
```

---

## 3. Manual Verification Steps

1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. The game should start **paused** on a retro CRT terminal main menu. Click **Start Escort** to start.
3. Observe the **CRT scanner curved screen effect** wrapping the UI overlay.
4. Listen to the heartbeat audio speed up and get louder as the Seeker gets closer to the walkway or becomes alerted.
5. Press **`Q`** (Freeze/Hide) or **`E`** (Follow) to command companions, and listen to the procedural whistle sound effect play.
6. Stand in the Seeker's searchlight and watch the top center **Detection Warning Bar** fill up and flash `WARNING: SPOTTED!` in red.
7. Stop moving, command Freeze, and watch the Toddler's floating **`TENSION`** percentage tick up above its head. Let it hit 100% and watch it wander off while chirping.
8. Navigate past the Seeker and walkthrough the portal to $X = 20.0$. Enter the **EscapeZone** and watch the Game Over / Victory screen trigger.
