# Phase 7 Walkthrough: Level Design & Game Loop Polish

This document outlines the implementation details for the campaign levels, Seeker difficulty scaling, progressive level transitions, fullscreen scaling, floating 3D tutorials, and persistent save/load features.

## Changes Implemented

### 1. Level Transitions & Persistent Saving/Loading
* **[NEW] [save_manager.gd](file:///d:/GameDev/hideandseek/scenes/objects/save_manager.gd)**:
  * Implemented a static helper class to serialize and save the current level scene path to `user://savegame.json`.
* **[MODIFY] [escape_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/escape_zone.gd)**:
  * Exported `next_level_path` to configure transitions in the inspector.
  * When victory is achieved on a level: if `next_level_path` is configured, it auto-saves the new level path using `SaveManager` and loads the new scene immediately. If empty, the final victory scoreboard screen displays.
* **[MODIFY] [game_state_menu.tscn](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.tscn)**:
  * Added a `ContinueButton` inside the Main Menu layout.
* **[MODIFY] [game_state_menu.gd](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.gd)**:
  * Displays the `ContinueButton` only if a save game file is detected.
  * Connects the press event to load the stored level scene path and transition into it.
* **[MODIFY] [project.godot](file:///d:/GameDev/hideandseek/project.godot)**:
  * Set `run/main_scene` to `res://scenes/levels/level_1_tutorial.tscn` to start new play sessions from the tutorial level.
  * Configured window stretch parameters (`canvas_items` mode, `expand` aspect) to support smooth aspect scaling upon fullscreen toggles and window resizes.

### 2. Escalating Campaign Levels & Floating 3D Tutorials
* **[NEW] [level_1_tutorial.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_1_tutorial.tscn)**:
  * Focuses on teaching the basics (Hiding, Climbing, Follow).
  * Includes a **LAME** Seeker patrolling in the background (cannot see, hear, or attack, and displays a passive light green vision cone).
  * Appended 6 progressive, floating `Label3D` tutorials along the walkway to guide the player (covering movement, commands, targeting, crate pushing, elder step climbing, and exit criteria).
  * Exit zone transitions to Level 2.
* **[NEW] [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)**:
  * Focuses on Seeker patrols and Toddler wandering.
  * Includes a **NORMAL** Seeker patrolling.
  * Exit zone transitions to Level 3.
* **[NEW] [level_3_engine_room.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_3_engine_room.tscn)**:
  * Focuses on verticality, coordinated console/bridge obstacle clearing.
  * Includes an **AGGRESSIVE** Seeker patrolling.
  * Exit zone triggers final game victory.

### 3. Escape Zone and Seeker Vision Balancing (Refinements)
* **Widened EscapeZones**:
  * Widened the collision area of `BoxShape3D_escape` from `3.0m` to `10.0m` across all campaign levels (`level_test.tscn`, `level_1_tutorial.tscn`, `level_2_cargo_hold.tscn`, and `level_3_engine_room.tscn`). This prevents queued companions from getting stuck outside the exit bounds when the player stops moving.
* **Gradual Seeker Visual Warning Meter**:
  * Overhauled `seeker.gd` to replace instant chases with a gradual visual detection warning meter.
  * When an actor enters the Seeker's spotlight, the Seeker freezes, locks its gaze onto the actor, and builds up `alert_level` over time (taking roughly 2 seconds to trigger a chase).
  * If the actor slides back into cover before the meter fills, the Seeker loses sight, transitioning to a `SUSPICIOUS` search state at the last seen position rather than initiating an instant chase.
  * Extended patrol search wait times to `3.5s` - `5.5s` to grant the player larger windows of opportunity to execute puzzle actions.

---

## Verification Results

### Automated Tests
* **[NEW] [test_phase_7.gd](file:///d:/GameDev/hideandseek/tests/test_phase_7.gd)**:
  * Verifies `SaveManager` read/write capabilities to `user://savegame.json`.
  * Verifies all three progressive level scenes exist and load successfully.
  * Verifies that entering the `EscapeZone` triggers level auto-saving.
  * Verifies the **LAME** Seeker's configuration parameters and zero sound/alert response properties.
* **[MODIFY] [test_seeker.gd](file:///d:/GameDev/hideandseek/tests/test_seeker.gd)**:
  * Updated Seeker spotting test coordinates to align with the unified root rotation system, ensuring tests pass with the new gradual detection accumulation system.
* All 35 tests passed successfully:
  ```
  =========================================
  Test Summary:
  Passed: 35
  Failed: 0
  =========================================
  ```
