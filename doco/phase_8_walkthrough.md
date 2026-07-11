# Phase 8 Walkthrough: Coordinated Stealth Puzzles

This document outlines the cooperative platforming mechanics, player focus inputs, projectile throwing, hider specialized behaviors, elevator system, and pressure plate integrations added for Phase 8.

## Implementation Details

### 1. The Player (Verticality, Projectiles, & Focus)
* **[MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)**:
  * **Automatic Ladder Translation**: Implemented a fixed translation system. When standing near the ladder and pressing W (move_up), the player aligns X/Z to the ladder, disables Layer 1 collisions, and climbs automatically to the top before snapping onto the upper platform (Y = 5.05). When standing at the top and pressing S (move_down), they automatically climb down to Floor 1, snapping safely to the ground. This prevents any accidental vertical clipping or falling through the world.
  * Added `_throw_pebble()` instantiating a [pebble.gd](file:///d:/GameDev/hideandseek/scenes/objects/pebble.gd) distraction projectile, launched in the horizontal direction the player faces.
  * Added Command Focus: holding shift/trigger slows down time via `Engine.time_scale = 0.25` for issuing rapid hider orders.
  * Intercepted player F/Interact inputs during Elder hacking to prevent accidental double-activations (e.g. interacting with other objects near the hack console).
* **[NEW] [pebble.gd](file:///d:/GameDev/hideandseek/scenes/objects/pebble.gd)**:
  * Emits a `sound_emitted` wave event upon ground impact.

### 2. The Adult (Gate Bracing & Launches)
* **[MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)**:
  * Implemented `try_launch_toddler(launcher)` which tosses the Toddler vertically onto high platforms or vents.
  * Added `brace_gate(gate)` which halts Adult movement while holding a gate open.
  * **Exiting Walk-through**: When commanded to follow/unbrace, the Adult automatically moves under/through the gate's X coordinate to the other side (target offset of 1.5m) before dropping the wall closed, ensuring they are never stranded on the wrong side.
* **[NEW] [ledge_launcher.gd](file:///d:/GameDev/hideandseek/scenes/objects/ledge_launcher.gd)**:
  * Interactable component targeting Adult to throw the Toddler.
* **[NEW] [brace_gate.gd](file:///d:/GameDev/hideandseek/scenes/objects/brace_gate.gd)**:
  * Interactable gate/shutter component controlling physical vertical movement and collision states of linked walls.

### 3. The Elder (Sweet-Spot Hacking & Seeker Sleep)
* **[MODIFY] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)**:
  * Implemented interactive terminal hacking sweet-spot minigame UI and logic.
  * **Easier Hacking**: Widented the green sweet-spot from 20% to 30% width and decreased the cursor sweep speed to 1.3 for smooth, fair inputs.
  * **Hacking Pause**: Initiating the minigame pauses the entire game tree (`get_tree().paused = true`), freezing all Seekers, hiders, and physics in the background. The Elder hider script and hacking UI are set to `PROCESS_MODE_ALWAYS` so they run smoothly in real-time. Unpausing is handled upon closing.
  * **Hacking Failure Alert**: If the cursor is stopped outside of the green zone, the minigame terminates immediately, plays a warning beep, and projects a sound circle of radius `12.0` to attract nearby Seekers to the Elder's location.
  * Links successful console overloads to Seeker sleeping.
* **[NEW] [hack_console.gd](file:///d:/GameDev/hideandseek/scenes/objects/hack_console.gd)**:
  * Hacking console target that stuns all active Seekers.
* **[MODIFY] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)**:
  * Added `State.SLEEP` stun state. During sleep, the robot freezes horizontally and its spotlight and vision cone tilt **straight down** (at `-90.0` degrees) as visual confirmation that it has been disabled. The robot restores its default angles, colors, and vision cone albedo upon waking.
  * Added Seeker to the `"seekers"` node group on startup, allowing the console stun to function on all archetypes (including LAME Seekers).

### 4. The Toddler (Vents & Weightlessness)
* **[MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)**:
  * Implemented `crawl_through_vent()` crawlspace traversal logic.
  * **Vent Exit Hiding**: Exiting a vent automatically freezes the Toddler in a hidden state (`is_hidden = true`, `State.FREEZE`) at the vent mouth until ordered otherwise.
  * **Auto-Vent Routing**: If commanded to follow or interact on a different vertical floor (Y difference > 2m), the Toddler automatically seeks the nearest local vent entrance on their level to crawl back down to the player's level, rather than trying to walk directly off the ledge. Resumes any saved interaction target upon exiting.
* **[NEW] [vent_entrance.gd](file:///d:/GameDev/hideandseek/scenes/objects/vent_entrance.gd)**:
  * Interactable vent entrance, registered in the `"vents"` node group.

### 5. Vertical Puzzle Mechanics (Elevators & Flat Pressure Plates)
* **[NEW] [elevator.gd](file:///d:/GameDev/hideandseek/scenes/objects/elevator.gd)**:
  * Translates a physical platform between configurable vertical heights.
* **[NEW] [elevator_button.gd](file:///d:/GameDev/hideandseek/scenes/objects/elevator_button.gd)**:
  * Accessible interactable to trigger elevator movement.
* **[NEW] [pressure_plate.gd](file:///d:/GameDev/hideandseek/scenes/objects/pressure_plate.gd)**:
  * Flat ground plate that supports weight-sensitive triggers (ignores Toddlers, detects Adult/Player) and support `invert_trigger` behavior (stepping on the plate lowers gates/closes doors).

---

## Sandbox Test Level Configuration

The `level_test.tscn` scene has been structured into a vertical puzzle level. Here is how you can test each mechanic:
1. **LAME Seeker**: The Seeker is set to archetype 3 (LAME) to wander peacefully and avoid interfering. When hacked, its spotlight tilts straight down and its movement freezes.
2. **Ladder & Upper Platform**: Press W to step back into the ladder and climb automatically to Floor 2. Press S to climb back down to Floor 1. Floor collision is temporarily bypassed during transition.
3. **Elevator**: Press the Elevator button on the upper floor to bring the elevator up and transport the Adult/Elder.
4. **Vents**: Target the Toddler and interact with the vent. The Toddler crawls to the upper exit and remains hidden. Whistle follow, and they automatically crawl back down.
5. **Flat Inverted Pressure Plate**: Stepping on the flat plate (at X = 2, lowered flat on the ground) as Player/Adult triggers a normally-open door gate (at X = 5) to drop down and block the walkway. Toddler can run across the plate without triggering it, allowing them to traverse and interact on the other side.
6. **Brace Gate**: Command the Adult to brace the gate. The gate wall raises. Order them to rejoin follow, and watch them walk under the gate before dropping it closed.
7. **Hacking Console**: Interact with the terminal as the Elder. Press F inside the widened green bar area to successfully put the Seeker to sleep. No double-activation occurs, and the game pauses completely during the hack.
8. **Label3D Guides**: Clean 3D text labels float above every interactable element in the level to explain exactly what to test.

---

## Verification Results

### Automated Tests
* **[test_phase_8.gd](file:///d:/GameDev/hideandseek/tests/test_phase_8.gd)**:
  * Verifies slow-mo time dilation.
  * Verifies directional Pebble Throw.
  * Verifies ladder climbing toggles.
  * Verifies Adult launcher velocities.
  * Verifies Elder terminal hacking UI and Seeker stuns.
  * Verifies Toddler weightless pressure plate bypasses.

All 41 tests in the suite compile and pass successfully.
