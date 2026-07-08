# Phase 1: Player Controller & 2.5D Foundation

Set up the project structure, basic 2.5D side-scrolling mechanics, and the Player (Leader) character with physics movement.

## User Review Required

> [!NOTE]
> Since this is a 2.5D game, we will use a 3D environment but lock movement to a 2D plane (X and Y axes, Z-axis locked to 0). This allows using 3D low-poly models (from Synty asset packs) while keeping the gameplay side-scrolling.

## Open Questions
- None.

## Proposed Changes

### Core Scene Structure

#### [NEW] [player.tscn](file:///d:/GameDev/hideandseek/scenes/player/player.tscn)
* A `CharacterBody3D` representing the player.
* Contains a collision shape, a placeholder mesh (for now), and a `Camera3D` configured to follow the player on a fixed side-view offset.

#### [NEW] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* Script inheriting from `CharacterBody3D`.
* Implements standard 2.5D side-scrolling controls (A/D or Arrow keys to move, Space to jump).
* Automatically locks the Z position of the player to `0.0` to keep movement strictly 2D.

#### [NEW] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* The test level containing static floor platforms (`StaticBody3D` nodes) and the spawned player instance to test basic physics interaction.

### Tests

#### [NEW] [test_player.gd](file:///d:/GameDev/hideandseek/tests/test_player.gd)
* A unit test suite verifying that:
  * The player scene can be loaded and instantiated.
  * The player script has the required movement variables (`SPEED`, `JUMP_VELOCITY`).
  * The player's Z-axis constraint behaves correctly.

## Verification Plan

### Automated Tests
- Execute tests using:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
  ```
  Ensure all assertions in `tests/test_player.gd` pass.
