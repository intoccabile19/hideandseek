### Level Transitions, Save/Load Game State, & Game Loop

#### [NEW] [save_manager.gd](file:///d:/GameDev/hideandseek/scenes/objects/save_manager.gd)
* A static helper class to handle reading and writing save state:
  * `save_level(scene_path: String)` writes the level scene path to `user://savegame.json`.
  * `load_level() -> String` retrieves the saved scene path.
  * `has_save() -> bool` checks if a save file exists.

#### [MODIFY] [escape_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/escape_zone.gd)
* Export `@export_file("*.tscn") var next_level_path: String = ""` to allow configuring level transitions in the inspector.
* In `_check_victory_condition()`, if `next_level_path` is configured:
  * Call `SaveManager.save_level(next_level_path)` to save the game.
  * Call `get_tree().change_scene_to_file(next_level_path)` to transition to the next level.
  * If it is empty, call the HUD victory screen to finish the game.

#### [MODIFY] [game_state_menu.gd](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.gd)
* Add a `ContinueButton` connection.
* On `_ready()`, if `SaveManager.has_save()` is true, make the `ContinueButton` visible/enabled. Otherwise, hide/disable it.
* When `ContinueButton` is pressed:
  * Load the saved level path using `SaveManager.load_level()`.
  * Change the scene to the saved level.

### Level Layouts

#### [NEW] [level_1_tutorial.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_1_tutorial.tscn)
* **Goal**: Teach basic controls (Follow, Hide/Freeze, and Climbing) and Seeker avoidance.
* **Setup**:
  * Linear path from left to right.
  * 1 Cover Zone (Medium) to teach hiding.
  * 1 pushable box (height `0.6m`) placed in front of a `1.2m` high wall, allowing the player and companions to climb over the wall.
  * Includes a **LAZY** Seeker patrolling in the background to teach safe hiding with minimal danger.
  * `EscapeZone` points to `res://scenes/levels/level_2_cargo_hold.tscn`.

#### [NEW] [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)
* **Goal**: Introduce Seeker patrols and Toddler wandering.
* **Setup**:
  * Medium-length path.
  * Includes a **NORMAL** Seeker patrolling in the background pathway.
  * Includes multiple cover zones (1 Small, 1 Medium, 1 Large).
  * Requires managing the Toddler's random wander behaviors and hiding the family when the Seeker looks/patrols towards the opening.
  * `EscapeZone` points to `res://scenes/levels/level_3_engine_room.tscn`.

#### [NEW] [level_3_engine_room.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_3_engine_room.tscn)
* **Goal**: High verticality and coordinated obstacle puzzle under high pressure.
* **Setup**:
  * High verticality platforms.
  * Includes an **AGGRESSIVE** Seeker patrolling in the background pathway (fast movement, fast alert growth).
  * Contains a terminal and a bridge gate (which must be raised to cross a gap).
  * Contains a retracting obstacle blocking the exit.
  * Pushing a box is required for the Elder to get up and activate the terminal.
  * Patrolling Seeker in the background.
  * `EscapeZone` has an empty `next_level_path` (triggers final game victory).

---

## Verification Plan

### Automated Tests
* Create `tests/test_phase_7.gd` to verify:
  * Scene files exist and load successfully.
  * `EscapeZone` correctly transitions scene files if `next_level_path` is loaded.

### Manual Verification
* Play through Level 1, confirming transitions to Level 2.
* Play through Level 2, confirming transitions to Level 3.
* Escape Level 3 with all companions and confirm the final victory screen displays correctly.
