# Phase 8: Coordinated Stealth Puzzles

To elevate the puzzle and platforming elements, we will transition the gameplay from passive waiting to active coordination. This design is fully playable on a controller, using character facing directions, standard trigger/face buttons, and specialized mechanics.

## Finalized Mechanics (2+ Functions per Character)

### 1. The Player (Agility, Ranged Distraction, & Command Focus)
* **Function 1: Ladder & Rope Climbing**:
  * *Description*: The Player can climb vertical ladders and ropes to navigate platforms.
* **Function 2: Pebble Throw (Directional Distraction)**:
  * *Description*: The player throws a small pebble directly forward in their facing direction. The pebble flies a fixed distance and creates a sound circle upon hitting the ground, attracting the Seeker.
* **Function 3: Command Focus (Slow-Mo)**:
  * *Description*: Holding a trigger button slows down time (e.g., `Engine.time_scale = 0.25`), allowing the player to easily issue multiple commands to different family members during chaotic situations.

### 2. The Adult (Heavy Objects & Verticality)
* **Function 1: Heavy Gate Bracing**:
  * *Description*: Pushes boxes and holds open heavy metal shutters or stands on heavy pressure plates to keep gates open.
* **Function 2: Toddler Launcher (Ledge Launch)**:
  * *Description*: Picks up the Toddler when standing next to them and tosses them vertically onto high platforms or into overhead air vents.

### 3. The Elder (Terminal Sweet-Spots & Robot Sleep Overload)
* **Function 1: Terminal Hack (Sweet-Spot Minigame)**:
  * *Description*: Displays an oscillating cursor bar. The player must press the action button when the bar aligns with a green "sweet spot" zone to complete the hack.
* **Function 2: Robot Sleep Overload**:
  * *Description*: From specific security console terminals, the Elder can overload the local giant robot (Seeker), putting it to sleep/stunning it for a short duration (e.g., 8-10 seconds) to create a safe path.

### 4. The Toddler (Crawlspaces & Weightless Infiltration)
* **Function 1: Vent Crawling**:
  * *Description*: Squeezes through narrow pipes and vents to bypass locked doors.
* **Function 2: Weightless Infiltrator**:
  * *Description*: The Toddler is too light to trigger heavy pressure plates, fragile/collapsible platforms (which would break under anyone else), or heavy-sensitivity laser tripwires.

---

## Proposed Changes File List

### Player
#### [MODIFY] [player.gd](file:///d:/GameDev/hideandseek/scenes/player/player.gd)
* Implement ladder/rope detection and climbing physics.
* Implement Pebble Throw instancing.
* Implement Focus time-dilation controls.

### Family Members
#### [MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
* Add Toddler launch mechanics.

#### [MODIFY] [elder.gd](file:///d:/GameDev/hideandseek/scenes/family/elder.gd)
* Add interactive hacking sweet-spot UI minigame.
* Add robot sleep signal emission upon console completion.

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
* Add Vent pathing.
* Configure weight/pressure bypass properties.

---

## Verification Plan

### Automated Tests
- `test_player_ladder_climbing.gd`
- `test_pebble_throw_directional.gd`
- `test_focus_slows_time.gd`
- `test_adult_toddler_launch.gd`
- `test_elder_hacking_sleep_overload.gd`
- `test_toddler_weightless_infiltrator.gd`
