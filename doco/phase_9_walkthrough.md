# Phase 9 Walkthrough: Character Animations Configuration

This document outlines how animations and mesh orientations have been implemented and mapped consistently across the Player and companion Hiders.

## Implementation Details

### Consistent Variable Naming Scheme
Every character script (Player and Hiders) now exposes the following Inspector properties:
* `anim_idle`: Animation key when stationary.
* `anim_move`: Animation key when running/walking.
* `anim_jump`: Animation key when airborne (jumping/falling).
* `anim_hide`: Animation key when in cover or frozen.
* `anim_interact_1`: First character-specific action animation key.
* `anim_interact_2`: Second character-specific action animation key.
* `anim_interact_3`: Third character-specific action animation key.

### Visual Mesh Orientation Rotation
Both Player and companion Hiders now automatically rotate their visual models (`Skeleton3D` children) on the Y axis to face the movement direction in 3D:
* **Facing Right**: Target `rotation.y = PI / 2` (default import direction).
* **Facing Left**: Target `rotation.y = -PI / 2`.
* This visual rotation is smoothly interpolated using `lerp_angle(..., delta * 12.0)` to ensure natural transitions without rotating the parent root node (thus preventing camera spinning).

### Fix: Walk-to-Interact & Action Animation Transitions
* Previously, entering `State.INTERACTING` returned early from the physics process loop, preventing visual mesh orientation and animation processing from updating.
* Refactored `_process_interacting` to update `facing_direction` and run the `_process_animations` sequence:
  * While moving towards the interaction target (`abs(velocity.x) > 0.1`), hiders correctly play `anim_move` (walking/running).
  * Upon arriving at the target (`velocity.x == 0.0`), hiders automatically trigger the specific action animation (`anim_interact_1`).
  * Face direction automatically aligns to the interaction's target orientation `_interact_dir` when stationary.

### Fix: Adult Box Pushing & Gate Bracing Animations
* Refactored [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd) to fall through the custom PUSHING and BRACING blocks into the orientation and animation update cycles.
* The Adult now faces the push direction (`_push_dir`) and plays the pushing animation (`anim_interact_2`) correctly during `State.PUSHING`.
* The Adult faces the gate and plays the bracing animation (`anim_interact_1`) during `_is_bracing`.

### Character-Specific Mappings & Default Keys

1. **Player ([player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd))**
   * Default keys:
     * `anim_idle` = `"Player/player_idle"`
     * `anim_move` = `"Player/player_run"`
     * `anim_jump` = `"Player/player_jump"`
     * `anim_interact_1` = `"Player/player_climb"` (Climbing ladder)
     * `anim_interact_2` = `"Player/player_throw"` (Throwing pebble)
   * Selection: Uses a transient throw timer (`_throw_timer`) to ensure the throw animation plays fully before defaulting to run/idle. Play `anim_jump` if `not is_on_floor()`.

2. **Base Hider ([family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd))**
   * Defines base `_process_animations()` that handles playing `anim_hide` (when in cover/frozen), `anim_jump` (when airborne/falling/jumping), `anim_move` (when moving horizontally), and `anim_idle` (when stationary).
   * Safe check: Calls `get_node_or_null("AnimationPlayer")` to prevent errors in unit tests or when models are missing.

3. **Adult ([adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd))**
   * Default keys:
     * `anim_idle` = `"Adult/adult_idle"`
     * `anim_move` = `"Adult/adult_run"`
     * `anim_jump` = `"Adult/adult_jump"`
     * `anim_interact_1` = `"Adult/adult_brace"` (Bracing gate)
     * `anim_interact_2` = `"Adult/adult_push"` (Pushing box)
     * `anim_interact_3` = `"Adult/adult_launch"` (Launching toddler)

4. **Elder ([elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd))**
   * Default keys:
     * `anim_idle` = `"Elder/elder_idle"`
     * `anim_move` = `"Elder/elder_run"`
     * `anim_jump` = `"Elder/elder_jump"`
     * `anim_interact_1` = `"Elder/elder_hack"` (Hacking terminal)

5. **Toddler ([toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd))**
   * Default keys:
     * `anim_idle` = `"Toddler/toddler_idle"`
     * `anim_move` = `"Toddler/toddler_run"`
     * `anim_jump` = `"Toddler/toddler_jump"`
     * `anim_interact_1` = `"Toddler/toddler_crawl"` (Vent crawling)
     * `anim_interact_2` = `"Toddler/toddler_thrown"` (Thrown in air)

---

## Verification Results

### Headless Verification
* Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all 41 test cases pass.
* All 41 tests compile and pass successfully with zero animation/rotation related errors!
