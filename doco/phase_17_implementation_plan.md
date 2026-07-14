# Phase 17: Start Screen, Pause Menu, and Game Won Screen

This phase introduces a dedicated Start Menu scene that loads at game startup, in-game pausing via the `ESC` key using the existing `GameStateMenu` overlay, and a dedicated Game Won scene when completing the final level.

## Proposed Changes

### Configuration

#### [MODIFY] [project.godot](file:///d:/GameDev/hideandseek/project.godot)
- Change `run/main_scene` from `"res://scenes/levels/level_1_tutorial.tscn"` to `"res://scenes/ui/start_menu.tscn"`.

---

### Start Menu Scene

#### [NEW] [start_menu.tscn](file:///d:/GameDev/hideandseek/scenes/ui/start_menu.tscn)
- A standalone UI scene with:
  - Title text: "HIDE & SEEK"
  - Buttons: **Start Game**, **Continue** (enabled if save file exists), **Quit**
  - Sound volume controls (HSlider) integrated into the menu layout.

#### [NEW] [start_menu.gd](file:///d:/GameDev/hideandseek/scenes/ui/start_menu.gd)
- Implements button callbacks:
  - **Start Game**: Resets progression and loads `level_1_tutorial.tscn`.
  - **Continue**: Loads the level path from `SaveManager` and changes scene.
  - **Quit**: Exits the game application.
  - **Volume Slider**: Adjusts master audio volume via `SoundManager`.

---

### Game State / Pause Menu Overlay

#### [MODIFY] [game_state_menu.gd](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.gd)
- Remove automatic pause and main menu activation on `_ready()`. Levels will now start immediately.
- Rename "StartButton" references to "Resume" button terminology (since it serves to resume gameplay).
- Handle the `ESC` (or `ui_cancel`) input event:
  - If the game is running normally, pressing `ESC` opens the menu and pauses the scene tree.
  - If the pause menu is open, pressing `ESC` (or clicking Resume) closes the menu and unpauses the scene tree.
  - If the Game Over or Victory screens are active, ignore the ESC input.
- Change the "Quit" button callback to return the player to the newly created `start_menu.tscn` instead of shutting down the whole game.

---

### Escape Zone & Game Won Screen

#### [NEW] [game_won.tscn](file:///d:/GameDev/hideandseek/scenes/ui/game_won.tscn)
- A dedicated victory scene shown when completing the final level of the game:
  - Header: "VICTORY! YOU ESCAPED!"
  - Text description celebrating the escape.
  - Statistics readout displaying the number of family members rescued.
  - Buttons: **Main Menu** (loads `start_menu.tscn`), **Exit Game**.

#### [NEW] [game_won.gd](file:///d:/GameDev/hideandseek/scenes/ui/game_won.gd)
- Displays final statistics (rescuing companion counts retrieved from `FamilyManager`).
- Re-enables normal processing (unpauses tree) and connects button signals.

#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
- Add a helper variable `var last_saved_count: int = 0` to store the survivor count for the Game Won screen.

#### [MODIFY] [escape_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/escape_zone.gd)
- If the final level is completed (`next_level_path` is empty), store the escaped companions count in `FamilyManager.last_saved_count` and change the active scene to `res://scenes/ui/game_won.tscn`.

---

## Verification Plan

### Automated Tests
- Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all existing test scenarios pass.

### Manual Verification
1. Run the game from Godot. It should load the Start Menu scene directly.
2. Verify the Start Game button starts the tutorial level.
3. While playing, press the `ESC` key. The game should pause, showing the pause menu.
4. Press `ESC` again (or click Resume). The game should resume playing.
5. Finish the last level (Level 3 or Level 2 with empty next_level_path) with companions. It should load the Game Won screen and display the correct number of rescued survivors.
