# Level 2 Vent Exit Paths & Ledge Launcher Fix

Correct the incorrect `connected_exit_path` assignments for the vents on Level 2 (`level_2_cargo_hold.tscn`), hide the Toddler visually when they are crawling in a vent, and support targeted trajectory throws for the Ledge Launcher.

## Proposed Changes

### Level 2 Cargo Hold Scene

#### [MODIFY] [level_2_cargo_hold.tscn](file:///d:/GameDev/hideandseek/scenes/levels/level_2_cargo_hold.tscn)
- Set `connected_exit_path = NodePath("../TestVentExit")` for `TestVentEntrance` (the ground floor vent entrance).
- Set `connected_exit_path = NodePath("../TestVentExitBottom")` for `TestVentEntranceTop` (the upper level vent entrance).
- Added a `LandingTarget` (Node3D marker) child to `TestLedgeLauncher` and mapped it to the new `landing_target` property.

### Ledge Launcher

#### [MODIFY] [ledge_launcher.gd](file:///d:/GameDev/hideandseek/scenes/objects/ledge_launcher.gd)
- Added an exported `@export var landing_target: Node3D` property.

### Adult Class

#### [MODIFY] [adult.gd](file:///d:/GameDev/hideandseek/scenes/family/adult.gd)
- In `try_launch_toddler()`, detect the `landing_target` property on the launcher. If present, compute the exact horizontal and vertical initial velocity required to arc and land the Toddler directly on the target coordinates. Falls back to default vertical toss if no target is specified.

### Toddler Class

#### [MODIFY] [toddler.gd](file:///d:/GameDev/hideandseek/scenes/family/toddler.gd)
- In `crawl_through_vent()`, set `visible = false` so the Toddler disappears while inside the vent.
- In `_physics_process()`, set `visible = true` once crawling finishes or aborts.

### Family Member Base Class

#### [MODIFY] [family_member.gd](file:///d:/GameDev/hideandseek/scenes/family/family_member.gd)
- In `_physics_process()`, changed the `State.LAUNCHED` physics flow to apply gravity and `move_and_slide()` *before* checking `is_on_floor()`. This avoids stale collision state from the previous frame incorrectly aborting the launch on the first frame.
- Added a check to prevent landing unless the Y-velocity is downward or stationary (`velocity.y <= 0.0`).

## Verification Plan

### Automated Tests
- Run `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` to ensure all existing test suites pass.

### Manual Verification
- Launch the game, play Level 2, call the Toddler to follow you up to the top level, and verify the Toddler uses the vent to reach the top level successfully without getting stuck.
- Verify the Toddler model and floating label completely disappear from the scene when they enter the vent and reappear immediately at the destination vent exit mouth.
- Trigger the toddler launch at `TestLedgeLauncher` and verify the Toddler is thrown across the gap and lands exactly at the `LandingTarget` marker.
