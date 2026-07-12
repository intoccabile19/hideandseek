# Phase 9 Implementation Plan: Character Animations

This plan details how we will integrate animations into the Player and companion Hider characters using exposed animation variables and dynamic state checks under a consistent configuration scheme.

## Proposed Changes

### Animation Configuration Scheme
Each character (Player and Hiders) will expose a consistent set of animation properties:
* `anim_idle`: Playing when stationary.
* `anim_move`: Playing when moving or walking.
* `anim_hide`: Playing when hiding in cover zones or frozen.
* `anim_interact_1`: First character-specific interaction.
* `anim_interact_2`: Second character-specific interaction.
* `anim_interact_3`: Third character-specific interaction.

### Character Mapping

| Character | anim_idle | anim_move | anim_hide | anim_interact_1 | anim_interact_2 | anim_interact_3 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Player** | Idle pose | Running/walking | Hiding in cover | Climbing ladder | Throwing pebble | *(Reserved)* |
| **Adult** | Idle pose | Running/walking | Frozen/hiding | Bracing gate | Pushing box | Launching toddler |
| **Elder** | Idle pose | Running/walking | Frozen/hiding | Hacking terminal | *(Reserved)* | *(Reserved)* |
| **Toddler**| Idle pose | Running/walking | Frozen/hiding | Vent crawling | Thrown in air | *(Reserved)* |

---

### Code Refactor

#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* Expose `@export_group("Animations")` with:
  * `anim_idle = "Player/player_idle"`
  * `anim_move = "Player/player_run"`
  * `anim_hide = ""`
  * `anim_interact_1 = "Player/player_climb"`
  * `anim_interact_2 = "Player/player_throw"`
  * `anim_interact_3 = ""`
* Play animations in `_physics_process`:
  * If climbing: play `anim_interact_1`
  * If throwing: play `anim_interact_2`
  * If in cover: play `anim_hide`
  * If moving: play `anim_move`
  * Otherwise: play `anim_idle`

#### [MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
* Expose base `@export_group("Animations")` with `anim_idle`, `anim_move`, `anim_hide`, `anim_interact_1`, `anim_interact_2`, and `anim_interact_3`.
* Play animations in base `_physics_process`:
  * If in cover (`is_hidden` or `State.FREEZE`): play `anim_hide`
  * If moving (velocity.x != 0): play `anim_move`
  * Otherwise: play `anim_idle`

#### [MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
* Override logic to play specific animations:
  * If bracing: play `anim_interact_1` (bracing)
  * If pushing: play `anim_interact_2` (pushing)
  * If launching: play `anim_interact_3` (launching)

#### [MODIFY] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)
* Override logic to play specific animations:
  * If hacking terminal: play `anim_interact_1` (hacking)

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
* Override logic to play specific animations:
  * If vent crawling: play `anim_interact_1` (crawling)
  * If thrown/airborne: play `anim_interact_2` (thrown)

---

## Verification Plan

### Automated Tests
* Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all 41 test cases pass.

### Manual Verification
* Deploy `level_test.tscn`, assign test animation strings, and verify they play.
