# Phase 14 Implementation Plan: Seeker Window Investigation Rework

This plan details the overhaul of the Seeker robot's window/look-spot investigation system to make robots reliably walk to wall windows, cycle through look animations there, optionally visit a second window, and perform random curiosity checks during normal patrol.

## Root Cause

The old `_process_suspicious()` used a single `_state_timer < 5.0` hard-coded gate for the walk phase, measured from the start of the entire SUSPICIOUS state — including the alert animation (~1.2s). This left only ~3.8 seconds for the Seeker to walk to a spot. If the Seeker was far away, it timed out and fell to Phase 3 at the *wrong position*. There was also no per-phase timer, so phases could not be tracked independently.

## Proposed Changes

### [Seeker Component]

#### [MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)

**New variables:**
- `_suspicious_phase: int` — sub-phase: `0=ALERT`, `1=WALK_TO_SPOT`, `2=LOOKING`
- `_phase_timer: float` — resets on each sub-phase transition (independent of `_state_timer`)
- `_look_spot_dwell_time: float` — randomised time to spend looking at each window
- `_total_investigate_timer: float` — wall-clock time across all spot visits (hard cap)
- `_spots_visited_count: int` — limits multi-spot hopping to max 2 additional spots
- `_switch_spot_chance: float` — per-type probability to visit a second window
- `_random_wall_check_timer: float` / `_random_wall_check_interval: float` — periodic curiosity checks during wander

**Archetype wall-check and switch-chance settings:**
| Archetype | `_random_wall_check_interval` | `_switch_spot_chance` |
|-----------|------------------------------|----------------------|
| LAZY      | 50 s                         | 0.15                 |
| NORMAL    | 30 s                         | 0.35                 |
| AGGRESSIVE| 18 s                         | 0.60                 |
| LAME      | disabled                     | 0.0                  |

**`_process_wander()` random curiosity check:**
- Countdown timer fires every `_random_wall_check_interval` seconds (±5s jitter)
- Picks nearest unoccupied look spot, walks there (Phase 1 directly — no alert anim)

**`_process_suspicious()` — new 3-phase sub-state machine:**
- **Phase 0 ALERT**: Freeze, play alert anim, face threat. Advances after `_alert_duration`.
- **Phase 1 WALK_TO_SPOT**: Walk toward `_target_pos` using combined XZ distance check (`< 0.6m`). Timeout after `search_wait_time * 3.0` seconds. Natural X deceleration via `clamp(x_dist * 4, -speed, speed)`. Z movement handled by global position mover.
- **Phase 2 LOOKING**: Align to look spot rotation, cycle look animations to completion, sweep spotlight. After `_look_spot_dwell_time`: roll dice to switch to another spot (max 2 visits) or return to wander.

**`_find_closest_unoccupied_spot(near, exclude)` new helper:**
- Consolidated spot-finding used by both `_on_sound_heard` and multi-spot switching
- Filters spots occupied by other Seekers and optionally the current spot (for switching)

**`_choose_next_wander()` additions:**
- Resets `_suspicious_phase`, `_phase_timer`, `_total_investigate_timer`, `_spots_visited_count`

**`_on_sound_heard()` simplification:**
- Replaced 20-line inline spot search with `_find_closest_unoccupied_spot(origin)`
- Resets all phase tracking vars when entering SUSPICIOUS

**`_process_animations()` update:**
- SUSPICIOUS animation now driven by `_suspicious_phase` (0→alert, 1→walk/idle, 2→look anim)

---

## Verification Plan

### Automated Tests
```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```

### Manual Verification
1. Throw pebble near window → Seeker stops, alert anim, walks to spot, looks through window
2. Seeker arrives at correct Z depth (not stuck at Z=0 or Z=-6)
3. NORMAL/AGGRESSIVE Seekers randomly walk to windows during patrol without any sound
4. AGGRESSIVE Seeker occasionally moves to a second window after the first
5. Two Seekers alerted simultaneously target different spots
6. After investigation, Seeker returns to work/wander normally
