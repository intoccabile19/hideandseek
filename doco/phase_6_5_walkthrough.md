# Phase 6.5 Walkthrough - Granular Controls, Seeker Types & Group Escape

This document details the design, files modified, and verification results for the Phase 6.5 gameplay improvements.

## 1. Summary of Changes

### A. Dynamic Companion Targeting (Keys 1-4)
* **[MODIFY] [project.godot](file:///d:/GameDev/hideandseek/project.godot)**:
  * Registered input actions: `target_all` (Key 1), `target_member_1` (Key 2), `target_member_2` (Key 3), and `target_member_3` (Key 4).
* **[MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)**:
  * Added `current_target_member: FamilyMember` (default `null` for ALL).
  * Exposed `select_target_by_index(idx: int)` mapping indices to registered level companions.
  * Updated cover allocation to only modify cover states for targeted companions.
* **[MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)**:
  * Updated `_on_command_broadcast()` to ignore commands if a specific member is targeted and it is not this member.
* **[MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)**:
  * Wired keys `1`-`4` to set targeting indices on `FamilyManager`.
* **[MODIFY] [hud_overlay.gd](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.gd)**:
  * Bottom command label updated to display the targeted companion dynamically (e.g. `MODE: FOLLOW | TARGET: MEMBER 1 (TODDLER)`).

### B. Stealth Whisper/Shout Propagation
* **[MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)**:
  * Updated `_calculate_sound_propagation()` to check the distance between the player and the active targeted companion. Whistling to command a companion right next to you generates a quiet whisper (2.0m radius). Shouting to command a companion far away generates a loud shout (15.0m radius).

### C. Seeker Personalities (Lazy, Normal, Aggressive)
* **[MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)**:
  * Exposed `@export var seeker_type: SeekerType = SeekerType.NORMAL`.
  * Decoupled normal wander speed (`2.0` uniform for all) from the investigate speed.
  * Added `investigate_speed` parameter mapping:
    * **LAZY**: Moves to the wall at a very slow walk of **`0.8`**. It has a low alert multiplier (`0.5`). On a first quiet sound, it registers a Low Alert, freezes in place, and rotates to "look" in the direction of the sound for 1.8 seconds without walking to the wall at all.
    * **NORMAL**: Moves to the wall at a casual walk of **`1.4`** (never rushing).
    * **AGGRESSIVE**: Rushes to the wall at **`2.5`** speed.
  * During a Low Alert (`_faint_look_timer > 0.0`), the Seeker now pauses movement (velocity zeroed) and faces the sound cue, bypassing normal state updates. The previous wander destination `_target_pos` is preserved, preventing the Seeker from walking towards the wall.
  * Configured speeds, vision/spotlight timers, alert decay rates, and alert growth multipliers dynamically on ready:

### D. Group Escape Win Condition
* **[MODIFY] [escape_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/escape_zone.gd)**:
  * Added `escaped_members` tracking.
  * Requires the Player and all alive registered family members to be simultaneously inside the escape zone before triggering victory.
* **[MODIFY] [hud_overlay.gd](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.gd)**:
  * Renders dynamic safe-zone status indicators (e.g. `SAFE: 1/3` survivors) in the bottom panel.

---

## 2. Test Verification Results

### Automated Unit Tests
A new test suite **[test_phase_6_5.gd](file:///d:/GameDev/hideandseek/tests/test_phase_6_5.gd)** was created. All **30 tests** compiled and passed successfully:

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

Running suite: test_phase_6_5.gd
  [PASS] test_targeting_controls_by_index
  [PASS] test_sound_propagation_scaling
  [PASS] test_seeker_role_initialization
  [PASS] test_escape_zone_multi_member_victory

Running suite: test_player.gd
  [PASS] test_player_scene_loads
  [PASS] test_player_instantiation_and_properties
  [PASS] test_player_z_axis_lock

Running suite: test_seeker.gd
  [PASS] test_seeker_wander_flow
  [PASS] test_seeker_hears_heard_sound
  [PASS] test_seeker_spots_player
  [PASS] test_seeker_ignores_hidden_actor

Running suite: test_ui_audio.gd
  [PASS] test_sound_manager_methods
  [PASS] test_hud_overlay_updates
  [PASS] test_game_state_menu_behavior
  [PASS] test_escape_zone_victory_trigger

=========================================
Test Summary:
Passed: 30
Failed: 0
=========================================
All tests completed successfully!
```

---

## 3. Manual Verification Steps

1. Launch [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn).
2. Press Key **`1`** (ALL), Key **`2`** (Member 1), Key **`3`** (Member 2), or Key **`4`** (Member 3).
3. Observe that the bottom HUD command panel updates to display `TARGET: MEMBER 1 (TODDLER)`, etc.
4. Command **Follow (`E`)** or **Freeze (`Q`)** and verify that only the targeted member moves.
5. Watch the bottom panel safe tally showing `SAFE: 0/3`.
6. Escort companions to the portal. Have them walk into the **EscapeZone** and note the counter updates to `SAFE: 1/3`, `SAFE: 2/3`.
7. Walk into the portal as the player, and verify that the victory screen **only** displays when everyone is inside.
