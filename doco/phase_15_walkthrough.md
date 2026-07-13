# Phase 15 Walkthrough: Stop Command + Level Detection

This walkthrough outlines the implementation of the Stop command and Level Detection features for escort controls.

## Changes Implemented

### 1. Stop Command (`State.STOP`)
- Added `STOP` as state `7` inside `FamilyMember.State`.
- Implemented `FamilyManager.broadcast_stop()` which broadcasts state 7 to the family, releasing any active cover zones they have.
- Modified player input handling in `player.gd` for `command_freeze` (default key `Q`):
  - **Single Q press**: Calls `FamilyManager.broadcast_stop()`. Family members stop moving instantly and play the `idle` animation. They do not look for cover.
  - **Double Q tap** (within 0.35s window): Calls `FamilyManager.broadcast_freeze()`. Family members run to the closest cover zones and hide.
- Updated `_process_animations()` in `family_member.gd` so members in the `STOP` state play their idle animations rather than their crouched/hiding animations.

### 2. Level Detection & Auto-Hiding
- Defined `LEVEL_Y_THRESHOLD = 2.5` inside `family_member.gd`.
- At the top of the `State.FOLLOW` physics block, we check if the player's Y position is significantly higher than the member's Y position (`y_diff > 2.5`).
- If this threshold is crossed, the family member executes `_auto_hide_on_level_change()`.
  - The member releases any current cover.
  - The member searches for the nearest unoccupied cover zone on their current level.
  - If a zone is available, they route to it and enter `State.HIDING`.
  - If no zone is found, they stop in place (`State.STOP`) to avoid jumping uselessly at ladders or ledges.

## Verification & Testing

### Automated Tests
Ran the full test suite via `run_tests.ps1`:
```
=========================================
[SUCCESS] All tests and validations passed!
=========================================
```

### Manual Testing Instructions
1. **Stop Command**: Escort family members. Press Q once. Verify they stand still exactly where they are and play their idle animation.
2. **Hide Command**: Escort family members. Double-tap Q quickly. Verify they run to cover zones and hide (crouching animation).
3. **Follow Override**: Press E. Verify that both stopped and hiding members resume following.
4. **Level Auto-Hide**: Stand near a ladder with the family following. Climb the ladder to the upper floor. Verify that as you go up, the family members automatically split off to hide in the nearest cover zones (or stand still if none exist) rather than constantly jumping at the ladder.
