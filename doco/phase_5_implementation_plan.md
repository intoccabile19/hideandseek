# Phase 5: Seeker Patrol & AI - Implementation Plan

Implement the background-patrolling Seeker AI, background debris lifting/searching mechanics, forward-scanning sweeps, sound detection, and chase/capture sequences.

## User Review Required

> [!IMPORTANT]
> The Seeker operates primarily in the **background layer ($Z = -1.5$)**, wandering and interacting with background objects.
> Periodically, or upon hearing a noise, they stop, face the foreground walkway ($Z = 0.0$), and sweep their spotlight cone.
> If a player or companion is spotted on the walkway, the Seeker **steps forward to $Z = 0.0$** and chases them down, triggering capture. Hiding in cover zones masks companions from detection.

## Proposed Changes

### Centralized Systems
#### [MODIFY] [family_manager.gd](file:///d:/GameDev/hideandseek/scenes/family/family_manager.gd)
* Add a global signal `game_over` to notify other systems (e.g., UI or levels) when the player or family members are captured.

---

### Seeker Components
#### [NEW] [seeker.gd](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.gd)
* Extends `CharacterBody3D`.
* Properties:
  * `@export var wander_range_x: Vector2 = Vector2(-15.0, 15.0)`
  * `@export var background_z: float = -1.5`
  * `@export var search_objects_group: String = "searchable_objects"`
  * `@export var vision_range: float = 10.0`
  * `@export var vision_angle: float = 40.0`
* States:
  * `State.WANDER`: Chooses a random X coordinate or searchable background object in the background layer ($Z = -1.5$) and walks to it.
  * `State.SEARCHING`: Arrives at a searchable object, lifts its mesh vertically (using a simple scale/translation lerp), shines spotlight underneath it, lowers it, and returns to wandering.
  * `State.SCANNING`: Stops, faces the foreground walkway (Z-axis rotation facing $Z = 0.0$), and sweeps its spotlight angle left and right.
  * `State.SUSPICIOUS`: Hears a sound. Faces the sound source, walks to its X coordinate in the background layer, and performs an intensive spotlight scan.
  * `State.CHASE`: Spots an un-hidden player/companion, steps forward to the foreground walkway ($Z = 0.0$), and runs after the target.
* Methods:
  * `_physics_process(delta)`: State machine processing and movement.
  * `_check_vision()`: Scans the player and active companions on the walkway. Checks if the target is within the spotlight cone and range, and casts a raycast to ensure line of sight is not blocked by static walls (Layer 1).
  * `_on_sound_heard(origin: Vector3, radius: float, is_shout: bool)`: Subscribes to `sound_emitted` and `toddler_chirped`. Intercepts sounds and transitions to `State.SUSPICIOUS` if within radius.

#### [NEW] [searchable_object.gd](file:///d:/GameDev/hideandseek/scenes/objects/searchable_object.gd)
* Extends `Node3D` and registers in `"searchable_objects"`.
* Represents background debris, boxes, or grates that the Seeker can lift and search. Contains reference to its mesh node for vertical lifting offsets.

#### [NEW] [seeker.tscn](file:///d:/GameDev/hideandseek/scenes/seeker/seeker.tscn)
* Root: `CharacterBody3D` (Seeker) on Layer 1 (World).
* Children:
  * `CollisionShape3D`: Capsule collision.
  * `MeshInstance3D`: Red mechanical eye/droid mesh.
  * `SpotLight3D`: High-intensity spotlight representing its vision cone.
  * `Area3D` (CaptureZone): Detects overlap with the player or companions during chase.

---

### Level Integration
#### [MODIFY] [level_test.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_test.tscn)
* Instantiate several background **SearchableObjects** (debris panels and grates) at $Z = -1.5$.
* Instantiate a **Seeker** patrolling the background layer.

---

## Verification Plan

### Automated Tests
#### [NEW] [test_seeker.gd](file:///d:/GameDev/hideandseek/tests/test_seeker.gd)
* **`test_seeker_wander_and_search`**: Spawns Seeker and SearchableObjects. Verifies Seeker wanders to objects and initiates lifting search logic.
* **`test_seeker_scanning_sweep`**: Verifies Seeker periodically stops to face forward and sweeps its spotlight direction.
* **`test_seeker_hears_sound`**: Emits a whisper sound and verifies Seeker changes target X to investigate.
* **`test_seeker_chase_and_step_forward`**: Spawns player on walkway inside spotlight cone. Verifies Seeker transitions to `State.CHASE` and steps forward to $Z = 0.0$.
