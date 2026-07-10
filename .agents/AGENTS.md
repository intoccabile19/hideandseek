# Workspace Rules

This file contains project-scoped rules and style guidelines that Antigravity will automatically discover and follow for all tasks in this workspace.

## Godot 4.6.3 Coding Standards
- Use GDScript best practices for Godot 4.x.
- Always use static typing in GDScript where possible (e.g., `var velocity: Vector3 = Vector3.ZERO`, `func _physics_process(delta: float) -> void:`).
- Group variables in inspector categories using `@export_group` and `@export_subgroup`.
- Follow the official Godot style guide: standard naming conventions (PascalCase for classes, snake_case for variables/functions/files, CONSTANT_CASE for constants).
- Keep node access clean: use `@onready var` with `$` or `get_node()` and specify types.

## General Project Rules
- Document public APIs and complex algorithms with clear comments.
- Keep components focused and modular.
- Always output an implementation plan for the current phase with clear instructions on what you are planning into the `doco\` folder.
- Always output a walkthrough/output document that clearly outlines what we have just implemented and how to test/verify it in the `doco\` folder, in the same folder as the implementation plan, with the same name.
- Always run tests after the implementation but before finalising the walkthrough document by executing `powershell -ExecutionPolicy Bypass -File .\run_tests.ps1` in the project root. Ensure all tests pass.
- Keep the project modular. When implementing new  functionality ensure that there isn't 1 big script that does everything, but rather break it down into smaller, more manageable scripts with comments. Break logical functions into different methods/functions within the script and add comments to explain what each method/function does. Avoid using helper scripts that do not follow the same rules as the main project scripts.

## Seeker Vision Cone Rules
- **NEVER** modify or resize the `VisionCone` (under `SpotLight3D` in `scenes/seeker/seeker.tscn`) node's transform or mesh size. The user has manually aligned it. Its exact transform `Transform3D(10, 0, 0, 0, -4.371139e-07, -10, 0, 10, -4.371139e-07, 0, -0.984766, -5.7029305)` and dimensions must be preserved.
