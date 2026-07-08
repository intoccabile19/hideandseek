# Phase 2: Family Queue & Whisper Network

Introduce the follow queue mechanics and command system, enabling family members to trail behind the player in a snake-like line and respond to "Follow" and "Freeze & Hide" commands.

## User Review Required

> [!IMPORTANT]
> To make escorting smooth and prevent followers from walking off cliffs or getting stuck behind ledges, we will use a **shared historical path buffer** tracked by the player. Followers will target points in this buffer sequentially, which means they will walk exactly in the player's footsteps (including replicating jumps and drops).
>
> We will map new inputs:
> * `command_follow`: Key **`E`** (calls the family to follow)
> * `command_freeze`: Key **`Q`** (tells the family to freeze and hide)

---

## Proposed Changes

### Input Configuration

#### [MODIFY] [project.godot](file:///d:/GameDev/hideandseek/project.godot)
* Add mappings for custom input actions:
  * `command_follow`: Key `E`
  * `command_freeze`: Key `Q`

### Core Scripts & Scenes

#### [NEW] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
* Script inheriting from `CharacterBody3D` representing a base family member.
* Implements a State enum: `FOLLOW`, `FREEZE`, `HIDING`.
* When in `FOLLOW` state, it queries the player's path history and moves toward its assigned target point on the path.
* Re-enforces Z-axis constraints to keep them locked on the 2.5D plane.

#### [NEW] [family_member.tscn](file:///d:/GameDev/hideandseek/scenes/family/family_member.tscn)
* Scene containing a `CharacterBody3D`, collision shape, and a distinct visual mesh placeholder (e.g., smaller cylinder/sphere to distinguish from the player).

#### [NEW] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* An autoload/central script that keeps references to all active family members in the scene.
* Orchestrates queue indexing (e.g., assigning each member their offset index in the player's path queue).
* Processes commands (`command_follow` / `command_freeze`) and broadcasts them to the active family members.
* Computes the "Whisper vs. Shout" sound projection radius based on proximity to the farthest member.

#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* Add a `path_history: Array[Vector3]` to store recent path coordinates.
* Every physics tick, if the player has moved a minimum distance (e.g., 0.1 units), prepend their new position to `path_history`.
* Limit the size of `path_history` to prevent memory leaks (based on the number of active family members).
* Emit signals when input actions `command_follow` and `command_freeze` are pressed.

#### [MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* Instantiate 2-3 family members in the level to allow manual verification of the queue following behavior.

### Tests

#### [NEW] [test_family.gd](file:///d:/GameDev/hideandseek/tests/test_family.gd)
* A unit test suite verifying that:
  * Family members follow the state changes (Follow, Freeze).
  * Player's path history records movements correctly.
  * Whisper network calculates the sound projection radius appropriately.

---

## Verification Plan

### Automated Tests
* Run the test suite:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
  ```
  Ensure all tests in `tests/test_family.gd` pass.

### Manual Verification
1. Run [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Walk forward and verify that the family members trail behind you in a clean, snake-like line.
3. Press **`Q`**: Verify family members stop immediately and enter `FREEZE` state.
4. Press **`E`**: Verify family members resume following.
5. Move far away from the family and press **`Q`** or **`E`**: Check console output logs to verify that the sound projection radius is flagged as a "SHOUT" instead of a "WHISPER" due to distance.
