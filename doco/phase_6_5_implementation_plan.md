# Phase 6.5 Implementation Plan - Command Targeting, Sound Adjustments, Seeker Archetypes & Group Escape

This plan outlines the design and implementation for the Phase 6.5 gameplay improvements sweep.

## Goal Description
Enhance strategic gameplay by introducing dynamic companion command targeting (Key 1 for ALL, Keys 2-4 for Member index 1-3 present in the level), sound circles scaled by distance to the targeted companion, distinct Seeker AI personality archetypes (Lazy, Normal, Aggressive), and a group escape completion loop where all active family members present in the level must reach the escape zone before winning.

---

## User Review Required

### Input Configuration
We will add new action mappings in `project.godot`:
* `target_all` -> Key 1
* `target_member_1` -> Key 2
* `target_member_2` -> Key 3
* `target_member_3` -> Key 4

### Dynamic Index Targeting
Companions will be selected based on their registration order in the level rather than hardcoded classes. If the level has two toddlers and one elder, Key 2 selects Toddler 1, Key 3 selects Toddler 2, and Key 4 selects the Elder.

---

## Proposed Changes

### 1. Dynamic Command Targeting (Keys 1-4)
#### [MODIFY] [project.godot](file:///d:/GameDev/hideandseek/project.godot)
* Add input actions `target_all`, `target_member_1`, `target_member_2`, and `target_member_3` mapped to keys `1`, `2`, `3`, and `4`.

#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* Add a `current_target_member: FamilyMember = null` property (where `null` represents "ALL").
* Update `broadcast_follow()` and `broadcast_freeze()`:
  * If `current_target_member == null`: Command **all** active family members.
  * If `current_target_member` is valid: Command **only** that specific companion.
* Expose a `select_target_by_index(idx: int)` method:
  * Index `-1` sets `current_target_member = null` (ALL).
  * Index `0` to `2` sets `current_target_member = active_members[idx]` (if bounds check succeeds).
* Update `_calculate_sound_propagation()` :
  * If `current_target_member` is selected: Base the whisper/shout check distance **only** on the distance to that specific targeted companion.
  * If `current_target_member == null`: Base it on the maximum distance of all active members.
  * If the check distance is small (<= 6.0m), the sound radius is small (2.0m). If the distance is large (> 6.0m), the sound radius is large (15.0m).

#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* In `_unhandled_input()`, check for keys `1`-`4` to call `FamilyManager.select_target_by_index()` (Key 1 -> -1, Key 2 -> 0, Key 3 -> 1, Key 4 -> 2).

#### [MODIFY] [hud_overlay.gd](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.gd) & [hud_overlay.tscn](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.tscn)
* Add a **Target Indicator Label** (e.g. `TARGET: ALL` or `TARGET: MEMBER 1 (TODDLER)`) to the bottom panel to give immediate visual feedback of the active command target.

---

### 2. Seeker Archetypes (Lazy, Normal, Aggressive)
#### [MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)
* Expose a `@export var seeker_type: String = "NORMAL"` (or enum).
* Configure variables in `_ready()` based on the selected archetype:
  * **LAZY**: 
    * Speed: `1.2` (Patrol), `2.0` (Chase)
    * Alert decay rate: `0.15` per second (forgets quickly)
    * Search wait time: `1.0` second before giving up
    * Alert level multiplier: `0.5`
  * **NORMAL**:
    * Speed: `2.0` (Patrol), `3.0` (Chase)
    * Alert decay rate: `0.06` per second
    * Search wait time: `1.8` seconds
    * Alert level multiplier: `1.0`
  * **AGGRESSIVE** (Current):
    * Speed: `2.5` (Patrol), `3.8` (Chase)
    * Alert decay rate: `0.03` per second
    * Search wait time: `2.5` seconds
    * Alert level multiplier: `1.5`

---

### 3. Dynamic Group Escape Loop
#### [MODIFY] [escape_zone.gd](file:///d:/GameDev/hideandseek/scenes/objects/escape_zone.gd)
* Maintain an `escaped_members: Array[Node3D] = []` array of companions currently inside the zone.
* Only trigger `show_victory()` when:
  1. The Player body is inside the zone.
  2. All currently alive `FamilyManager.active_members` present in the level are inside the zone.
* Display escape progress feedback (e.g. `Escaped: 1/2`) on the HUD overlay when a member enters the zone.

---

## Verification Plan

### Automated Tests
* Create `tests/test_phase_6_5.gd` verifying:
  * Selecting keys 1-4 updates target index or target node.
  * Command broadcasts only update the targeted index companion.
  * Sound propagation scales appropriately based on player-to-target distance.
  * Lazy vs. Aggressive Seekers have different speeds and decay rates.
  * EscapeZone requires all registered living members to win.

### Manual Verification
1. Run the test level, press `2` and whistle (follow/freeze). Verify only the first registered companion moves.
2. Verify that whistling when the selected companion is close to you generates a very small sound circle.
3. Test that walking to the exit does not trigger victory until all companions are safely inside.
