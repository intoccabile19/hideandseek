# Phase 12 Implementation Plan: Fixes and Refinements

This plan details how we will address several key bug fixes and refinements in animations, input interactions, and game-over conditions.

## Proposed Changes

### [Player Component]

#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* In `_physics_process(delta: float)`:
  * Remove `abs(v_axis) > 0.1` from the cover release override condition. This prevents the **S** key (which triggers both `move_down` and `hide_action`) from instantly canceling hiding.

### [Family Component]

#### [MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
* **Release Cover on Interact**: In `interact_with(target, direction)`, call `release_cover()` to reset `is_hidden = false` and clean up the assigned cover slot.
* **Walking Animation Priority**: In `_process_animations(delta)`, evaluate `abs(velocity.x) > 0.1` first so that any movement immediately triggers the walking animation (`anim_move`).
* **Interaction Animation Delays**:
  * Declare `var _interact_anim_timer: float = 0.0`.
  * In `_execute_interaction()`, query the length of `anim_interact_1` in the active `AnimationPlayer`, set `_interact_anim_timer = anim_len`, and start playing the animation.
  * In `_process_interacting(delta)`, if `_interact_anim_timer > 0.0`, lock movement, decrement the timer, and only trigger the target interaction (opening gates/platforms) and return to follow state once the timer has reached `0.0`.

#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* **GameOver Fall Zone**:
  * Implement `_process(delta: float) -> void` to continuously check if the player or any active family member falls below Y = `-15.0`.
  * If true, print a log and emit the `game_over` signal.

---

## Verification Plan

### Automated Tests
* Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all 41 test cases pass.

### Manual Verification
* Press **S** near a cover zone and verify the player stays hidden in cover.
* Order the Toddler out of cover to a terminal and verify they play the running animation.
* Order the Elder to hack a bridge console, verifying that the console is only triggered after the full duration of the hacking animation plays.
* Walk off a ledge and verify falling below Y = -15.0 triggers Game Over.
