# Phase 14 Walkthrough: Seeker Window Investigation Rework

This document details the overhaul of the Seeker robot's window/look-spot investigation behavior completed in Phase 14.

## Implementation Details

### 1. Root Cause Fix — Phase 2 Walk Timeout

**Problem**: The old `_state_timer < 5.0` check in `_process_suspicious()` was measured from the moment the Seeker entered `State.SUSPICIOUS`, which includes the 1.2s alert animation. The walk phase only had ~3.8 seconds — not enough time for a distant Seeker to reach the look spot.

**Fix**: Introduced a separate `_phase_timer` that resets to `0.0` on every sub-phase transition. Phase 1 (walk) now has its own independent timeout of `search_wait_time * 3.0` seconds (e.g., 13.5s for NORMAL), and arrival uses a combined XZ distance check (`< 0.6m`) instead of X-only.

---

### 2. New 3-Phase SUSPICIOUS Sub-State Machine

Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):

**Phase 0 — ALERT** (`_suspicious_phase = 0`):
- Seeker freezes in place and plays the alert animation
- Faces the sound/sight source
- Duration matches actual animation length (queried from AnimationPlayer)
- Advances to Phase 1 when complete

**Phase 1 — WALK_TO_SPOT** (`_suspicious_phase = 1`):
- Seeker walks toward `_assigned_look_spot.global_position` (or sound origin if no spot)
- Uses `clamp(x_dist * 4.0, -move_speed, move_speed)` for natural X deceleration near the target
- Z movement handled by the global position mover (no double-movement bug)
- Transitions to Phase 2 when within `0.6m` XZ, or after `search_wait_time * 3.0s` timeout

**Phase 2 — LOOKING** (`_suspicious_phase = 2`):
- Seeker aligns rotation to the look spot's Y rotation (peers through the exact window opening)
- Sweeps spotlight through the opening
- Cycles look animations — each plays to full completion before the next starts
- Stays for a randomised `_look_spot_dwell_time = search_wait_time * rand(1.0, 1.8)` seconds
- On expiry: rolls dice (`_switch_spot_chance`) to either visit another spot or return to wander

**Hard cap**: `_total_investigate_timer > search_wait_time * 5.0` forces return to wander if investigation drags on across multiple spot visits.

---

### 3. Multi-Spot Investigation

Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):

When Phase 2 dwell time expires, the Seeker may walk to a second spot:
- Rolls `randf() < _switch_spot_chance` AND requires `_spots_visited_count < 2`
- Calls `_find_closest_unoccupied_spot(_target_pos, prev_spot)` to find an unoccupied spot excluding the current one
- If found: transitions back to Phase 1 with the new target, increments `_spots_visited_count`
- Up to **2 additional spot visits** per investigation session

| Archetype | `_switch_spot_chance` | Behavior |
|-----------|----------------------|----------|
| LAZY      | 15%                  | Usually goes straight back to work |
| NORMAL    | 35%                  | Occasionally checks a second window |
| AGGRESSIVE| 60%                  | Usually checks multiple windows |
| LAME      | 0%                   | Never investigates |

---

### 4. Random Curiosity Wall Checks

Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):

During normal `State.WANDER`, a countdown timer fires every `_random_wall_check_interval` seconds (±5s jitter):
- LAZY: every ~50s
- NORMAL: every ~30s  
- AGGRESSIVE: every ~18s
- LAME: disabled

When it fires, the Seeker finds the nearest unoccupied look spot and walks to it directly (enters Phase 1, skipping the alert anim — this is a casual check, not an alarmed response). After looking through the window, it returns to normal patrol.

---

### 5. Consolidated `_find_closest_unoccupied_spot()` Helper

Modified [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd):

Replaced the 20-line inline spot-search in `_on_sound_heard()` with a reusable helper:
```gdscript
func _find_closest_unoccupied_spot(near: Vector3, exclude: Node3D = null) -> Node3D
```
- Collects spots held by all other active Seekers (via `"seeker"` group)
- Optionally excludes an additional spot (the current spot when switching)
- Returns nearest unoccupied spot to `near`, or `null` if none available

---

### 6. Animation Updates

Updated `_process_animations()` SUSPICIOUS branch to use `_suspicious_phase` instead of `_state_timer`:
- `_suspicious_phase == 0` → `anim_alert`
- `_suspicious_phase == 1` + moving → `anim_walk`; stationary → `anim_idle`
- `_suspicious_phase == 2` → current look animation (or `anim_idle` if none selected yet)

---

## Verification Results

### Automated Tests
All tests passed:
```
=========================================
[SUCCESS] All tests and validations passed!
=========================================
```
(Stderr warnings are pre-existing headless test harness issues unrelated to this change.)

### Manual Testing Checklist
Open **Level 1 (Tutorial)** and verify:

- [ ] **Pebble near window**: Seeker stops → plays alert anim → walks to nearest look spot → peers through window with look animations → returns to work
- [ ] **Correct Z depth**: Seeker arrives at the look spot's Z (e.g., Z=-9), not at Z=0 or Z=-6
- [ ] **Multi-spot (AGGRESSIVE)**: After looking at one window, Seeker walks to a different window and looks there too
- [ ] **Random wall check**: Without any pebble or sound, NORMAL/AGGRESSIVE Seekers periodically walk to a window and look (~30/18s)
- [ ] **Multi-Seeker coordination**: Two Seekers hearing the same sound go to *different* look spots
- [ ] **Return to work**: After investigation completes, Seeker resumes wander/work normally
- [ ] **Spotlight godbeams**: Still visible through window openings (Phase 13 behavior preserved)
