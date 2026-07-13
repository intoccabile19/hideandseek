# Phase 15 Implementation Plan: Stop Command + Level Detection

## Overview

Two escort control improvements:

1. **Stop command** — a quick "freeze in place" that does NOT seek cover. Needed when operating elevators or other interactables where cover-seeking would scatter the family unhelpfully.
2. **Level detection** — family members in FOLLOW state auto-hide when the player climbs to a significantly higher floor (>2.5 m Y gap), preventing them from jumping endlessly and failing to follow.

---

## Proposed Input Scheme

The current Q key (= `command_freeze`) triggers hide + cover-seeking. The new scheme remaps this:

| Gesture | Action |
|---------|--------|
| **Single Q tap** | Stop in place — new `State.STOP` (no cover) |
| **Double-tap Q** (within 0.35 s) | Seek cover — existing `State.HIDING` behavior |
| **E** | Follow — unchanged |

This makes the lighter "just pause" action easier and the more disruptive "scramble for cover" action deliberate.

---

## Files to Modify

### 1. `scenes/family/family_member.gd`

#### a) New State enum value
Add `STOP = 7` after `LAUNCHED`:
```gdscript
enum State { FOLLOW, FREEZE, HIDING, WANDER, PUSHING, INTERACTING, LAUNCHED, STOP }
```

#### b) New level threshold constant
```gdscript
const LEVEL_Y_THRESHOLD: float = 2.5
```
A normal jump reaches ~2.1 m maximum, so 2.5 m safely identifies a different floor.

#### c) FOLLOW physics — level check at top of FOLLOW block
```gdscript
# Auto-hide if player has climbed to a significantly higher floor
var y_diff: float = FamilyManager.player.global_position.y - global_position.y
if y_diff > LEVEL_Y_THRESHOLD:
    _auto_hide_on_level_change()
    return
```
Direction is **player-above-member only** — if the player drops down, members continue following using existing gap-jump logic.

#### d) New method `_auto_hide_on_level_change()`
- Searches for nearest cover zone (same standalone logic from `_on_command_broadcast`)
- If found: assign cover → `current_state = State.HIDING`
- If not found: `current_state = State.STOP` (stand still in place)
- Prints diagnostic message

#### e) `_on_command_broadcast()` — handle STOP
New `elif current_state == State.STOP:` branch:
- Release any assigned cover
- **No** cover search (this is the key difference from FREEZE)

#### f) `_process_animations()` — STOP plays idle
```gdscript
elif current_state == State.STOP:
    _play_anim(anim_idle)
```
Visually, STOP = standing still (idle pose), not crouching (anim_hide).

---

### 2. `scenes/family/family_manager.gd`

#### New method `broadcast_stop(player_pos: Vector3)`
```gdscript
func broadcast_stop(player_pos: Vector3) -> void:
    update_queue_order()
    var sound_info := _calculate_sound_propagation(player_pos)
    sound_emitted.emit(player_pos, sound_info.radius, sound_info.is_shout)
    spawn_soundwave(player_pos, sound_info.radius)
    command_broadcast.emit(7)  # State.STOP
```
Intentionally does **not** call `assign_hiding_covers()`.

---

### 3. `scenes/player/player.gd`

#### New variables
```gdscript
var _last_freeze_press_time: float = 0.0
const DOUBLE_TAP_WINDOW: float = 0.35
```

#### Modified `command_freeze` handler in `_unhandled_input()`
```gdscript
if event.is_action_pressed("command_freeze"):
    var now: float = Time.get_ticks_msec() / 1000.0
    if now - _last_freeze_press_time < DOUBLE_TAP_WINDOW:
        # Double-tap: seek cover (existing hide behavior)
        FamilyManager.broadcast_freeze(global_position)
        _last_freeze_press_time = 0.0
    else:
        # Single tap: stop in place
        FamilyManager.broadcast_stop(global_position)
        _last_freeze_press_time = now
```

---

## Verification Plan

### Automated Tests
```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```
All existing tests must continue to pass.

### Manual Testing Checklist
Test in `level_1_tutorial.tscn`:

| # | Test | Expected |
|---|------|----------|
| 1 | Single Q press | Family stops in place, plays idle animation, does NOT seek cover |
| 2 | Double-tap Q | Family seeks nearest cover zone (existing hide behavior) |
| 3 | Elevator / hold Q | Family stands still while player operates elevator |
| 4 | Climb ladder to Floor 2 | Members on Floor 1 automatically hide (or stop if no cover) |
| 5 | Return to Floor 1 + press E | Members resume FOLLOW normally |
| 6 | Normal floor-1 jumping | Jumping over small gaps does NOT trigger auto-hide |
| 7 | Press E while stopped | Members resume following (STOP releases cover = none, then FOLLOW) |
