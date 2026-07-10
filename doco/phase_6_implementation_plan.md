# Phase 6 Implementation Plan - UI, Audio & Polish

This plan outlines the design and implementation for the UI, Audio, and general game polish sweep in Phase 6.

## Goal Description
Elevate the tension, readability, and overall game feel of Micro-Migration. We will establish clear visual/audio feedback for stealth state alerts, toddler tension status, command modes, and general game loop states (menus, victory, and game over screens).

---

## User Review Required

> [!IMPORTANT]
> **Audio Resources**: Since this is a programmatic environment, we will generate synthetic placeholders (using standard Godot `AudioStreamGenerator` or standard beep oscillators) to ensure the audio code executes cleanly without requiring external binary asset downloads.
> Let us know if you prefer to drop in specific `.wav`/`.ogg` audio files during this phase.

---

## Open Questions
* Do you want the retro CRT shader effect on the UI, or would you prefer a clean, modern glassmorphism design?
* For the Toddler tension meter: should it be a circular gauge above the Toddler's head, or a floating warning bar? We propose a clean floating warning bar that changes color from green to pulsing orange/red.

---

## Proposed Changes

### 1. UI Control Screens & HUD
#### [NEW] [hud_overlay.tscn](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.tscn)
#### [NEW] [hud_overlay.gd](file:///d:/GameDev/hideandseek/scenes/ui/hud_overlay.gd)
* A overlay canvas displaying:
  * **Command Indicator**: Shows whether family is ordered to `Follow` or `Freeze` (using retro stencil text & color indicators).
  * **Detection Warning Eye**: Centered at the top, reflecting the Seeker's alert state (unaware, suspicious `?`, chasing `!`, flashing warnings).
  * **CRT Post-Process Overlay**: A viewport shader simulating retro terminal CRT screens.

#### [NEW] [game_state_menu.tscn](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.tscn)
#### [NEW] [game_state_menu.gd](file:///d:/GameDev/hideandseek/scenes/ui/game_state_menu.gd)
* Standardized retro screen layouts for:
  * **Main Menu**: Options to start, configure keys, and quit.
  * **Game Over / Captured Screen**: Blinking red warning texts and retry option.
  * **Victory Screen**: Number of family members saved and jam scoreboard.

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
* Instantiates a floating 3D `ProgressBar3D` or `Label3D` above the Toddler's head to reflect their curiosity/panic meter visually in real-time.

---

### 2. Audio Systems
#### [NEW] [sound_manager.gd](file:///d:/GameDev/hideandseek/scenes/audio/sound_manager.gd)
* An autoload sound controller that dynamically generates and triggers synthetic audio cues:
  * **Whistle/Chirp Beeps**: Frequency modulated beep sounds for player whistles and toddler chirps.
  * **Seeker Footsteps**: Low-pitched pitch-modulated noise bursts that increase in volume as the Seeker moves closer to the window.
  * **Ambient Heartbeat**: An oscillating bass tone that increases in tempo and volume based on the Seeker's current alert state or distance to the player.

#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* Trigger whistle audio beeps on `command_follow` or `command_freeze` key actions.

---

## Verification Plan

### Automated Tests
* Create `tests/test_ui_audio.gd` to verify:
  * HUD overlays update successfully in response to Seeker state changes.
  * Sound manager correctly spawns audio cues on sound circle events.

### Manual Verification
1. Run the test level, check the CRT overlay and the HUD elements.
2. Make noise (whistle/chirp) and verify the Seeker detection eye HUD starts filling up and flashing.
3. Observe the Toddler's floating warning bar fill up before they wander off and chirp.
